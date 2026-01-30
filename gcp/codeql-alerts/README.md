# CodeQL Alert Fetcher Cloud Function

This Google Cloud Function fetches open CodeQL alerts (Critical and High severity) from GitHub repositories with a specific topic (default: `bcregistry`) and uploads the results to a Google Cloud Storage bucket.

It also leverages Google Cloud Logging to trigger alerts via Log-based Alert Policies when Critical issues are found.

## Features

- **GitHub API Integration**: Uses `requests` to fetch open alerts directly from GitHub.
- **Configurable**: Topic, output bucket, and auth token are configurable via Environment Variables.
- **Structured Logging**: Logs findings as structured JSON, enabling easy filtering and alerting in GCP.
- **GCS Archiving**: Saves full JSON reports to GCS with timestamps.

## Prerequisites

1. **Google Cloud Storage Bucket**: A bucket to store the JSON reports.
2. **GitHub Personal Access Token (PAT)**:
    - Scopes: `repo`, `read:org`, `security_events` (if required for private repos).
    - Store this token in **Google Secret Manager**.

## Configuration

The function uses the following Environment Variables:

| Variable | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `CODEQL_GITHUB_TOKEN` | GitHub PAT for API authentication. Should be a Secret Env Var. | - | Yes |
| `CODEQL_GCS_BUCKET_NAME` | Name of the GCS bucket to upload results to. | - | No (Upload skipped if missing) |
| `CODEQL_GITHUB_TOPIC` | GitHub topic to filter repositories by. | `bcregistry` | No |

## Deployment

Deploy using `gcloud`. Replace placeholders with your actual values.

```bash
gcloud functions deploy codeql-alert \
  --runtime python310 \
  --trigger-http \
  --entry-point main \
  --source . \
  --region northamerica-northeast1  \
  --set-env-vars CODEQL_GCS_BUCKET_NAME=your-gcs-bucket-name,CODEQL_GITHUB_TOPIC=bcregistry \
  --set-secrets CODEQL_GITHUB_TOKEN=projects/YOUR_PROJECT_ID/secrets/github-token/versions/latest
```

## Scheduling (Cloud Scheduler)

To run the function on a schedule (e.g., weekly at Sunday 6 AM):

**Create Job**:

    ```bash
    gcloud scheduler jobs create http codeql-weekly-scan \
      --schedule="0 6 * * 7" \
      --uri="https://northamerica-northeast1 -YOUR_PROJECT_ID.cloudfunctions.net/codeql-alert" \
      --http-method=GET \
      --oidc-service-account-email="codeql-scheduler-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
      --location=northamerica-northeast1 
    ```

## Alerting (Log-based)

To receive email/Slack notifications for Critical alerts:

1. Go to **Logging** > **Logs Explorer**.
2. Query: `jsonPayload.severity="CRITICAL" AND jsonPayload.component="codeql-alert-fetcher"`
3. Click **Create Alert**.
4. Configure the alert to notify your desired **Notification Channel**.
