# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
#     "python-dotenv"
# ]
# ///
"""
BC Registry Application Inventory & Tech Stack Scanner

Generates a consolidated table of all applications across managed bcgov repos.
Includes app type detection, Python version from Dockerfile, dependency tracking,
and EOL warnings for both app-level inventory and per-package detail reports.

Usage:
    uv run scan_app_inventory.py
"""

import base64
import csv
import json
import os
import re
import sys
from datetime import datetime

import requests
from dotenv import load_dotenv

load_dotenv()

GITHUB_TOKEN = os.getenv("CODEQL_GITHUB_TOKEN")
if not GITHUB_TOKEN:
    print("Error: CODEQL_GITHUB_TOKEN is not set in .env")
    sys.exit(1)

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
}

TODAY = datetime.now().strftime("%Y-%m-%d")
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── EOL definitions ───────────────────────────────────────────────────────────
# Format: package -> [(max_major, max_minor_or_None, eol_date, note), ...]
EOL_VERSIONS = {
    "flask": [
        (1, None, "2023-08-01", "Flask 1.x — unsupported, upgrade to 3.x"),
        (2, None, "2025-04-01", "Flask 2.x — EOL, upgrade to 3.x"),
    ],
    "django": [
        (3, None, "2024-04-01", "Django 3.x — EOL"),
        (4, 1, "2023-12-01", "Django 4.1 — EOL"),
    ],
    "sqlalchemy": [
        (1, None, "2024-09-05", "SQLAlchemy 1.x — EOL Sep 2024"),
    ],
    "pydantic": [
        (1, None, "2024-07-01", "Pydantic 1.x — superseded by v2"),
    ],
    "celery": [
        (4, None, "2023-07-01", "Celery 4.x — EOL"),
    ],
    "cryptography": [
        (41, None, "2024-01-01", "cryptography <42 — upgrade recommended"),
    ],
    "protobuf": [
        (3, None, "2024-06-01", "protobuf 3.x — EOL, upgrade to 4.x+"),
    ],
    "vue": [
        (2, None, "2023-12-31", "Vue 2.x — EOL Dec 2023"),
    ],
    "nuxt": [
        (2, None, "2024-06-30", "Nuxt 2.x — EOL Jun 2024"),
        (3, None, "2026-07-31", "Nuxt 3.x — EOL Jul 2026, migrate to Nuxt 4"),
    ],
    "vuex": [
        (3, None, "2023-12-31", "Vuex 3.x — tied to Vue 2 (EOL), use Pinia"),
        (4, None, "2024-01-01", "Vuex 4.x — maintenance only, migrate to Pinia"),
    ],
    "webpack": [
        (4, None, "2023-01-01", "webpack 4.x — EOL, upgrade to 5.x+"),
    ],
    "typescript": [
        (3, None, "2023-01-01", "TypeScript 3.x — very outdated"),
        (4, None, "2025-01-01", "TypeScript 4.x — outdated, upgrade to 5.x"),
    ],
    "node": [
        (16, None, "2023-09-11", "Node.js 16 — EOL Sep 2023"),
        (18, None, "2025-04-30", "Node.js 18 — EOL Apr 2025"),
        (20, None, "2026-04-30", "Node.js 20 — EOL Apr 2026"),
    ],
    "jest": [(27, None, "2024-01-01", "Jest 27 — outdated, upgrade to 29+")],
    "axios": [(0, None, "2023-11-01", "axios 0.x — outdated, upgrade to 1.x")],
    "vue-router": [(3, None, "2023-12-31", "vue-router 3.x — tied to Vue 2 (EOL)")],
    "vite": [
        (3, None, "2024-01-01", "Vite 3.x — outdated"),
        (4, None, "2025-06-01", "Vite 4.x — outdated, upgrade to 5+"),
    ],
}

# Python versions EOL as of 2026 (3.9 went EOL Oct 2025)
PYTHON_EOL_MAX = (3, 9)

# Key Python packages to track in the detail report
PYTHON_KEY_DEPS = [
    "flask", "django", "fastapi", "starlette", "uvicorn", "gunicorn",
    "sqlalchemy", "alembic", "celery", "redis", "psycopg2", "psycopg2-binary",
    "pydantic", "marshmallow", "pytest", "requests", "httpx", "aiohttp",
    "sentry-sdk", "google-cloud-storage", "google-cloud-pubsub",
    "google-cloud-secret-manager", "protobuf", "grpcio", "cryptography",
    "authlib", "pyjwt", "python-jose", "jinja2", "nats-py",
    "launchdarkly-server-sdk",
]

