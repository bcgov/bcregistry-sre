import os
import json
import time
import requests
import logging
from datetime import datetime
from google.cloud import storage

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class MaxRetriesExceededError(Exception):
    """Exception raised when max retries are exceeded."""

    pass


def log_structured(message, severity="INFO", payload=None):
    """Log a structured JSON message for Google Cloud Logging."""
    entry = {
        "severity": severity,
        "message": message,
        "component": "codeql-alert-fetcher",
    }
    if payload:
        entry.update(payload)
    print(json.dumps(entry))  # Print to stdout is captured by Cloud Logging


def make_github_request(url, headers, params=None, max_retries=5):
    """Make a GitHub API request with rate limit handling."""
    retries = 0
    while retries < max_retries:
        response = requests.get(url, headers=headers, params=params)

        if response.status_code in [200, 404]:
            return response

        if response.status_code in [403, 429]:
            # Check for rate limit headers
            retry_after = response.headers.get("Retry-After")
            reset_time = response.headers.get("x-ratelimit-reset")
            remaining = response.headers.get("x-ratelimit-remaining")

            wait_time = 0

            if retry_after:
                wait_time = int(retry_after)
            elif reset_time and remaining and int(remaining) == 0:
                # Only wait for reset if we actually ran out of quota
                wait_time = max(int(reset_time) - int(time.time()), 1)
            else:
                # Secondary rate limit (Abuse Detection) with no headers
                # Use exponential backoff: 60s, 120s, 240s, 480s...
                wait_time = 60 * (2**retries)

            log_structured(
                f"Rate limit hit (Status: {response.status_code}, Remaining: {remaining}). Waiting {wait_time} seconds before retry {retries + 1}/{max_retries}.",
                severity="WARNING",
            )
            time.sleep(wait_time + 1)  # Add buffer
            retries += 1
            continue

        # Other errors
        return response

    log_structured(
        f"Max retries exceeded for URL: {url}. Aborting process.", severity="CRITICAL"
    )
    raise MaxRetriesExceededError(f"Max retries exceeded for URL: {url}")


def check_and_log_rate_limit(github_token):
    """Check and log the current GitHub Rate Limit."""
    url = "https://api.github.com/rate_limit"
    headers = {
        "Authorization": f"Bearer {github_token}",
        "Accept": "application/vnd.github.v3+json",
    }
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            core = data.get("resources", {}).get("core", {})
            remaining = core.get("remaining")
            limit = core.get("limit")
            reset_ts = core.get("reset")
            reset_time = (
                datetime.fromtimestamp(reset_ts).strftime("%Y-%m-%d %H:%M:%S")
                if reset_ts
                else "Unknown"
            )

            log_structured(
                f"GitHub Rate Limit Status: {remaining}/{limit} remaining. Resets at {reset_time}",
                severity="INFO",
            )
        else:
            log_structured(
                f"Failed to check rate limit: {response.text}", severity="WARNING"
            )
    except Exception as e:
        log_structured(f"Error checking rate limit: {str(e)}", severity="ERROR")


def get_repos_by_topic(topic, github_token):
    """Search for repositories with a specific topic using GitHub API."""
    url = "https://api.github.com/search/repositories"
    headers = {
        "Authorization": f"Bearer {github_token}",
        "Accept": "application/vnd.github.v3+json",
    }
    params = {"q": f"topic:{topic}", "per_page": 100}

    repos = []
    page = 1

    while True:
        params["page"] = page
        response = make_github_request(url, headers=headers, params=params)

        if response.status_code != 200:
            log_structured(
                f"Failed to search repos: {response.text}",
                severity="ERROR",
            )
            return []

        data = response.json()
        items = data.get("items", [])
        if not items:
            break

        repos.extend(items)
        # Check for pagination (incomplete check but sufficient for < 1000 repos)
        if len(repos) >= data.get("total_count", 0):
            break
        page += 1

        # Throttling to avoid secondary rate limits
        time.sleep(1)

    # Cooldown after search
    time.sleep(5)

    return repos


def get_all_open_alerts(repo_full_name, github_token):
    """Fetch all open CodeQL alerts for a repository."""
    url = f"https://api.github.com/repos/{repo_full_name}/code-scanning/alerts"
    headers = {
        "Authorization": f"Bearer {github_token}",
        "Accept": "application/vnd.github.v3+json",
    }
    params = {"tool_name": "CodeQL", "state": "open", "per_page": 100}

    all_alerts = []
    page = 1

    while True:
        # Throttling for pagination
        time.sleep(1)
        params["page"] = page
        response = make_github_request(url, headers=headers, params=params)

        if response.status_code == 404:
            # Code scanning might not be enabled
            return []
        if response.status_code != 200:
            log_structured(
                f"Error fetching alerts for {repo_full_name}: {response.text}",
                severity="WARNING",
            )
            return []

        data = response.json()
        if not data:
            break

        all_alerts.extend(data)
        if len(data) < 100:
            break
        page += 1

    return all_alerts


