# GCP Canadian Resource Scanner

A tool to scan Google Cloud Platform resources across projects and verify if they are deployed in Canadian regions.

## Overview

This script scans GCP resources for data residency compliance, checking if databases, storage, backups, and network resources are located in Canadian regions (northamerica-northeast1, northamerica-northeast2, or the Canadian multi-region).

## Features

- Scans multiple projects and environments
- Checks databases (Cloud SQL, Firestore, Bigtable, Spanner, Redis, BigQuery)
- Verifies storage locations (Cloud Storage, including multi-regional buckets)
- Checks backups (Cloud SQL backups, disk snapshots, etc.)
- Examines compute resources (Cloud Run services and jobs)
- Examines network resources
- Checks Artifact Registry repositories
- Saves non-compliant resources to Google Cloud Storage (optional)
- Exits with error code for alerting when violations are found
- Generates a summary report of compliant and non-compliant resources

## Usage

### Resource Scanning Mode (Default)

To scan resources for Canadian region compliance:

```bash
./run.sh
```

### IAM Permission Granting Mode

To grant the Viewer role to the service account defined in the script:

```bash
GRANT_VIEWER_ROLE=true ./run.sh
```

### Report Storage

The script can save non-compliant resources to a Google Cloud Storage bucket for historical tracking and analysis:

```bash
# Enable GCS report storage - only saves non-compliant resources
SAVE_TO_GCS=true REPORT_BUCKET=my-compliance-reports ./run.sh
```

When enabled, this creates timestamped CSV files containing only resources that violate Canadian data residency requirements.

### Alerting and Monitoring

The script is designed to work with GCP alerting systems:

- **Exit Code 0**: All resources are compliant (success)
- **Exit Code 1**: Non-compliant resources detected (failure)

When run as a GCP Cloud Run job, you can set up alerts based on job failure to be notified when compliance violations are found.

You can create a `.env` file in the project root with these variables:

```
# GCS report storage - only saves non-compliant resources
SAVE_TO_GCS=false
REPORT_BUCKET=my-compliance-reports-bucket

# Scan configuration (comma-separated lists)
SCAN_PROJECTS=a083gt,bcrbk9,c4hnrd
SCAN_ENVIRONMENTS=dev,test,prod

# IAM permission granting
GRANT_VIEWER_ROLE=false
```

Then source it before running the script:
```bash
set -a && source .env && set +a && ./run.sh
```


## Requirements

- Google Cloud SDK (`gcloud`, including the `gcloud storage` component)
- Appropriate permissions to scan resources and grant IAM roles

## Notes

- Multi-regional storage within Canada (CA region) is considered compliant
- The script uses the Cloud Asset Inventory API for efficient scanning

## Building and Deploying with Docker

### Configure GCP Artifact Registry

```bash
# Configure Docker to use GCP Artifact Registry
gcloud auth configure-docker northamerica-northeast1-docker.pkg.dev

# Build the image
docker build -t northamerica-northeast1-docker.pkg.dev/c4hnrd-dev/job-repo/compliance-checker:latest .

# Push to Artifact Registry
docker push northamerica-northeast1-docker.pkg.dev/c4hnrd-dev/job-repo/compliance-checker:latest
```