# Key Node packages to track in the detail report
NODE_KEY_DEPS = [
    "vue", "nuxt", "react", "next", "angular", "@angular/core",
    "typescript", "vite", "webpack", "vitest", "jest", "cypress",
    "axios", "pinia", "vuex", "vue-router", "express", "tailwindcss",
    "@nuxt/ui", "primevue",
]

# Summary-level packages shown in the inventory table Major Tech Stack column
SUMMARY_DEPS = [
    "flask", "django", "fastapi", "sqlalchemy", "pydantic", "celery",
    "vue", "nuxt", "react", "next", "typescript", "vite", "postgresql", "redis",
]


# ── EOL helpers ───────────────────────────────────────────────────────────────

def extract_major_minor(version_str: str) -> tuple[int, int | None] | None:
    if not version_str or version_str in ("unspecified", "latest", "catalog:"):
        return None
    cleaned = re.sub(r"^[^0-9]*", "", version_str)
    m = re.match(r"(\d+)(?:\.(\d+))?", cleaned)
    if m:
        return int(m.group(1)), int(m.group(2)) if m.group(2) else None
    return None


def check_eol(package: str, version_str: str) -> tuple[bool, str]:
    if package not in EOL_VERSIONS:
        return False, ""
    version = extract_major_minor(version_str)
    if version is None:
        return False, ""
    pkg_major, pkg_minor = version
    for eol_major, eol_minor, _, note in EOL_VERSIONS[package]:
        if eol_minor is not None:
            if pkg_major < eol_major or (
                pkg_major == eol_major and (pkg_minor is None or pkg_minor <= eol_minor)
            ):
                return True, note
        else:
            if pkg_major <= eol_major:
                return True, note
    return False, ""


# ── GitHub API helpers ────────────────────────────────────────────────────────

def get_paginated(url: str) -> list:
    results = []
    while url:
        resp = requests.get(url, headers=HEADERS)
        resp.raise_for_status()
        results.extend(resp.json())
        url = resp.links.get("next", {}).get("url")
    return results


def get_file_content(owner: str, repo: str, path: str) -> str | None:
    url = f"https://api.github.com/repos/{owner}/{repo}/contents/{path}"
    resp = requests.get(url, headers=HEADERS)
    if resp.status_code != 200:
        return None
    data = resp.json()
    if data.get("encoding") == "base64":
        return base64.b64decode(data["content"]).decode("utf-8", errors="replace")
    return None


def get_repo_tree(owner: str, repo: str) -> list[str]:
    url = f"https://api.github.com/repos/{owner}/{repo}/git/trees/HEAD?recursive=1"
    resp = requests.get(url, headers=HEADERS)
    if resp.status_code != 200:
        return []
    return [item["path"] for item in resp.json().get("tree", []) if item["type"] == "blob"]


# ── Dependency file parsers ───────────────────────────────────────────────────

def parse_requirements_txt(content: str) -> dict:
    deps = {}
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("-"):
            continue
        m = re.match(r"^([a-zA-Z0-9_.-]+)\s*([><=!~]+\s*[\d.*]+)?", line)
        if m:
            pkg = m.group(1).lower().replace("_", "-")
            ver = m.group(2).strip() if m.group(2) else "unspecified"
            deps[pkg] = ver
    return deps


def parse_pyproject_toml(content: str) -> dict:
    deps = {}
    in_deps = False
    for line in content.splitlines():
        stripped = line.strip()
        if stripped in ("[project.dependencies]", "dependencies = [", "[tool.poetry.dependencies]"):
            in_deps = True
            continue
        if in_deps:
            if stripped.startswith("["):
                in_deps = False
                continue
            if not stripped:
                continue
            m = re.search(r'^["\']?([a-zA-Z0-9_.-]+)\s*([><=!~^]+\s*[\d.*]+)?', stripped)
            if m:
                pkg = m.group(1).lower().replace("_", "-")
                ver = m.group(2).strip() if m.group(2) else "unspecified"
                deps[pkg] = ver
            m2 = re.match(r'([a-zA-Z0-9_.-]+)\s*=\s*["\']([^"\']+)["\']', stripped)
            if m2:
                deps[m2.group(1).lower().replace("_", "-")] = m2.group(2)
    return deps


def parse_pipfile(content: str) -> dict:
    deps = {}
    in_packages = False
    for line in content.splitlines():
        stripped = line.strip()
        if stripped == "[packages]":
            in_packages = True
            continue
        if stripped.startswith("["):
            in_packages = False
            continue
        if in_packages:
            m = re.match(r'([a-zA-Z0-9_.-]+)\s*=\s*["\']([^"\']+)["\']', stripped)
            if m:
                deps[m.group(1).lower().replace("_", "-")] = m.group(2)
    return deps