def get_alert_details(alert, repo_full_name, repo_html_url):
    """Extract relevant details from an alert."""
    return {
        "repository": repo_full_name,
        "repo_url": repo_html_url,
        "alert_number": alert.get("number"),
        "html_url": alert.get("html_url"),
        "state": alert.get("state"),
        "created_at": alert.get("created_at"),
        "rule_id": alert.get("rule", {}).get("id"),
        "rule_description": alert.get("rule", {}).get("description"),
        "severity": alert.get("rule", {}).get("security_severity_level"),
        "original_severity": alert.get("rule", {}).get("severity"),
        "message": alert.get("most_recent_instance", {}).get("message", {}).get("text"),
    }


def upload_to_gcs(bucket_name, filename, data):
    """Upload data to Google Cloud Storage. Handles gs:// prefix and subdirectories."""
    try:
        # Normalize bucket name
        if bucket_name.startswith("gs://"):
            bucket_name = bucket_name[5:]

        # Split bucket and prefix if exists
        prefix = ""
        if "/" in bucket_name:
            parts = bucket_name.split("/", 1)
            bucket_name = parts[0]
            prefix = parts[1]
            if prefix and not prefix.endswith("/"):
                prefix += "/"

        full_filename = f"{prefix}{filename}"

        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(full_filename)
        blob.upload_from_string(
            json.dumps(data, indent=2), content_type="application/json"
        )
        log_structured(f"Uploaded {full_filename} to {bucket_name}", severity="INFO")
        return True
    except Exception as e:
        log_structured(f"Failed to upload to GCS: {str(e)}", severity="ERROR")
        return False


def main(request):
    """Cloud Function entry point."""
    # Getting configuration from Environment Variables
    github_token = os.environ.get("CODEQL_GITHUB_TOKEN")
    bucket_name = os.environ.get("CODEQL_GCS_BUCKET_NAME")
    topic = os.environ.get("CODEQL_GITHUB_TOPIC", "bcregistry")

    if not github_token:
        log_structured(
            "CODEQL_GITHUB_TOKEN environment variable is not set", severity="ERROR"
        )
        return "Internal Server Error: Missing Configuration", 500

    log_structured(f"Starting CodeQL alert fetch for topic: {topic}", severity="INFO")
    check_and_log_rate_limit(github_token)

    repos = get_repos_by_topic(topic, github_token)
    log_structured(f"Found {len(repos)} repositories", severity="INFO")

    critical_findings = []
    high_findings = []

    for repo in repos:
        full_name = repo["full_name"]
        html_url = repo["html_url"]

        # Throttling to avoid secondary rate limits
        time.sleep(2)

        alerts = get_all_open_alerts(full_name, github_token)

        if alerts:
            for alert in alerts:
                rule = alert.get("rule", {})
                sec_severity = rule.get("security_severity_level")

                details = get_alert_details(alert, full_name, html_url)

                if sec_severity == "critical":
                    critical_findings.append(details)
                elif sec_severity == "high":
                    high_findings.append(details)

    log_structured(
        f"Processing complete. Critical: {len(critical_findings)}, High: {len(high_findings)}",
        severity="INFO",
    )

    # Alerting via Logging
    if len(critical_findings) > 0:
        log_structured(
            f"Found {len(critical_findings)} CRITICAL CodeQL alerts!",
            severity="CRITICAL",
            payload={
                "alert_count": len(critical_findings),
                "findings": critical_findings[:10],
            },  # Limit payload size
        )

    if not bucket_name:
        log_structured("GCS_BUCKET_NAME not set, skipping upload", severity="WARNING")
        return json.dumps(
            {
                "status": "success",
                "critical_count": len(critical_findings),
                "high_count": len(high_findings),
                "message": "Processed successfully, but no bucket configured.",
            }
        ), 200

    # Upload results
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    upload_to_gcs(bucket_name, f"codeql_critical_{timestamp}.json", critical_findings)
    upload_to_gcs(bucket_name, f"codeql_high_{timestamp}.json", high_findings)

    # Also overwrite 'latest' files for easy access
    upload_to_gcs(bucket_name, "codeql_critical_latest.json", critical_findings)
    upload_to_gcs(bucket_name, "codeql_high_latest.json", high_findings)

    return json.dumps(
        {
            "status": "success",
            "critical_count": len(critical_findings),
            "high_count": len(high_findings),
            "bucket": bucket_name,
        }
    ), 200
