# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "google-cloud-run",
#     "google-auth"
# ]
# ///
"""
Scan all Cloud Run services and jobs across production GCP projects for environment
variables referencing the OpenShift Silver cluster (silver.devops.gov.bc.ca).

Supports value-level and key-level ignore patterns. Outputs both a console
summary and a Markdown report grouped by project.

Usage:
    uv run scan_openshift_silver_refs.py
    uv run scan_openshift_silver_refs.py --projects a083gt-prod,c4hnrd-prod
    uv run scan_openshift_silver_refs.py --target gold.devops.gov.bc.ca
    uv run scan_openshift_silver_refs.py --output output/my_report.md
"""

import argparse
import os
from datetime import datetime

import google.auth
from google.cloud import run_v2

# ── Defaults ──────────────────────────────────────────────────────────────────
DEFAULT_PROJECTS = [
    "a083gt-prod", "bcrbk9-prod", "c4hnrd-prod", "eogruh-prod",
    "gtksf3-prod", "yfjq17-prod", "yfthig-prod", "k973yf-prod",
    "keee67-prod", "mvnjri-prod", "okagqp-prod"
]
DEFAULT_TARGET = ".silver.devops.gov.bc.ca"

# Env var VALUES containing these strings will be skipped
IGNORE_VALUE_PATTERNS = ["pay-connector", "namex-solr", "traction-tenant", "minio", "ocp-relay"]

# Env var KEYS matching these will be skipped
IGNORE_KEY_PATTERNS = ["VALID_REDIRECT_URLS"]

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")


def is_ignored_value(value: str) -> bool:
    return any(p.lower() in value.lower() for p in IGNORE_VALUE_PATTERNS)


def is_ignored_key(key: str) -> bool:
    return any(p.lower() in key.lower() for p in IGNORE_KEY_PATTERNS)


def scan_services(client: run_v2.ServicesClient, project_id: str, target: str) -> list[dict]:
    """Scan all Cloud Run services across all regions in a project."""
    findings = []
    parent = f"projects/{project_id}/locations/-"
    try:
        for service in client.list_services(parent=parent):
            svc_name = service.name.split("/")[-1]
            location = service.name.split("/")[3]
            for container in service.template.containers:
                for env in container.env:
                    if not env.value:
                        continue
                    if target.lower() in env.value.lower() and not is_ignored_value(env.value) and not is_ignored_key(env.name):
                        findings.append({
                            "resource_type": "Service",
                            "name": svc_name,
                            "location": location,
                            "env_key": env.name,
                            "env_value": env.value,
                        })
    except Exception as e:
        print(f"  ⚠️  Error scanning services in {project_id}: {e}")
    return findings


def scan_jobs(client: run_v2.JobsClient, project_id: str, target: str) -> list[dict]:
    """Scan all Cloud Run jobs across all regions in a project."""
    findings = []
    parent = f"projects/{project_id}/locations/-"
    try:
        for job in client.list_jobs(parent=parent):
            job_name = job.name.split("/")[-1]
            location = job.name.split("/")[3]
            for container in job.template.template.containers:
                for env in container.env:
                    if not env.value:
                        continue
                    if target.lower() in env.value.lower() and not is_ignored_value(env.value) and not is_ignored_key(env.name):
                        findings.append({
                            "resource_type": "Job",
                            "name": job_name,
                            "location": location,
                            "env_key": env.name,
                            "env_value": env.value,
                        })
    except Exception as e:
        print(f"  ⚠️  Error scanning jobs in {project_id}: {e}")
    return findings


