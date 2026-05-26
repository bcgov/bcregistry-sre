# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "google-cloud-monitoring",
#     "google-auth"
# ]
# ///
"""
List all Uptime Checks across production GCP projects and their monitored endpoints.
Outputs a Markdown report grouped by project.

Usage:
    uv run scan_uptime_checks.py
    uv run scan_uptime_checks.py --projects a083gt-prod,c4hnrd-prod
    uv run scan_uptime_checks.py --output output/uptime_checks.md
"""

import argparse
import os
from datetime import datetime

import google.auth
from google.cloud import monitoring_v3

DEFAULT_PROJECTS = [
    "a083gt-prod", "bcrbk9-prod", "c4hnrd-prod", "eogruh-prod",
    "gtksf3-prod", "yfjq17-prod", "yfthig-prod", "k973yf-prod",
    "keee67-prod", "mvnjri-prod", "okagqp-prod"
]

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")


def get_uptime_checks(client: monitoring_v3.UptimeCheckServiceClient, project_id: str) -> list[dict]:
    """List all uptime checks for a given project."""
    checks = []
    try:
        for check in client.list_uptime_check_configs(parent=f"projects/{project_id}"):
            # Determine the monitored resource type and endpoint
            resource_type = check.monitored_resource.type if check.monitored_resource else "N/A"

            # Extract host/URL from the appropriate checker type
            endpoint = "N/A"
            protocol = "N/A"
            path = ""

            if check.http_check.path:
                protocol = "HTTPS" if check.http_check.use_ssl else "HTTP"
                path = check.http_check.path or "/"
                port = check.http_check.port or (443 if check.http_check.use_ssl else 80)

                if check.monitored_resource.type == "uptime_url":
                    host = check.monitored_resource.labels.get("host", "")
                    endpoint = f"{protocol.lower()}://{host}:{port}{path}" if port not in (80, 443) else f"{protocol.lower()}://{host}{path}"
                elif check.monitored_resource.type == "gce_instance":
                    endpoint = f"{protocol.lower()}://<gce-instance>{path}"
                elif check.monitored_resource.type == "k8s_service":
                    ns = check.monitored_resource.labels.get("namespace", "")
                    svc = check.monitored_resource.labels.get("service_name", "")
                    endpoint = f"{protocol.lower()}://{svc}.{ns}{path}"
                else:
                    host = check.monitored_resource.labels.get("host", resource_type)
                    endpoint = f"{protocol.lower()}://{host}{path}"

            elif check.tcp_check.port:
                protocol = "TCP"
                host = check.monitored_resource.labels.get("host", "")
                port = check.tcp_check.port
                endpoint = f"tcp://{host}:{port}"

            checks.append({
                "display_name": check.display_name,
                "check_id": check.name.split("/")[-1],
                "protocol": protocol,
                "endpoint": endpoint,
                "resource_type": resource_type,
                "period": f"{check.period.seconds}s",
                "timeout": f"{check.timeout.seconds}s",
                "regions": ", ".join(str(r) for r in check.selected_regions) or "global",
            })
    except Exception as e:
        print(f"  ⚠️  Error fetching uptime checks for {project_id}: {e}")
    return checks


def main():
    parser = argparse.ArgumentParser(description="List all GCP Uptime Checks across prod projects")
    parser.add_argument("--projects", help="Comma-separated project IDs (default: all prod projects)")
    parser.add_argument("--output", help="Output Markdown file (defaults to output/ folder)")
    args = parser.parse_args()

    projects = [p.strip() for p in args.projects.split(",")] if args.projects else DEFAULT_PROJECTS
    today = datetime.now().strftime("%Y-%m-%d")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = args.output or os.path.join(OUTPUT_DIR, f"uptime_checks_{today}.md")

    credentials, _ = google.auth.default()
    client = monitoring_v3.UptimeCheckServiceClient(credentials=credentials)

    print(f"{'=' * 60}")
    print(f"  GCP Uptime Check Scanner")
    print(f"{'=' * 60}")
    print(f"  Projects: {len(projects)}")
    print(f"{'=' * 60}\n")

    all_results: dict[str, list[dict]] = {}
    total_checks = 0

    for project_id in projects:
        print(f"Scanning: {project_id}...")
        checks = get_uptime_checks(client, project_id)
        if checks:
            all_results[project_id] = checks
            total_checks += len(checks)
            for c in checks:
                print(f"  ✅ {c['display_name']}")
                print(f"     {c['protocol']}  {c['endpoint']}")
        else:
            print(f"  — No uptime checks found.")

    # ── Markdown output ────────────────────────────────────────────────────────
    md_lines = [
        "# GCP Uptime Checks",
        "",
        f"**Generated:** {today}  ",
        f"**Projects Scanned:** {len(projects)} | **Total Checks:** {total_checks}",
        "",
        "---",
        "",
        "## Summary",
        "",
        "| Project | Display Name | Protocol | Endpoint | Period | Timeout |",
        "|:--------|:-------------|:---------|:---------|:-------|:--------|",
    ]

    for project_id in projects:
        for c in all_results.get(project_id, []):
            md_lines.append(
                f"| {project_id} | {c['display_name']} | {c['protocol']} "
                f"| `{c['endpoint']}` | {c['period']} | {c['timeout']} |"
            )

    md_lines += ["", "---", "", "## Per-Project Detail", ""]

    for project_id in projects:
        checks = all_results.get(project_id, [])
        md_lines.append(f"### {project_id}\n")
        if not checks:
            md_lines.append("*No uptime checks configured.*\n")
            continue

        md_lines += [
            "| Display Name | Protocol | Endpoint | Period | Timeout | Regions |",
            "|:-------------|:---------|:---------|:-------|:--------|:--------|",
        ]
        for c in checks:
            md_lines.append(
                f"| {c['display_name']} | {c['protocol']} | `{c['endpoint']}` "
                f"| {c['period']} | {c['timeout']} | {c['regions']} |"
            )
        md_lines.append("")

    with open(output_path, "w") as f:
        f.write("\n".join(md_lines))

    print(f"\n{'=' * 60}")
    print(f"  Total checks found : {total_checks}")
    print(f"  Report saved to    : {output_path}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