def parse_package_json(content: str) -> dict:
    try:
        data = json.loads(content)
    except json.JSONDecodeError:
        return {}
    all_deps: dict = {}
    all_deps.update(data.get("dependencies", {}))
    all_deps.update(data.get("devDependencies", {}))
    # Capture node engine version
    node_ver = data.get("engines", {}).get("node")
    result = {k: v for k, v in all_deps.items() if k in NODE_KEY_DEPS or k in SUMMARY_DEPS}
    if node_ver:
        result["node"] = node_ver
    return result


def parse_dockerfile(content: str) -> str | None:
    """Extract Python version from a Dockerfile FROM line (major.minor only)."""
    for line in content.splitlines():
        stripped = line.strip()
        if not stripped.upper().startswith("FROM "):
            continue
        image = stripped.split()[1].lower()
        m = re.search(r'(?:^|/)python:([0-9]+\.[0-9]+(?:\.[0-9]+)?)', image)
        if m:
            return ".".join(m.group(1).split(".")[:2])
        m = re.search(r'python([0-9]+\.[0-9]+)', image)
        if m:
            return m.group(1)
    return None


# ── App type & tech stack ─────────────────────────────────────────────────────

def detect_app_type(path: str, deps: dict) -> str:
    path_lower = path.lower()
    deps_keys = [k.lower() for k in deps]
    if any(x in deps_keys for x in ["nuxt", "vue", "react", "next", "angular"]):
        return "frontend"
    if any(x in path_lower for x in ["-ui", "-web", "frontend", "site"]):
        return "frontend"
    if any(x in path_lower for x in ["job", "cron", "batch", "worker", "backfiller"]):
        return "job"
    if any(x in deps_keys for x in ["flask", "django", "fastapi", "express"]):
        return "backend"
    if "api" in path_lower:
        return "backend"
    if "service" in path_lower or "queue" in path_lower:
        return "service"
    return "service"


def format_tech_stack(deps: dict, python_version: str | None = None) -> str:
    found = []
    is_node = any(k in deps for k in ["nuxt", "vue", "react", "next", "typescript", "vite"])
    is_python = any(k in deps for k in ["flask", "django", "fastapi", "sqlalchemy"])

    if is_node:
        found.append("Node.js")
    elif is_python or python_version:
        if python_version:
            try:
                parts = python_version.split(".")
                major, minor = int(parts[0]), int(parts[1]) if len(parts) > 1 else 0
                eol_major, eol_minor = PYTHON_EOL_MAX
                is_eol = major < eol_major or (major == eol_major and minor <= eol_minor)
                label = f"Python {python_version}"
                found.append(f"**{label} (EOL)**" if is_eol else label)
            except (ValueError, IndexError):
                found.append(f"Python {python_version}")
        else:
            found.append("Python")

    EOL_LIMITS = {
        "vue": (3, 0), "nuxt": (3, 0), "flask": (3, 0),
        "sqlalchemy": (2, 0), "django": (4, 2), "fastapi": (0, 100), "react": (18, 0),
    }
    for pkg in SUMMARY_DEPS:
        if pkg not in deps:
            continue
        ver_raw = deps[pkg]
        ver = ver_raw.strip("^~=><! ")
        is_eol = False
        if pkg in EOL_LIMITS:
            m = re.search(r'(\d+)\.(\d+)', ver)
            if m:
                major, minor = int(m.group(1)), int(m.group(2))
                lim_maj, lim_min = EOL_LIMITS[pkg]
                is_eol = major < lim_maj or (major == lim_maj and minor < lim_min)
            else:
                m2 = re.search(r'^(\d+)$', ver)
                if m2 and int(m2.group(1)) < EOL_LIMITS[pkg][0]:
                    is_eol = True
        label = f"{pkg.capitalize()} {ver}" if ver != "unspecified" else f"{pkg.capitalize()}"
        found.append(f"**{label} (EOL)**" if is_eol else label)

    return ", ".join(found)


# ── Exclusions ────────────────────────────────────────────────────────────────

