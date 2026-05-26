# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "google-auth",
#     "google-auth-httplib2",
#     "requests"
# ]
# ///
"""
List Apigee API proxies, environments, target servers, and KVM entries for a GCP project.
Saves endpoint URLs found in KVMs to a Markdown report.

NOTE: For BC Registry, `okagqp-test` is the single Apigee org that hosts both
prod and dev proxies (e.g. strr-apiproxy + strr-dev-apiproxy in the same org).
`okagqp-prod` has the Apigee API enabled but no org provisioned.

Usage:
    uv run scan_apigee_endpoints.py --project okagqp-test
    uv run scan_apigee_endpoints.py --project okagqp-test --output output/apigee_report.md
"""

import argparse
import os
import sys
from datetime import datetime

import requests
import google.auth
import google.auth.transport.requests

APIGEE_BASE = "https://apigee.googleapis.com/v1"
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")


def get_token() -> str:
    credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    credentials.refresh(google.auth.transport.requests.Request())
    return credentials.token


def api_get(token: str, url: str) -> tuple[dict | list | None, str | None]:
    """GET a URL with Bearer auth. Returns (data, error_message)."""
    try:
        resp = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=15)
        if resp.status_code == 200:
            return resp.json(), None
        try:
            err_body = resp.json()
            err_msg = err_body.get("error", {}).get("message") or err_body.get("message") or resp.text[:200]
        except Exception:
            err_msg = resp.text[:200]
        return None, f"HTTP {resp.status_code}: {err_msg}"
    except Exception as e:
        return None, str(e)


def main():
    parser = argparse.ArgumentParser(description="Scan Apigee proxies, target servers, and KVM entries")
    parser.add_argument("--project", required=True, help="GCP project ID (also the Apigee org name)")
    parser.add_argument("--output", help="Output Markdown file path (defaults to output/ folder)")
    args = parser.parse_args()

    project = args.project
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    today = datetime.now().strftime("%Y-%m-%d")
    output_path = args.output or os.path.join(OUTPUT_DIR, f"apigee_endpoints_{project}_{today}.md")

    print(f"Fetching access token...")
    token = get_token()

    md_lines = [
        f"# Apigee Proxies and Endpoints — `{project}`",
        "",
        f"**Generated:** {today}",
        "",
        "## Backend KVM Endpoints",
        "",
        "| Environment | KVM Name | Key | Endpoint URL |",
        "|-------------|----------|-----|--------------|",
    ]

    # ── 1. List proxies ──────────────────────────────────────────────
    print(f"\n{'─' * 57}")
    print(f"1. Listing Apigee API Proxies for: {project}")
    print(f"{'─' * 57}")

    proxies_data, err = api_get(token, f"{APIGEE_BASE}/organizations/{project}/apis")
    if proxies_data is None:
        print(f"  [!] Failed to fetch proxies: {err}")
        sys.exit(1)

    proxies = proxies_data if isinstance(proxies_data, list) else proxies_data.get("proxies", [])
    for proxy in proxies:
        name = proxy.get("name", proxy) if isinstance(proxy, dict) else proxy
        print(f"  - {name}")

    # ── 2. List environments ─────────────────────────────────────────
    print("\nFetching environments...")
    envs_data, err = api_get(token, f"{APIGEE_BASE}/organizations/{project}/environments")
    if envs_data is None:
        print(f"  [!] Failed to fetch environments: {err}")
        sys.exit(1)

    envs = envs_data if isinstance(envs_data, list) else []
    if not envs:
        print("  No environments found.")
        sys.exit(0)

    for env in envs:
        if not isinstance(env, str):
            continue
        print(f"\n{'─' * 57}")
        print(f"Environment: {env}")
        print(f"{'─' * 57}")

        # ── Target Servers ───────────────────────────────────────────
        print(">>> Target Servers:")
        ts_data, ts_err = api_get(token, f"{APIGEE_BASE}/organizations/{project}/environments/{env}/targetservers")
        ts_list = ts_data if isinstance(ts_data, list) else []
        if ts_data is None:
            print(f"  [!] Error fetching target servers: {ts_err}")
        if not ts_list:
            print("  None found.")
        else:
            for ts_name in ts_list:
                if not isinstance(ts_name, str):
                    continue
                ts_detail, _ = api_get(token, f"{APIGEE_BASE}/organizations/{project}/environments/{env}/targetservers/{ts_name}")
                if ts_detail:
                    host = ts_detail.get("host", "?")
                    port = ts_detail.get("port", "?")
                    print(f"  - {ts_name} -> {host}:{port}")

        # ── KVMs ─────────────────────────────────────────────────────
        print("\n>>> KVMs (Key Value Maps):")
        kvm_data, kvm_err = api_get(token, f"{APIGEE_BASE}/organizations/{project}/environments/{env}/keyvaluemaps")
        kvm_list = kvm_data if isinstance(kvm_data, list) else []
        if kvm_data is None:
            print(f"  [!] Error fetching KVMs: {kvm_err}")
        if not kvm_list:
            print("  None found.")
        else:
            for kvm_name in kvm_list:
                if not isinstance(kvm_name, str):
                    continue
                print(f"  * KVM: {kvm_name}")
                entries_data, entries_err = api_get(
                    token,
                    f"{APIGEE_BASE}/organizations/{project}/environments/{env}/keyvaluemaps/{kvm_name}/entries"
                )
                if entries_data is None:
                    print(f"    (Could not fetch entries: {entries_err})")
                    continue

                entries = entries_data.get("keyValueEntries", [])
                if not entries:
                    print("    (No entries found or KVM is encrypted)")
                    continue

                for entry in entries:
                    key = entry.get("name", "")
                    val = entry.get("value", "")
                    print(f"    > {key} = {val}")
                    if any(k in key.lower() for k in ("endpoint", "url")) or val.startswith("http"):
                        md_lines.append(f"| {env} | {kvm_name} | {key} | {val} |")

    # ── Write markdown ───────────────────────────────────────────────
    with open(output_path, "w") as f:
        f.write("\n".join(md_lines))

    print(f"\nDone. Results saved to {output_path}")


if __name__ == "__main__":
    main()
