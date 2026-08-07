#!/bin/bash

# Default projects array - can be overridden with SCAN_PROJECTS env var
DEFAULT_PROJECTS=("a083gt" "bcrbk9" "c4hnrd" "eogruh" "gtksf3" "yfjq17" "yfthig" "k973yf" "p0q6jr" "keee67" "mvnjri" "sbgmug" "okagqp")

# Check if SCAN_PROJECTS is set, if so use it instead of the defaults
if [[ ! -z "${SCAN_PROJECTS}" ]]; then
    # Read from environment variable (comma-separated list)
    IFS=',' read -ra projects <<< "${SCAN_PROJECTS}"
    echo "Using projects from SCAN_PROJECTS environment variable"
else
    # Use the default projects
    projects=("${DEFAULT_PROJECTS[@]}")
fi

# Default environments array - can be overridden with SCAN_ENVIRONMENTS env var
DEFAULT_ENVIRONMENTS=("dev" "test" "tools" "prod" "integration" "sandbox")

# Check if SCAN_ENVIRONMENTS is set, if so use it instead of the defaults
if [[ ! -z "${SCAN_ENVIRONMENTS}" ]]; then
    # Read from environment variable (comma-separated list)
    IFS=',' read -ra environments <<< "${SCAN_ENVIRONMENTS}"
    echo "Using environments from SCAN_ENVIRONMENTS environment variable"
else
    # Use the default environments
    environments=("${DEFAULT_ENVIRONMENTS[@]}")
fi

# Create files to store results
TEMP_DIR=$(mktemp -d)
COMPLIANT_FILE="${TEMP_DIR}/compliant.txt"
ERRORS_FILE="${TEMP_DIR}/errors.txt"
touch "$COMPLIANT_FILE"
touch "$ERRORS_FILE"

SERVICE_ACCOUNT="sa-compliance-scanner@c4hnrd-tools.iam.gserviceaccount.com"
ROLE="roles/viewer"

# Environment variable to control whether to grant IAM permissions
# Set GRANT_VIEWER_ROLE=true to enable IAM permission granting
GRANT_IAM=${GRANT_VIEWER_ROLE:-false}

# Environment variable to control whether to save reports to Google Cloud Storage
# Set SAVE_TO_GCS=true and REPORT_BUCKET to enable GCS report storage
SAVE_TO_GCS=${SAVE_TO_GCS:-false}
REPORT_BUCKET=${REPORT_BUCKET:-""}

echo "Debug: SAVE_TO_GCS=${SAVE_TO_GCS}"
echo "Debug: REPORT_BUCKET=${REPORT_BUCKET:-"(not set)"}"

echo "==============================================="
echo "GCP Canadian Resource Scanner"
echo "==============================================="
echo "Configuration:"
echo "  - Projects to scan: ${#projects[@]}"
echo "  - Environments to scan: ${#environments[@]}"
if [[ "$GRANT_IAM" == "true" ]]; then
    echo "  - IAM Permission Granting: ENABLED"
    echo "    Service Account: $SERVICE_ACCOUNT"
    echo "    Role: $ROLE"
else
    echo "  - Resource Scanning: ENABLED"
    echo "    (Set GRANT_VIEWER_ROLE=true to switch to IAM granting mode)"
    echo "  - Include Empty Subnets: ${INCLUDE_EMPTY_DEFAULT_SUBNETS:-false}"
fi
echo "==============================================="
echo ""