def should_exclude(repo_name: str, app_name: str) -> bool:
    IGNORE_REPOS = {
        "bcregistry-gcp-jobs", "bcregistry-sre", "entity",
        "sbc-producthub", "vue-test-utils-helpers",
    }
    EXCLUDE_EXACT = {
        ("developer.connect", "api"), ("ppr", "(root)"), ("business-ui", "(root)"),
        ("connect-nuxt", "(root)"), ("lear", "data-tool/find-tables"),
        ("lear", "data-tool/find-columns"), ("lear", "tests/data"),
        ("lear", "legal-api/tests/performance"),
        ("lear", "python/common/business-registry-common"),
        ("namex", "services/solr-names-updater"), ("namex", "solr"),
        ("sbc-pay", "releases"), ("registries-search", "search-ui"),
    }
    EXCLUDE_STARTSWITH = [
        "src/", "btr-web/btr-", "packages/configs/",
        "packages/layers/", "apps/demo/", "apps/stackblitz-template",
    ]
    if repo_name in IGNORE_REPOS:
        return True
    if (repo_name, app_name) in EXCLUDE_EXACT:
        return True
    if app_name.endswith("/requirements") or app_name == "requirements":
        return True
    if app_name in ["e2e", "testing"]:
        return True
    for prefix in EXCLUDE_STARTSWITH:
        if app_name.startswith(prefix):
            return True
    return False


# ── Repo scanner ──────────────────────────────────────────────────────────────

def scan_repo(owner: str, repo: str) -> list[dict]:
    apps = []
    tree = get_repo_tree(owner, repo)
    if not tree:
        return apps

    subprojects: dict[str, dict] = {}

    for path in tree:
        basename = os.path.basename(path)
        sp = os.path.dirname(path) or "(root)"

        def merge(sp, d):
            if sp not in subprojects:
                subprojects[sp] = {}
            subprojects[sp].update(d)

        if basename == "requirements.txt" or (path.endswith(".txt") and "/requirements/" in path):
            content = get_file_content(owner, repo, path)
            if content:
                merge(sp, parse_requirements_txt(content))
        elif basename == "pyproject.toml":
            content = get_file_content(owner, repo, path)
            if content:
                merge(sp, parse_pyproject_toml(content))
        elif basename == "Pipfile":
            content = get_file_content(owner, repo, path)
            if content:
                merge(sp, parse_pipfile(content))
        elif basename == "package.json" and "node_modules" not in path:
            content = get_file_content(owner, repo, path)
            if content:
                merge(sp, parse_package_json(content))
        elif basename == "Dockerfile" or re.match(r'Dockerfile\.\w+', basename):
            content = get_file_content(owner, repo, path)
            if content:
                py_ver = parse_dockerfile(content)
                if py_ver:
                    if sp not in subprojects:
                        subprojects[sp] = {}
                    subprojects[sp]["__python_version__"] = py_ver

    for sp, deps in subprojects.items():
        if not deps:
            continue
        if should_exclude(repo, sp):
            continue
        python_version = deps.pop("__python_version__", None)
        app_type = detect_app_type(sp, deps)
        tech_stack = format_tech_stack(deps, python_version=python_version)
        github_link = (
            f"https://github.com/{owner}/{repo}/tree/HEAD/{sp}"
            if sp != "(root)"
            else f"https://github.com/{owner}/{repo}"
        )
        # Collect key deps for the detail section
        key_deps = {
            k: v for k, v in deps.items()
            if k in PYTHON_KEY_DEPS or k in NODE_KEY_DEPS
        }
        apps.append({
            "repo_name": repo,
            "app_name": sp,
            "type": app_type,
            "tech_stack": tech_stack,
            "key_deps": key_deps,
            "link": github_link,
            "folder": sp,
        })

    return apps


# ── Report writers ────────────────────────────────────────────────────────────

