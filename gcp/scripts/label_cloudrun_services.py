# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "google-cloud-run",
#     "google-auth"
# ]
# ///
"""
Add a label to all Cloud Run services across one or more GCP projects.

Usage:
    uv run label_cloudrun_services.py --projects c4hnrd-dev --label product=common
    uv run label_cloudrun_services.py --projects a083gt-prod,c4hnrd-prod --label product=common --region northamerica-northeast1
"""

import argparse
import google.auth
from google.cloud import run_v2


def label_services(project_id: str, region: str, label_key: str, label_value: str, client: run_v2.ServicesClient):
    parent = f"projects/{project_id}/locations/{region}"
    print(f"\n{'━' * 47}")
    print(f"Project: {project_id}")
    print(f"{'━' * 47}")

    services = list(client.list_services(parent=parent))
    if not services:
        print("  No Cloud Run services found.")
        return

    for service in services:
        svc_name = service.name.split("/")[-1]
        print(f"  🏷️  Adding label [{label_key}={label_value}] to: {svc_name}")

        # Merge existing labels with the new one
        updated_labels = dict(service.labels)
        updated_labels[label_key] = label_value

        service.labels.clear()
        service.labels.update(updated_labels)

        update_mask = {"paths": ["labels"]}
        request = run_v2.UpdateServiceRequest(service=service, update_mask=update_mask)
        try:
            operation = client.update_service(request=request)
            operation.result()  # Wait for completion
            print(f"  ✅ Done: {svc_name}")
        except Exception as e:
            print(f"  ❌ Failed to update {svc_name}: {e}")


def main():
    parser = argparse.ArgumentParser(description="Add a label to Cloud Run services across GCP projects")
    parser.add_argument("--projects", required=True, help="Comma-separated list of project IDs (e.g. c4hnrd-dev,a083gt-prod)")
    parser.add_argument("--label", required=True, help="Label to apply in key=value format (e.g. product=common)")
    parser.add_argument("--region", default="northamerica-northeast1", help="Cloud Run region")
    args = parser.parse_args()

    if "=" not in args.label:
        print("Error: --label must be in key=value format.")
        raise SystemExit(1)
    label_key, label_value = args.label.split("=", 1)

    projects = [p.strip() for p in args.projects.split(",")]

    credentials, _ = google.auth.default()
    client = run_v2.ServicesClient(credentials=credentials)

    for project_id in projects:
        label_services(project_id, args.region, label_key, label_value, client)

    print("\nDone.")


if __name__ == "__main__":
    main()