# Calculate total projects for progress tracking
total_projects=$(( ${#environments[@]} * ${#projects[@]} ))
current_project=0

for ev in "${environments[@]}"
do
    for ns in "${projects[@]}"
    do
        PROJECT_ID=$ns-$ev
        current_project=$((current_project + 1))
        echo "Project: $PROJECT_ID [$current_project/$total_projects]"

        # Quick check if project exists before proceeding
        if ! gcloud projects describe ${PROJECT_ID} --verbosity=none >/dev/null 2>&1; then
            echo "  ⚠️  Project $PROJECT_ID does not exist or is not accessible, skipping..."
            continue
        fi

        gcloud config set project ${PROJECT_ID} --quiet

            # Either grant IAM permissions OR scan resources based on environment variable
            if [[ "$GRANT_IAM" == "true" ]]; then
                echo "Granting $ROLE role to $SERVICE_ACCOUNT on project $PROJECT_ID..."
                if gcloud projects add-iam-policy-binding ${PROJECT_ID} \
                    --member="serviceAccount:${SERVICE_ACCOUNT}" \
                    --role="${ROLE}" \
                    --quiet > /dev/null 2>&1; then
                    echo "  ✓ Successfully granted $ROLE to $SERVICE_ACCOUNT on project $PROJECT_ID"
                else
                    echo "  ⚠️  Failed to grant $ROLE to $SERVICE_ACCOUNT on project $PROJECT_ID"
                fi
            else
                  # IAM user compliance check
                  BAD=$(gcloud projects get-iam-policy "$PROJECT_ID" \
                    --format="value(bindings.members)" | \
                    tr ',;' '\n' | tr -d "[]' " | \
                    grep -E "^user:" | \
                    grep -vE "@gov\.bc\.ca$" | \
                    sort -u)

                  if [[ -n "$BAD" ]]; then
                      while read -r u; do
                          echo "$PROJECT_ID|$u" >> "$ERRORS_FILE"
                      done <<< "$BAD"
                  else
                      echo "$PROJECT_ID|IAM: OK" >> "$COMPLIANT_FILE"
                  fi

            fi  # End of if GRANT_IAM/else (scan resources) block
    done
done


if [[ "$GRANT_IAM" != "true" ]]; then
    # Display summary
    echo "=========================================="
    echo "SUMMARY REPORT"
    echo "=========================================="

    # Display compliant resources
    if [[ -s "$COMPLIANT_FILE" ]]; then
        echo ""
        echo "✅ PROJECTS WITH ONLY APPROVED ENTRA USERS:"
        echo "------------------------------------"
        # Process compliant resources by project
        current_project=""
        sort "$COMPLIANT_FILE" | while IFS="|" read -r project resource; do
            if [[ "$project" != "$current_project" ]]; then
                # Print newline between projects except for the first one
                if [[ -n "$current_project" ]]; then
                    echo ""
                fi
                echo "Project: $project"
                current_project="$project"
            fi
            echo "  ✓ $resource"
        done
        echo ""
    fi
    # Display errors
    if [[ -s "$ERRORS_FILE" ]]; then
        echo ""
        echo "🚨 PROJECTS WITH NON-ENTRA USERS:"
        echo "----------------------------------------"

        # Process error resources by project
        current_project=""
        sort "$ERRORS_FILE" | while IFS="|" read -r project resource; do
            if [[ "$project" != "$current_project" ]]; then
                # Print newline between projects except for the first one
                if [[ -n "$current_project" ]]; then
                    echo ""
                fi
                echo "Project: $project"
                current_project="$project"
            fi
            echo "  - $resource"
        done
        echo ""
    else
        echo ""
        echo "✅ NO NON-CANADIAN RESOURCES FOUND!"
    fi

    echo "=========================================="

    if [[ "${SAVE_TO_GCS:-false}" == "true" && -n "${REPORT_BUCKET}" ]]; then
        echo ""
        echo "Saving compliance reports to Google Cloud Storage..."

        TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
        ERRORS_REPORT="non-entra-users-${TIMESTAMP}.csv"
        ERRORS_CSV="${TEMP_DIR}/${ERRORS_REPORT}"

        if [[ -s "$ERRORS_FILE" ]]; then
            {
                echo "Project,User"
                while IFS='|' read -r project user; do
                    echo "\"$project\",\"$user\""
                done < <(sort -u "$ERRORS_FILE")
            } > "$ERRORS_CSV"

            if gcloud storage cp "$ERRORS_CSV" "gs://${REPORT_BUCKET}/${ERRORS_REPORT}" 2>/dev/null; then
                echo "  ✓ Non-ENTRA users report uploaded: gs://${REPORT_BUCKET}/${ERRORS_REPORT}"
            else
                echo "  ⚠️ Failed to upload Non-ENTRA users report"
            fi
        else
            echo "No Non-ENTRA users found - nothing to save to GCS"
        fi
    elif [[ "${SAVE_TO_GCS:-false}" == "true" && -z "${REPORT_BUCKET}" ]]; then
        echo ""
        echo "⚠️ GCS reporting enabled but REPORT_BUCKET not specified"
    fi

fi

# Exit with error code if Non-ENTRA users were found (for GCP alerting)
if [[ "$GRANT_IAM" != "true" && -s "$ERRORS_FILE" ]]; then
    echo ""
    echo "🚨 EXITING WITH ERROR CODE 1 - Non-ENTRA users detected"
    echo "This will trigger GCP Cloud Run job failure for alerting purposes"

    # Clean up temp directory
    rm -rf "$TEMP_DIR"

    exit 1
fi

# Clean up temp directory
rm -rf "$TEMP_DIR"