def write_markdown(all_apps: list[dict], filepath: str):
    # Build flat EOL rows for the detail section
    eol_rows = []
    for app in all_apps:
        for pkg, ver in app["key_deps"].items():
            is_eol, note = check_eol(pkg, ver)
            if is_eol:
                eol_rows.append({
                    "repo": app["repo_name"],
                    "app": app["app_name"],
                    "package": pkg,
                    "version": ver,
                    "note": note,
                })

    with open(filepath, "w") as f:
        f.write("# Application Inventory\n\n")
        f.write(f"**Generated:** {TODAY}  \n")
        f.write(f"**Total Apps:** {len(all_apps)} | **EOL Dependencies:** {len(eol_rows)}\n\n")

        # ── Inventory table ───────────────────────────────────────────
        f.write("## App Inventory\n\n")
        f.write("| Repo | Application | Type | Major Tech Stack |\n")
        f.write("|:-----|:------------|:-----|:----------------|\n")
        for app in sorted(all_apps, key=lambda x: (x["repo_name"], x["app_name"])):
            f.write(
                f"| {app['repo_name']} | [{app['app_name']}]({app['link']}) "
                f"| {app['type'].capitalize()} | {app['tech_stack']} |\n"
            )

        # ── EOL summary ───────────────────────────────────────────────
        f.write("\n---\n\n## ⛔ EOL Dependencies\n\n")
        if not eol_rows:
            f.write("*No EOL dependencies found.*\n")
        else:
            f.write("| Repo | App | Package | Version | Note |\n")
            f.write("|:-----|:----|:--------|:--------|:-----|\n")
            for r in eol_rows:
                f.write(
                    f"| {r['repo']} | {r['app']} | {r['package']} "
                    f"| `{r['version']}` | {r['note']} |\n"
                )

        # ── Per-repo dependency detail (EOL only) ────────────────────
        f.write("\n---\n\n## ⚠️ Dependency Detail (EOL only)\n\n")
        repos = sorted(set(a["repo_name"] for a in all_apps))
        for repo in repos:
            repo_apps = [a for a in all_apps if a["repo_name"] == repo]
            # Only include apps that have at least one EOL package
            apps_with_eol = []
            for app in sorted(repo_apps, key=lambda x: x["app_name"]):
                eol_pkgs = {
                    pkg: ver for pkg, ver in app["key_deps"].items()
                    if check_eol(pkg, ver)[0]
                }
                if eol_pkgs:
                    apps_with_eol.append((app, eol_pkgs))

            if not apps_with_eol:
                continue

            eol_count = sum(len(pkgs) for _, pkgs in apps_with_eol)
            f.write(f"### [{repo}](https://github.com/bcgov/{repo}) — ⛔ {eol_count} EOL\n\n")
            for app, eol_pkgs in apps_with_eol:
                f.write(f"**[{app['app_name']}]({app['link']})** ({app['type']})\n\n")
                f.write("| Package | Version | Note |\n")
                f.write("|:--------|:--------|:-----|\n")
                for pkg, ver in sorted(eol_pkgs.items()):
                    _, note = check_eol(pkg, ver)
                    f.write(f"| {pkg} | `{ver}` | {note} |\n")
                f.write("\n")


def write_csv(all_apps: list[dict], filepath: str):
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["repo_name", "app_name", "type", "tech_stack", "folder", "link"]
        )
        writer.writeheader()
        for app in all_apps:
            writer.writerow({k: app[k] for k in writer.fieldnames})


def write_eol_csv(all_apps: list[dict], filepath: str):
    rows = []
    for app in all_apps:
        for pkg, ver in app["key_deps"].items():
            is_eol, note = check_eol(pkg, ver)
            if is_eol:
                rows.append({
                    "repo": app["repo_name"], "app": app["app_name"],
                    "package": pkg, "version": ver, "note": note,
                })
    if not rows:
        return
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["repo", "app", "package", "version", "note"])
        writer.writeheader()
        writer.writerows(rows)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Fetching managed bcgov repos...")
    repos_url = "https://api.github.com/user/repos?type=all&sort=updated&per_page=100"
    try:
        all_repos = get_paginated(repos_url)
    except Exception as e:
        print(f"Error fetching repos: {e}")
        return

    managed_repos = [
        r for r in all_repos
        if r.get("owner", {}).get("login") == "bcgov"
        and not r.get("archived", False)
    ]

    print(f"Found {len(managed_repos)} active bcgov repos. Scanning...")

    all_apps: list[dict] = []
    for i, repo in enumerate(managed_repos, 1):
        full_name = repo["full_name"]
        owner, name = full_name.split("/")
        sys.stdout.write(f"\r  [{i}/{len(managed_repos)}] {full_name}...".ljust(80))
        sys.stdout.flush()
        try:
            all_apps.extend(scan_repo(owner, name))
        except Exception:
            continue

    print("\n\nGenerating reports...")

    md_file   = os.path.join(OUTPUT_DIR, f"app_inventory_{TODAY}.md")
    csv_file  = os.path.join(OUTPUT_DIR, f"app_inventory_{TODAY}.csv")
    eol_file  = os.path.join(OUTPUT_DIR, f"app_inventory_eol_{TODAY}.csv")

    write_markdown(all_apps, md_file)
    write_csv(all_apps, csv_file)
    write_eol_csv(all_apps, eol_file)

    eol_count = sum(
        1 for a in all_apps
        for pkg, ver in a["key_deps"].items()
        if check_eol(pkg, ver)[0]
    )
    print(f"Done!")
    print(f"  Apps found       : {len(all_apps)}")
    print(f"  EOL dependencies : {eol_count}")
    print(f"  Markdown         : {md_file}")
    print(f"  CSV              : {csv_file}")
    if eol_count:
        print(f"  EOL CSV          : {eol_file}")


if __name__ == "__main__":
    main()
