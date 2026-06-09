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
import tomllib
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
    "flask",
    "django",
    "fastapi",
    "starlette",
    "uvicorn",
    "gunicorn",
    "sqlalchemy",
    "alembic",
    "celery",
    "redis",
    "psycopg2",
    "psycopg2-binary",
    "pydantic",
    "marshmallow",
    "pytest",
    "requests",
    "httpx",
    "aiohttp",
    "sentry-sdk",
    "google-cloud-storage",
    "google-cloud-pubsub",
    "google-cloud-secret-manager",
    "protobuf",
    "grpcio",
    "cryptography",
    "authlib",
    "pyjwt",
    "python-jose",
    "jinja2",
    "nats-py",
    "launchdarkly-server-sdk",
]

# Key Node packages to track in the detail report
NODE_KEY_DEPS = [
    "vue",
    "nuxt",
    "react",
    "next",
    "angular",
    "@angular/core",
    "typescript",
    "vite",
    "webpack",
    "vitest",
    "jest",
    "cypress",
    "axios",
    "pinia",
    "vuex",
    "vue-router",
    "express",
    "tailwindcss",
    "@nuxt/ui",
    "primevue",
]

# Summary-level packages shown in the inventory table Major Tech Stack column
SUMMARY_DEPS = [
    "flask",
    "django",
    "fastapi",
    "sqlalchemy",
    "pydantic",
    "celery",
    "vue",
    "nuxt",
    "react",
    "next",
    "typescript",
    "vite",
    "postgresql",
    "redis",
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
    return [
        item["path"] for item in resp.json().get("tree", []) if item["type"] == "blob"
    ]


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
    """Parse pyproject.toml using tomllib.

    Handles PEP 621 ([project] dependencies + optional-dependencies),
    PEP 735 ([dependency-groups]), and Poetry ([tool.poetry.dependencies]
    + group dependencies, including inline tables).
    """
    try:
        data = tomllib.loads(content)
    except Exception:
        return {}

    deps: dict[str, str] = {}

    def add(name: str, ver: str = "unspecified") -> None:
        pkg = name.lower().replace("_", "-")
        # Prefer a concrete version over "unspecified" if seen multiple times
        if pkg not in deps or deps[pkg] == "unspecified":
            deps[pkg] = ver

    def parse_pep508(spec: str) -> tuple[str | None, str]:
        # Strip env marker (everything after ';') and extras (e.g. [asyncio])
        spec = spec.split(";", 1)[0].strip()
        spec = re.sub(r"\[[^\]]*\]", "", spec).strip()
        # Name, then optional version constraint — possibly wrapped in (...)
        m = re.match(r"^([a-zA-Z0-9_.-]+)\s*(?:\(([^)]*)\)|([><=!~].*))?$", spec)
        if not m:
            return None, "unspecified"
        name = m.group(1)
        ver = (m.group(2) or m.group(3) or "").strip()
        return name, ver or "unspecified"

    # ── PEP 621: [project].dependencies / optional-dependencies
    project = data.get("project", {})
    for dep in project.get("dependencies", []) or []:
        name, ver = parse_pep508(dep)
        if name:
            add(name, ver)
    for group_deps in (project.get("optional-dependencies", {}) or {}).values():
        for dep in group_deps or []:
            name, ver = parse_pep508(dep)
            if name:
                add(name, ver)

    # Capture requires-python (PEP 621) or tool.poetry.dependencies.python
    requires_python = project.get("requires-python")

    # ── PEP 735: [dependency-groups]
    for group_deps in (data.get("dependency-groups", {}) or {}).values():
        for dep in group_deps or []:
            if isinstance(dep, str):
                name, ver = parse_pep508(dep)
                if name:
                    add(name, ver)

    # ── Poetry: [tool.poetry.dependencies] + group dependencies
    poetry = data.get("tool", {}).get("poetry", {})
    poetry_python = (poetry.get("dependencies", {}) or {}).get("python")
    for name, spec in (poetry.get("dependencies", {}) or {}).items():
        if name.lower() == "python":
            continue
        if isinstance(spec, str):
            add(name, spec)
        elif isinstance(spec, dict):
            add(name, spec.get("version", "unspecified"))
    for group in (poetry.get("group", {}) or {}).values():
        for name, spec in (group.get("dependencies", {}) or {}).items():
            if name.lower() == "python":
                continue
            if isinstance(spec, str):
                add(name, spec)
            elif isinstance(spec, dict):
                add(name, spec.get("version", "unspecified"))

    # Surface python version as a sentinel key so caller can use it as a
    # fallback when no Dockerfile is present.
    py_spec = requires_python or (
        poetry_python if isinstance(poetry_python, str) else None
    )
    if py_spec:
        m = re.search(r"(\d+\.\d+)", py_spec)
        if m:
            deps["__python_requires__"] = m.group(1)

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
    result = {
        k: v for k, v in all_deps.items() if k in NODE_KEY_DEPS or k in SUMMARY_DEPS
    }
    if node_ver:
        result["node"] = node_ver
    return result


def parse_pnpm_workspace(content: str) -> dict:
    """Extract default and named pnpm catalogs from pnpm-workspace.yaml.

    Returns a flat dict mapping package name -> version, with the default
    catalog and all named catalogs merged together (default takes precedence).
    Falls back to a forgiving line-by-line parser if PyYAML isn't available.
    """
    catalogs: dict[str, dict[str, str]] = {"default": {}}
    try:
        import yaml  # type: ignore[import-untyped]

        data = yaml.safe_load(content) or {}
        if isinstance(data.get("catalog"), dict):
            catalogs["default"].update({k: str(v) for k, v in data["catalog"].items()})
        if isinstance(data.get("catalogs"), dict):
            for name, entries in data["catalogs"].items():
                if isinstance(entries, dict):
                    catalogs[name] = {k: str(v) for k, v in entries.items()}
    except ImportError:
        # Minimal YAML fallback: parse `catalog:` block (single-level mapping)
        in_catalog = False
        base_indent: int | None = None
        for raw in content.splitlines():
            line = raw.rstrip()
            if not line or line.lstrip().startswith("#"):
                continue
            stripped = line.lstrip()
            indent = len(line) - len(stripped)
            if stripped.startswith("catalog:") and stripped.endswith(":"):
                in_catalog = True
                base_indent = None
                continue
            if in_catalog:
                if base_indent is None:
                    base_indent = indent
                if indent < base_indent:
                    in_catalog = False
                    continue
                m = re.match(
                    r"^['\"]?([@\w./-]+)['\"]?\s*:\s*['\"]?([^'\"#]+?)['\"]?\s*$",
                    stripped,
                )
                if m:
                    catalogs["default"][m.group(1)] = m.group(2).strip()

    # Merge all catalogs into a single lookup; default wins
    merged: dict[str, str] = {}
    for name, entries in catalogs.items():
        if name != "default":
            merged.update(entries)
    merged.update(catalogs.get("default", {}))
    return merged


def resolve_catalog_versions(deps: dict, catalog: dict) -> dict:
    """Replace pnpm catalog: specifiers with concrete versions when known."""
    if not catalog:
        return deps
    resolved = {}
    for name, ver in deps.items():
        if isinstance(ver, str) and ver.startswith("catalog:"):
            # `catalog:` (default) or `catalog:named` — both look up by package name
            resolved[name] = catalog.get(name, ver)
        else:
            resolved[name] = ver
    return resolved


def parse_dockerfile(content: str) -> str | None:
    """Extract Python version from a Dockerfile FROM line (major.minor only)."""
    for line in content.splitlines():
        stripped = line.strip()
        if not stripped.upper().startswith("FROM "):
            continue
        image = stripped.split()[1].lower()
        m = re.search(r"(?:^|/)python:([0-9]+\.[0-9]+(?:\.[0-9]+)?)", image)
        if m:
            return ".".join(m.group(1).split(".")[:2])
        m = re.search(r"python([0-9]+\.[0-9]+)", image)
        if m:
            return m.group(1)
    return None


def parse_workflow_node_version(content: str) -> str | None:
    """Extract a Node.js version hint from a CI workflow YAML.

    Looks for `node-version: <ver>`, `node-version-file:` is ignored
    (it points at .nvmrc/.node-version which we already scan). Also tries
    `FROM node:<ver>` style references in inline scripts.
    Returns the first concrete major[.minor] string found.
    """
    for raw in content.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        # node-version: '20' / "20.x" / 20.10.0
        m = re.match(r"node-version\s*:\s*['\"]?([\d.x*]+)['\"]?", line, re.IGNORECASE)
        if m and m.group(1).strip(".x*"):
            ver = m.group(1).strip(".x*")
            m2 = re.match(r"(\d+)(?:\.(\d+))?", ver)
            if m2:
                return f"{m2.group(1)}.{m2.group(2)}" if m2.group(2) else m2.group(1)
        # FROM node:20-alpine
        m = re.search(r"\bnode:([0-9]+(?:\.[0-9]+)?)", line)
        if m:
            return m.group(1)
    return None


def parse_nvmrc(content: str) -> str | None:
    """Extract Node version from .nvmrc / .node-version (single-line)."""
    for raw in content.splitlines():
        line = raw.strip().lstrip("v")
        if not line or line.startswith("#"):
            continue
        m = re.match(r"(\d+)(?:\.(\d+))?", line)
        if m:
            return f"{m.group(1)}.{m.group(2)}" if m.group(2) else m.group(1)
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
    is_node = any(
        k in deps for k in ["nuxt", "vue", "react", "next", "typescript", "vite"]
    )
    is_python = any(k in deps for k in ["flask", "django", "fastapi", "sqlalchemy"])

    if is_node:
        node_raw = deps.get("node")
        if node_raw:
            # Extract first major[.minor] from specs like ">=20.10", "^22", "20.x"
            m = re.search(r"(\d+)(?:\.(\d+))?", str(node_raw))
            if m:
                major = int(m.group(1))
                ver = f"{major}.{m.group(2)}" if m.group(2) else f"{major}"
                # EOL check via EOL_VERSIONS["node"]
                is_eol = False
                for max_major, _, _, _ in EOL_VERSIONS.get("node", []):
                    if major <= max_major:
                        is_eol = True
                        break
                label = f"Node.js {ver}"
                found.append(f"**{label} (EOL)**" if is_eol else label)
            else:
                found.append(f"Node.js {node_raw}")
        else:
            found.append("Node.js")
    elif is_python or python_version:
        if python_version:
            try:
                parts = python_version.split(".")
                major, minor = int(parts[0]), int(parts[1]) if len(parts) > 1 else 0
                eol_major, eol_minor = PYTHON_EOL_MAX
                is_eol = major < eol_major or (
                    major == eol_major and minor <= eol_minor
                )
                label = f"Python {python_version}"
                found.append(f"**{label} (EOL)**" if is_eol else label)
            except (ValueError, IndexError):
                found.append(f"Python {python_version}")
        else:
            found.append("Python")

    EOL_LIMITS = {
        "vue": (3, 0),
        "nuxt": (3, 0),
        "flask": (3, 0),
        "sqlalchemy": (2, 0),
        "django": (4, 2),
        "fastapi": (0, 100),
        "react": (18, 0),
    }
    for pkg in SUMMARY_DEPS:
        if pkg not in deps:
            continue
        ver_raw = deps[pkg]
        # Extract just the first concrete version number (e.g. ">=3.1.0,<4.0.0" -> "3.1.0")
        ver_match = re.search(r"(\d+(?:\.\d+)*)", ver_raw)
        ver = ver_match.group(1) if ver_match else ver_raw.strip("^~=><!()[] ")
        is_eol = False
        if pkg in EOL_LIMITS:
            m = re.search(r"(\d+)\.(\d+)", ver)
            if m:
                major, minor = int(m.group(1)), int(m.group(2))
                lim_maj, lim_min = EOL_LIMITS[pkg]
                is_eol = major < lim_maj or (major == lim_maj and minor < lim_min)
            else:
                m2 = re.search(r"^(\d+)$", ver)
                if m2 and int(m2.group(1)) < EOL_LIMITS[pkg][0]:
                    is_eol = True
        label = (
            f"{pkg.capitalize()} {ver}"
            if ver and ver_raw != "unspecified"
            else f"{pkg.capitalize()}"
        )
        found.append(f"**{label} (EOL)**" if is_eol else label)

    return ", ".join(found)


# ── Exclusions ────────────────────────────────────────────────────────────────


def should_exclude(repo_name: str, app_name: str) -> bool:
    IGNORE_REPOS = {
        "bcregistry-gcp-jobs",
        "bcregistry-sre",
        "entity",
        "sbc-producthub",
        "vue-test-utils-helpers",
    }
    EXCLUDE_EXACT = {
        ("developer.connect", "api"),
        ("ppr", "(root)"),
        ("ppr", "archive"),
        ("business-ui", "(root)"),
        ("connect-nuxt", "(root)"),
        ("lear", "colin-api/.devcontainer"),
        ("lear", "data-tool"),
        ("lear", "data-tool/find-columns"),
        ("lear", "data-tool/find-tables"),
        ("lear", "tests/data"),
        ("lear", "legal-api/tests/performance"),
        ("lear", "python/common/business-registry-common"),
        ("namex", "services/auto-analyze"),
        ("namex", "services/auto-analyze/.devcontainer"),
        ("namex", "services/solr-names-updater"),
        ("namex", "solr"),
        ("sbc-pay", "releases"),
        ("registries-search", "search-ui"),
    }
    EXCLUDE_STARTSWITH = [
        "src/",
        "btr-web/btr-",
        "packages/configs/",
        "packages/layers/",
        "apps/demo/",
        "apps/stackblitz-template",
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
    # Resolve pnpm catalogs keyed by the directory containing pnpm-workspace.yaml
    # so a subproject can be matched to the nearest workspace ancestor.
    pnpm_catalogs: dict[str, dict] = {}
    # Per-directory Node.js version hints from .nvmrc / .node-version
    nvmrc_versions: dict[str, str] = {}
    # Repo-wide Node.js version hints from .github/workflows/*.y(a)ml — last wins
    workflow_node_version: str | None = None

    for path in tree:
        basename = os.path.basename(path)
        sp = os.path.dirname(path) or "(root)"

        def merge(sp, d):
            if sp not in subprojects:
                subprojects[sp] = {}
            subprojects[sp].update(d)

        if basename == "requirements.txt" or (
            path.endswith(".txt") and "/requirements/" in path
        ):
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
        elif basename == "pnpm-workspace.yaml" and "node_modules" not in path:
            content = get_file_content(owner, repo, path)
            if content:
                pnpm_catalogs[sp] = parse_pnpm_workspace(content)
        elif basename in (".nvmrc", ".node-version"):
            content = get_file_content(owner, repo, path)
            if content:
                ver = parse_nvmrc(content)
                if ver:
                    nvmrc_versions[sp] = ver
        elif path.startswith(".github/workflows/") and basename.endswith(
            (".yml", ".yaml")
        ):
            content = get_file_content(owner, repo, path)
            if content:
                ver = parse_workflow_node_version(content)
                if ver:
                    workflow_node_version = ver
        elif basename == "Dockerfile" or re.match(r"Dockerfile\.\w+", basename):
            content = get_file_content(owner, repo, path)
            if content:
                py_ver = parse_dockerfile(content)
                if py_ver:
                    if sp not in subprojects:
                        subprojects[sp] = {}
                    subprojects[sp]["__python_version__"] = py_ver

    def lookup_catalog(sp: str) -> dict:
        # Find the nearest ancestor directory that has a pnpm-workspace catalog
        if not pnpm_catalogs:
            return {}
        candidates = [d for d in pnpm_catalogs if sp == d or sp.startswith(d + "/")]
        if not candidates:
            # Also allow root catalog ("(root)") to apply to all subprojects
            return pnpm_catalogs.get("(root)", {})
        return pnpm_catalogs[max(candidates, key=len)]

    def lookup_node_version(sp: str) -> str | None:
        # Nearest .nvmrc / .node-version ancestor, else repo-wide CI workflow hint
        if nvmrc_versions:
            candidates = [
                d for d in nvmrc_versions if sp == d or sp.startswith(d + "/")
            ]
            if candidates:
                return nvmrc_versions[max(candidates, key=len)]
            if "(root)" in nvmrc_versions:
                return nvmrc_versions["(root)"]
        return workflow_node_version

    for sp, deps in subprojects.items():
        if not deps:
            continue
        if should_exclude(repo, sp):
            continue
        python_version = deps.pop("__python_version__", None)
        # Fall back to pyproject.toml requires-python if no Dockerfile was found
        python_requires = deps.pop("__python_requires__", None)
        if not python_version and python_requires:
            python_version = python_requires
        # Resolve pnpm catalog: specifiers against the nearest workspace
        deps = resolve_catalog_versions(deps, lookup_catalog(sp))
        # Fall back to .nvmrc / CI workflow node-version when package.json has no engines.node
        if "node" not in deps:
            node_fallback = lookup_node_version(sp)
            if node_fallback:
                deps = {**deps, "node": node_fallback}
        app_type = detect_app_type(sp, deps)
        tech_stack = format_tech_stack(deps, python_version=python_version)
        github_link = (
            f"https://github.com/{owner}/{repo}/tree/HEAD/{sp}"
            if sp != "(root)"
            else f"https://github.com/{owner}/{repo}"
        )
        # Collect key deps for the detail section
        key_deps = {
            k: v for k, v in deps.items() if k in PYTHON_KEY_DEPS or k in NODE_KEY_DEPS
        }
        apps.append(
            {
                "repo_name": repo,
                "app_name": sp,
                "type": app_type,
                "tech_stack": tech_stack,
                "key_deps": key_deps,
                "link": github_link,
                "folder": sp,
            }
        )

    return apps


# ── Report writers ────────────────────────────────────────────────────────────


def write_markdown(all_apps: list[dict], filepath: str):
    # Build flat EOL rows for the detail section
    eol_rows = []
    for app in all_apps:
        for pkg, ver in app["key_deps"].items():
            is_eol, note = check_eol(pkg, ver)
            if is_eol:
                eol_rows.append(
                    {
                        "repo": app["repo_name"],
                        "app": app["app_name"],
                        "package": pkg,
                        "version": ver,
                        "note": note,
                    }
                )

    with open(filepath, "w") as f:
        f.write("# Application Inventory\n\n")
        f.write(f"**Generated:** {TODAY}  \n")
        f.write(
            f"**Total Apps:** {len(all_apps)} | **EOL Dependencies:** {len(eol_rows)}\n\n"
        )

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
                    pkg: ver
                    for pkg, ver in app["key_deps"].items()
                    if check_eol(pkg, ver)[0]
                }
                if eol_pkgs:
                    apps_with_eol.append((app, eol_pkgs))

            if not apps_with_eol:
                continue

            eol_count = sum(len(pkgs) for _, pkgs in apps_with_eol)
            f.write(
                f"### [{repo}](https://github.com/bcgov/{repo}) — ⛔ {eol_count} EOL\n\n"
            )
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
            f,
            fieldnames=[
                "repo_name",
                "app_name",
                "type",
                "tech_stack",
                "folder",
                "link",
            ],
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
                rows.append(
                    {
                        "repo": app["repo_name"],
                        "app": app["app_name"],
                        "package": pkg,
                        "version": ver,
                        "note": note,
                    }
                )
    if not rows:
        return
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["repo", "app", "package", "version", "note"]
        )
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
        r
        for r in all_repos
        if r.get("owner", {}).get("login") == "bcgov" and not r.get("archived", False)
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

    md_file = os.path.join(OUTPUT_DIR, f"app_inventory_{TODAY}.md")
    csv_file = os.path.join(OUTPUT_DIR, f"app_inventory_{TODAY}.csv")
    eol_file = os.path.join(OUTPUT_DIR, f"app_inventory_eol_{TODAY}.csv")

    write_markdown(all_apps, md_file)
    write_csv(all_apps, csv_file)
    write_eol_csv(all_apps, eol_file)

    eol_count = sum(
        1
        for a in all_apps
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