def main():
    parser = argparse.ArgumentParser(description="Scan Cloud Run env vars for OpenShift Silver cluster references")
    parser.add_argument("--projects", help="Comma-separated project IDs (default: all prod projects)")
    parser.add_argument("--target", default=DEFAULT_TARGET, help="String to search for in env var values")
    parser.add_argument("--no-filter", action="store_true", help="Disable ignore patterns and show all matches")
    parser.add_argument("--output", help="Output Markdown file (defaults to output/ folder)")
    args = parser.parse_args()

    if args.no_filter:
        IGNORE_VALUE_PATTERNS.clear()
        IGNORE_KEY_PATTERNS.clear()

    projects = [p.strip() for p in args.projects.split(",")] if args.projects else DEFAULT_PROJECTS
    target = args.target
    today = datetime.now().strftime("%Y-%m-%d")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = args.output or os.path.join(OUTPUT_DIR, f"silver_envvar_refs_{today}.md")

    credentials, _ = google.auth.default()
    svc_client = run_v2.ServicesClient(credentials=credentials)
    job_client = run_v2.JobsClient(credentials=credentials)

    print(f"{'=' * 55}")
    print(f"  Cloud Run Environment Variable Scanner")
    print(f"{'=' * 55}")
    print(f"  Search String : {target}")
    print(f"  Projects      : {len(projects)}")
    print(f"{'=' * 55}\n")

    all_findings: dict[str, list[dict]] = {}

    for project_id in projects:
        print(f"{'━' * 47}")
        print(f"Project: {project_id}")
        print(f"{'━' * 47}")

        print("  Scanning Cloud Run services...")
        service_findings = scan_services(svc_client, project_id, target)

        print("  Scanning Cloud Run jobs...")
        job_findings = scan_jobs(job_client, project_id, target)

        findings = service_findings + job_findings
        if findings:
            all_findings[project_id] = findings
            for f in findings:
                print(f"  ⚠️  {f['resource_type']}: {f['name']} ({f['location']})")
                print(f"        ENV VAR : {f['env_key']}")
                print(f"        VALUE   : {f['env_value']}\n")
        else:
            print("  ✅ No matches found.\n")

    total_matches = sum(len(v) for v in all_findings.values())

    # ── Console summary ───────────────────────────────────────────────────────
    print(f"{'=' * 55}")
    print(f"  SCAN RESULTS  ({total_matches} match{'es' if total_matches != 1 else ''})")
    print(f"{'=' * 55}")
    if all_findings:
        for project_id, findings in sorted(all_findings.items()):
            for f in findings:
                print(f"[{project_id}] {f['resource_type']}: {f['name']} ({f['location']})")
                print(f"  └─ {f['env_key']} = {f['env_value']}")

    # ── Write Markdown ────────────────────────────────────────────────────────
    md_lines = [
        f"# Cloud Run Env Var Scan: `{target}`",
        "",
        f"**Scan Date:** {today}  ",
        f"**Projects Scanned:** {len(projects)} | **Total Matches:** {total_matches}",
        "",
        "---",
        "",
        "| Project | Type | Name | Location | Env Key | Env Value |",
        "|:---|:---|:---|:---|:---|:---|",
    ]

    for project_id in projects:
        for f in all_findings.get(project_id, []):
            md_lines.append(
                f"| {project_id} | {f['resource_type']} | {f['name']} | {f['location']} "
                f"| `{f['env_key']}` | `{f['env_value']}` |"
            )

    md_lines += ["", "---", ""]

    # Per-project breakdown section
    md_lines.append("## Per-Project Breakdown\n")
    for project_id in projects:
        md_lines.append(f"### {project_id}\n")
        if project_id not in all_findings:
            md_lines.append("✅ No matches found.\n")
            continue

        findings = all_findings[project_id]
        service_rows = [f for f in findings if f["resource_type"] == "Service"]
        job_rows = [f for f in findings if f["resource_type"] == "Job"]

        if service_rows:
            md_lines += ["**Cloud Run Services**\n", "| Service | Location | Env Key | Value |", "|---------|----------|---------|-------|"]
            for f in service_rows:
                md_lines.append(f"| {f['name']} | {f['location']} | `{f['env_key']}` | `{f['env_value']}` |")
            md_lines.append("")

        if job_rows:
            md_lines += ["**Cloud Run Jobs**\n", "| Job | Location | Env Key | Value |", "|-----|----------|---------|-------|"]
            for f in job_rows:
                md_lines.append(f"| {f['name']} | {f['location']} | `{f['env_key']}` | `{f['env_value']}` |")
            md_lines.append("")

    with open(output_path, "w") as out_file:
        out_file.write("\n".join(md_lines))

    print(f"\n  Results saved to : {output_path}")
    print(f"{'=' * 55}")


if __name__ == "__main__":
    main()
