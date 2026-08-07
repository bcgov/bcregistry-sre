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

# Environment variable to control whether to include empty default subnets in compliance checks
# Set INCLUDE_EMPTY_DEFAULT_SUBNETS=true to include them (creates more noise but is more thorough)
INCLUDE_EMPTY_DEFAULT_SUBNETS=${INCLUDE_EMPTY_DEFAULT_SUBNETS:-false}

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
                # Resource scanning logic
                echo "Checking databases, backups, storage, compute, artifact registry, and network resources in project: ${PROJECT_ID}"
                echo "  Note: Multi-regional storage within Canada (CA region) is considered compliant"

                # Use Cloud Asset Inventory to get all relevant resources and their locations
                echo "  Scanning all database, backup, storage, compute, and network resources using Asset Inventory..."

                # Define asset types to check for databases, backups, storage, compute, and network
                target_asset_types=(
                    # Database services
                    "sqladmin.googleapis.com/Instance"
                    "firestore.googleapis.com/Database"
                    "bigtableadmin.googleapis.com/Instance"
                    "spanner.googleapis.com/Instance"
                    "redis.googleapis.com/Instance"
                    "bigquery.googleapis.com/Dataset"

                    # Backup/Archive storage (where backup data is actually stored)
                    "sqladmin.googleapis.com/BackupRun"
                    "storage.googleapis.com/Bucket"
                    "compute.googleapis.com/Snapshot"
                    "file.googleapis.com/Backup"

                    # Storage services (excluding buckets - handled separately)
                    "file.googleapis.com/Instance"
                    "compute.googleapis.com/Disk"
                    "compute.googleapis.com/Snapshot"
                    "compute.googleapis.com/Image"
                    "artifactregistry.googleapis.com/Repository"

                    # Compute services
                    "run.googleapis.com/Service"
                    "run.googleapis.com/Job"

                    # Network services
                    "compute.googleapis.com/Network"
                    "compute.googleapis.com/Subnetwork"
                    "compute.googleapis.com/Address"
                    "compute.googleapis.com/GlobalAddress"
                    "compute.googleapis.com/Router"
                    "compute.googleapis.com/VpnGateway"
                    "compute.googleapis.com/VpnTunnel"
                    "compute.googleapis.com/Interconnect"
                    "compute.googleapis.com/InterconnectAttachment"
                    "dns.googleapis.com/ManagedZone"
                    "servicenetworking.googleapis.com/Connection"
                )

                # Get all resources with their types and locations (increased timeout for large projects)
                all_resources=$(timeout 180 gcloud asset search-all-resources --project=${PROJECT_ID} --format="csv[no-heading](assetType,location,name)" 2>/dev/null)

                # Cache compute instances data to avoid repeated API calls
                echo "  Caching compute instances data..."
                instances_cache=$(timeout 20 gcloud compute instances list --project="$PROJECT_ID" --format="csv[no-heading](name,zone,networkInterfaces[0].subnetwork)" 2>/dev/null)

                # Special check for ALL Cloud Storage buckets (both multi-regional and regional)
                echo "  Checking for Cloud Storage buckets..."
                buckets=$(timeout 20 gcloud storage ls --project=${PROJECT_ID} 2>/dev/null)

                if [[ ! -z "$buckets" ]]; then
                    while read -r bucket; do
                        # Skip empty lines
                        [[ -z "$bucket" ]] && continue

                        # Extract bucket name first
                        bucket_name=$(basename "$bucket")
                        bucket_name=${bucket_name%/}

                        # Get bucket location information with reduced timeout
                        bucket_info=$(timeout 10 gcloud storage buckets describe "$bucket" --format="value(location,locationType)" 2>/dev/null)
                        location_constraint=$(echo "$bucket_info" | awk '{print $1}')
                        location_type=$(echo "$bucket_info" | awk '{print $2}')
                        # Fallback: if location info is empty (describe failed/no access)
                        if [[ -z "$location_constraint" && -z "$location_type" ]]; then
                            # For Cloud Deploy and similar service buckets, they're often in us-central1
                            if [[ "$bucket_name" == *"_clouddeploy"* ]] || [[ "$bucket_name" == *"gcf-"* ]]; then
                                echo "    Debug: Service bucket detected, likely us-central1: $bucket_name"
                                location_constraint="us-central1"
                                location_type="regional"
                            else
                                echo "    Warning: Unable to determine location for bucket: $bucket_name"
                            fi
                        fi

                        # Determine bucket type and location
                        is_multi_regional=false
                        bucket_location=""

                        if [[ "$location_type" == "multi-regional" ]]; then
                            is_multi_regional=true
                            bucket_location="$location_constraint"
                        elif [[ "$location_constraint" == "US" ]] || [[ "$location_constraint" == "EU" ]] || [[ "$location_constraint" == "ASIA" ]]; then
                            is_multi_regional=true
                            bucket_location="$location_constraint"
                        else
                            # This is a regional bucket
                            is_multi_regional=false
                            bucket_location="$location_constraint"
                        fi

                        # Check if bucket is in Canadian location
                        canadian_bucket=false
                        if [[ "$bucket_location" == "CA" ]] ||
                           [[ "$bucket_location" == "NORTHAMERICA-NORTHEAST1" ]] ||
                           [[ "$bucket_location" == "NORTHAMERICA-NORTHEAST2" ]] ||
                           [[ "$bucket_location" == "northamerica-northeast1" ]] ||
                           [[ "$bucket_location" == "northamerica-northeast2" ]]; then
                            canadian_bucket=true
                        fi

                        # Report based on bucket type and location
                        if [[ "$is_multi_regional" == "true" ]]; then
                            if [[ "$canadian_bucket" == "true" ]]; then
                                echo "    ✓ Multi-Regional Cloud Storage Bucket '$bucket_name' is in Canadian region: $bucket_location"
                                echo "$PROJECT_ID|Multi-Regional Cloud Storage: $bucket_name ($bucket_location)" >> "$COMPLIANT_FILE"
                            else
                                echo "    ⚠️  Multi-Regional Cloud Storage Bucket '$bucket_name' is NOT in Canadian region: $bucket_location"
                                echo "$PROJECT_ID|Multi-Regional Cloud Storage: $bucket_name ($bucket_location)" >> "$ERRORS_FILE"
                            fi
                        else
                            # Regional bucket
                            if [[ "$canadian_bucket" == "true" ]]; then
                                echo "    ✓ Regional Cloud Storage Bucket '$bucket_name' is in Canadian region: $bucket_location"
                                echo "$PROJECT_ID|Regional Cloud Storage: $bucket_name ($bucket_location)" >> "$COMPLIANT_FILE"
                            else
                                echo "    ⚠️  Regional Cloud Storage Bucket '$bucket_name' is NOT in Canadian region: $bucket_location"
                                echo "$PROJECT_ID|Regional Cloud Storage: $bucket_name ($bucket_location)" >> "$ERRORS_FILE"
                            fi
                        fi
                    done <<< "$buckets"
                fi

                # Special check for Cloud Composer environments
                echo "  Checking for Cloud Composer environments..."
                if timeout 10 gcloud services list --enabled --filter="name:composer.googleapis.com" --project=${PROJECT_ID} --format="value(name)" 2>/dev/null | grep -q "composer.googleapis.com"; then
                    # Check Canadian regions individually since --locations=all is not supported
                    canadian_regions=("northamerica-northeast1" "northamerica-northeast2")
                    composer_found=false

                    for region in "${canadian_regions[@]}"; do
                        composer_list=$(timeout 20 gcloud composer environments list --locations="$region" --project=${PROJECT_ID} --format="csv[no-heading](name,location,state)" 2>/dev/null)

                        if [[ ! -z "$composer_list" ]]; then
                            while IFS=',' read -r composer_name composer_location composer_state; do
                                # Skip empty lines
                                [[ -z "$composer_name" ]] && continue
                                composer_found=true

                                # Extract environment name from full path if needed
                                env_name=$(basename "$composer_name")

                                # Use region if location is empty (common with CSV output)
                                if [[ -z "$composer_location" ]]; then
                                    composer_location="$region"
                                fi

                                echo "    ✓ Cloud Composer Environment '$env_name' is in Canadian region: $composer_location"
                                echo "$PROJECT_ID|Cloud Composer: $env_name ($composer_location)" >> "$COMPLIANT_FILE"
                            done <<< "$composer_list"
                        fi
                    done

                    # Also check for environments in non-Canadian regions (common ones)
                    non_canadian_regions=("us-central1" "us-east1" "us-west1" "europe-west1" "asia-east1")
                    for region in "${non_canadian_regions[@]}"; do
                        composer_list=$(timeout 20 gcloud composer environments list --locations="$region" --project=${PROJECT_ID} --format="csv[no-heading](name,location,state)" 2>/dev/null)

                        if [[ ! -z "$composer_list" ]]; then
                            while IFS=',' read -r composer_name composer_location composer_state; do
                                # Skip empty lines
                                [[ -z "$composer_name" ]] && continue
                                composer_found=true

                                # Extract environment name from full path if needed
                                env_name=$(basename "$composer_name")

                                # Use region if location is empty
                                if [[ -z "$composer_location" ]]; then
                                    composer_location="$region"
                                fi

                                echo "    ⚠️  Cloud Composer Environment '$env_name' is NOT in Canadian region: $composer_location"
                                echo "$PROJECT_ID|Cloud Composer: $env_name ($composer_location)" >> "$ERRORS_FILE"
                            done <<< "$composer_list"
                        fi
                    done
                    if [[ "$composer_found" == "false" ]]; then
                        echo "    No Cloud Composer environments found in checked regions"
                    fi
                else
                    echo "    Cloud Composer API not enabled for this project"
                fi

                # Special check for Artifact Registry repositories
                echo "  Checking for Artifact Registry repositories..."
                # Check if Artifact Registry API is enabled (with faster timeout and early exit)
                if timeout 10 gcloud services list --enabled --filter="name:artifactregistry.googleapis.com" --project=${PROJECT_ID} --format="value(name)" 2>/dev/null | grep -q "artifactregistry.googleapis.com"; then
                    # Get a better formatted output that includes all details we need
                    # Use format with 'description' to get more accurate location info
                    artifact_repos=$(timeout 20 gcloud artifacts repositories list --project=${PROJECT_ID} --format="csv[no-heading](name,format,location,description)" 2>/dev/null)

                    if [[ ! -z "$artifact_repos" ]]; then
                        while IFS=',' read -r repo_name repo_format repo_location repo_description; do
                            # Skip empty lines
                            [[ -z "$repo_name" ]] && continue

                            # Extract just the repository name from the full path
                            repo_name=$(basename "$repo_name")

                            # Extract location from the full repository path if location field is empty
                            if [[ -z "$repo_location" ]]; then
                                # The repo_name from CSV might still contain the full path, extract location from it
                                # Format: projects/PROJECT/locations/LOCATION/repositories/REPO_NAME
                                original_repo_path="$repo_name"
                                if [[ "$original_repo_path" == *"/locations/"* ]]; then
                                    repo_location=$(echo "$original_repo_path" | grep -o 'locations/[^/]*' | cut -d'/' -f2)
                                    echo "    Info: Extracted location '$repo_location' from repository path"
                                fi
                                repo_name=$(basename "$original_repo_path")
                            fi

                            # Debug output to see what we're getting
                            echo "    Debug: Artifact Registry raw data - name: '$repo_name', format: '$repo_format', location: '$repo_location', description: '$repo_description'"

                            # Check if the location is empty but the description contains location info
                            if [[ -z "$repo_location" && "$repo_description" == *"northamerica-northeast"* ]]; then
                                if [[ "$repo_description" == *"northamerica-northeast1"* ]]; then
                                    repo_location="northamerica-northeast1"
                                    echo "    Info: Empty location field, but description indicates repo '$repo_name' is in $repo_location (Montreal)"
                                elif [[ "$repo_description" == *"northamerica-northeast2"* ]]; then
                                    repo_location="northamerica-northeast2"
                                    echo "    Info: Empty location field, but description indicates repo '$repo_name' is in $repo_location (Toronto)"
                                fi
                            # Use a more accurate method for location resolution
                            elif [[ -z "$repo_location" ]]; then
                                # Try to get location directly from repository resource
                                repo_location=$(timeout 10 gcloud artifacts repositories describe "$repo_name" --project=${PROJECT_ID} --format="value(name)" --quiet 2>/dev/null | sed -n 's|.*/locations/\([^/]*\)/.*|\1|p')

                                if [[ ! -z "$repo_location" ]]; then
                                    echo "    Info: Retrieved location '$repo_location' for repo '$repo_name' from describe command"
                                else
                                    # If that fails, try getting it from the full list with better formatting
                                    repo_location=$(timeout 10 gcloud artifacts repositories list --project=${PROJECT_ID} --format="table[no-heading](name.segment(-1),name.segment(-3))" --filter="name.segment(-1):$repo_name" --quiet 2>/dev/null | awk '{print $2}' | head -1)

                                    if [[ ! -z "$repo_location" ]]; then
                                        echo "    Info: Retrieved location '$repo_location' for repo '$repo_name' from list command"
                                    else
                                        echo "    Warning: Unable to determine location for repository '$repo_name' - marking as non-Canadian for safety"
                                        repo_location="unknown-non-canadian"
                                    fi
                                fi
                            fi

                            # Debug the Canadian region check
                            echo "    Debug: Final repo_location for '$repo_name': '$repo_location'"
                            echo "    Debug: Checking if '$repo_location' matches Canadian region patterns..."

                            # Check if location is Canadian - use simple string contains checks for robustness
                            if [[ "$repo_location" == *"northamerica-northeast1"* ]] ||
                               [[ "$repo_location" == *"northamerica-northeast2"* ]] ||
                               [[ "$repo_location" == *"montreal"* ]] ||
                               [[ "$repo_location" == *"Montreal"* ]] ||
                               [[ "$repo_location" == *"montréal"* ]] ||
                               [[ "$repo_location" == *"Montréal"* ]] ||
                               [[ "$repo_location" == *"toronto"* ]] ||
                               [[ "$repo_location" == *"Toronto"* ]] ||
                               [[ "$repo_location" == "ca" ]] ||
                               [[ "$repo_location" == "CA" ]]; then
                                echo "    ✓ Artifact Registry '$repo_name' ($repo_format) is in Canadian region: $repo_location"
                                echo "$PROJECT_ID|Artifact Registry|$repo_name|$repo_format|$repo_location" >> "$COMPLIANT_FILE"
                            else
                                echo "    ⚠️  Artifact Registry '$repo_name' ($repo_format) is NOT in Canadian region: $repo_location"
                                echo "    Debug: repo_location='$repo_location' did not match any Canadian patterns"
                                echo "$PROJECT_ID|Artifact Registry|$repo_name|$repo_format|$repo_location" >> "$ERRORS_FILE"
                            fi
                        done <<< "$artifact_repos"
                    else
                        echo "    No Artifact Registry repositories found"
                    fi
                else
                    echo "    Artifact Registry API not enabled for this project"
                fi

                if [[ ! -z "$all_resources" ]]; then
                    while IFS=',' read -r asset_type location resource_name; do
                        # Check if this is a target resource type
                        for target_type in "${target_asset_types[@]}"; do
                            if [[ "$asset_type" == "$target_type" ]]; then
                                # Skip services already handled separately
                                if [[ "$asset_type" == "artifactregistry.googleapis.com/Repository" ]] ||
                                   [[ "$asset_type" == "storage.googleapis.com/Bucket" ]]; then
                                    continue 2
                                fi

                                # Clean up resource name (remove project path prefix)
                                clean_name=$(basename "$resource_name")
                                display_location=""

                                # Determine service category and type for display
                                case "$asset_type" in
                                    # Database services
                                    "sqladmin.googleapis.com/Instance")
                                        service_name="Cloud SQL"
                                        category="Database"
                                        ;;
                                    "firestore.googleapis.com/Database")
                                        service_name="Firestore"
                                        category="Database"
                                        ;;
                                    "bigtableadmin.googleapis.com/Instance")
                                        service_name="Bigtable"
                                        category="Database"
                                        ;;
                                    "spanner.googleapis.com/Instance")
                                        service_name="Spanner"
                                        category="Database"
                                        ;;
                                    "redis.googleapis.com/Instance")
                                        service_name="Redis"
                                        category="Database"
                                        ;;
                                    "bigquery.googleapis.com/Dataset")
                                        service_name="BigQuery"
                                        category="Database"
                                        ;;

                                    # Backup/Archive storage
                                    "sqladmin.googleapis.com/BackupRun")
                                        service_name="Cloud SQL Backup"
                                        category="Backup"
                                        ;;
                                    "compute.googleapis.com/Snapshot")
                                        service_name="Disk Snapshot"
                                        category="Backup"
                                        ;;
                                    "file.googleapis.com/Backup")
                                        service_name="Filestore Backup"
                                        category="Backup"
                                        ;;

                                    # Other storage services
                                    "file.googleapis.com/Instance")
                                        service_name="Filestore"
                                        category="Storage"
                                        ;;
                                    "compute.googleapis.com/Disk")
                                        service_name="Persistent Disk"
                                        category="Storage"
                                        ;;
                                    "compute.googleapis.com/Image")
                                        service_name="Compute Image"
                                        category="Storage"
                                        ;;
                                    "artifactregistry.googleapis.com/Repository")
                                        service_name="Artifact Registry"
                                        category="Storage"
                                        ;;

                                    # Compute services
                                    "run.googleapis.com/Service")
                                        service_name="Cloud Run Service"
                                        category="Compute"
                                        ;;
                                    "run.googleapis.com/Job")
                                        service_name="Cloud Run Job"
                                        category="Compute"
                                        ;;

                                                                        # Network services
                                    "compute.googleapis.com/Network")
                                        # VPC networks are global resources - focus on actual usage, not potential
                                        if [[ "$clean_name" == "default" ]]; then
                                            # For default VPC, check if it has actual resources in non-Canadian regions
                                            if [[ "${INCLUDE_EMPTY_DEFAULT_SUBNETS:-false}" != "true" ]]; then
                                                # Use cached instances data instead of making new API call
                                                non_canadian_instances=0
                                                non_canadian_custom_subnet_instances=0
                                                total_instances=0
                                                while IFS=',' read -r instance_name zone subnet_path; do
                                                    if [[ ! -z "$instance_name" ]]; then
                                                        total_instances=$((total_instances + 1))

                                                        # Check if instance is in non-Canadian zone
                                                        if [[ "$zone" != *"northamerica-northeast"* ]]; then
                                                            non_canadian_instances=$((non_canadian_instances + 1))

                                                            # Check if it's using a custom subnet (not default subnet name pattern)
                                                            subnet_name=$(basename "$subnet_path")
                                                            if [[ "$subnet_name" != "default" ]]; then
                                                                non_canadian_custom_subnet_instances=$((non_canadian_custom_subnet_instances + 1))
                                                            fi
                                                        fi
                                                    fi
                                                done <<< "$instances_cache"

                                                if [[ $non_canadian_custom_subnet_instances -gt 0 ]]; then
                                                    service_name="VPC Network (default, $non_canadian_custom_subnet_instances instances in custom non-Canadian subnets)"
                                                    category="Network"
                                                    display_location="Global (with non-Canadian resources in custom subnets)"
                                                elif [[ $non_canadian_instances -gt 0 ]]; then
                                                    # Only instances in default subnets outside Canada
                                                    default_subnet_instances=$((non_canadian_instances - non_canadian_custom_subnet_instances))
                                                    if [[ "${INCLUDE_EMPTY_DEFAULT_SUBNETS:-false}" == "true" ]]; then
                                                        service_name="VPC Network (default, $default_subnet_instances instances in default non-Canadian subnets)"
                                                        category="Network"
                                                        display_location="Global (with resources in default non-Canadian subnets)"
                                                    else
                                                        # Skip if only default subnet usage
                                                        echo "    ℹ️  Skipping default VPC network '$clean_name' - only has instances in default non-Canadian subnets (set INCLUDE_EMPTY_DEFAULT_SUBNETS=true to include)"
                                                        continue 2
                                                    fi
                                                else
                                                    if [[ $total_instances -gt 0 ]]; then
                                                        # VPC with only Canadian instances - this is compliant
                                                        service_name="VPC Network (default, $total_instances Canadian instances only)"
                                                        category="Network"
                                                        display_location="Global (Canadian resources only)"
                                                    else
                                                        # Skip VPC with no instances (no risk)
                                                        echo "    ℹ️  Skipping default VPC network '$clean_name' - no compute instances deployed (set INCLUDE_EMPTY_DEFAULT_SUBNETS=true to include)"
                                                        continue 2
                                                    fi
                                                fi
                                            else
                                                # Include all default VPCs regardless of usage
                                                total_instances=$(echo "$instances_cache" | grep -c '^[^,]*,[^,]*,[^,]*' 2>/dev/null || echo "0")
                                                service_name="VPC Network (default, $total_instances total instances)"
                                                category="Network"
                                                display_location="Global"
                                            fi
                                        else
                                            # Custom VPC networks - check their actual usage from cached data
                                            # More precise matching: look for instances whose subnet path contains this VPC name
                                            # Format: instance_name,zone,projects/PROJECT/regions/REGION/subnetworks/SUBNET
                                            vpc_instances=""
                                            non_canadian_instances=0
                                            total_instances=0
                                            while IFS=',' read -r instance_name zone subnet_path; do
                                                if [[ ! -z "$instance_name" && "$subnet_path" == *"$clean_name"* ]]; then
                                                    vpc_instances="${vpc_instances}${instance_name},${zone},${subnet_path}\n"
                                                    total_instances=$((total_instances + 1))

                                                    # Check if instance is in non-Canadian zone
                                                    if [[ "$zone" != *"northamerica-northeast"* ]]; then
                                                        non_canadian_instances=$((non_canadian_instances + 1))
                                                    fi
                                                fi
                                            done <<< "$instances_cache"

                                            if [[ $non_canadian_instances -gt 0 ]]; then
                                                service_name="VPC Network (custom, $non_canadian_instances non-Canadian instances)"
                                                category="Network"
                                                display_location="Global (with non-Canadian resources)"
                                            else
                                                if [[ $total_instances -gt 0 ]]; then
                                                    # VPC with only Canadian instances - this is compliant
                                                    service_name="VPC Network (custom, $total_instances Canadian instances only)"
                                                    category="Network"
                                                    display_location="Global (Canadian resources only)"
                                                else
                                                    # Skip unused custom VPCs
                                                    echo "    ℹ️  Skipping custom VPC network '$clean_name' - no compute instances deployed"
                                                    continue 2
                                                fi
                                            fi
                                        fi
                                        ;;
                                    "compute.googleapis.com/Address")
                                        # For global static IPs, check if they're associated with Canadian resources
                                        if [[ "$location" == "global" ]]; then
                                            # Get detailed static IP information to check for Canadian associations
                                            static_ip_details=$(timeout 10 gcloud compute addresses describe "$clean_name" --global --project="$PROJECT_ID" --format="value(users[0],subnetwork,region)" 2>/dev/null)
                                            if [[ ! -z "$static_ip_details" ]]; then
                                                # Check if the static IP is associated with Canadian resources
                                                IFS=$'\t' read -r user_resource subnetwork region <<< "$static_ip_details"

                                                canadian_association=false

                                                # Check if associated with Canadian region
                                                if [[ "$region" == *"northamerica-northeast"* ]]; then
                                                    canadian_association=true
                                                fi

                                                # Check if associated with Canadian subnetwork
                                                if [[ "$subnetwork" == *"northamerica-northeast"* ]]; then
                                                    canadian_association=true
                                                fi

                                                # Check if the user resource (like load balancer) is in Canadian region
                                                if [[ "$user_resource" == *"northamerica-northeast"* ]]; then
                                                    canadian_association=true
                                                fi

                                                if [[ "$canadian_association" == "true" ]]; then
                                                    echo "    ✓ Global Static IP '$clean_name' is associated with Canadian resources"
                                                    service_name="Global Static IP (Canadian association)"
                                                    category="Network"
                                                else
                                                    echo "    ℹ️  Skipping Global Static IP '$clean_name' - no Canadian resource associations found"
                                                    continue 2
                                                fi
                                            else
                                                echo "    ℹ️  Skipping Global Static IP '$clean_name' - unable to determine associations (may be unused)"
                                                continue 2
                                            fi
                                        else
                                            # For regional static IPs, check if they're external addresses
                                            # Internal/private IPs don't have data residency implications
                                            region_name=$(echo "$location" | sed 's/.*regions\///;s/\/addresses.*//')
                                            if [[ -z "$region_name" ]]; then
                                                region_name="$location"
                                            fi
                                            
                                            # Get address details to check if it's external
                                            address_details=$(timeout 10 gcloud compute addresses describe "$clean_name" --region="$region_name" --project="$PROJECT_ID" --format="value(addressType)" 2>/dev/null)
                                            
                                            if [[ "$address_details" == "EXTERNAL" ]]; then
                                                service_name="Static IP"
                                                category="Network"
                                            else
                                                # Skip internal/private IP addresses
                                                echo "    ℹ️  Skipping Internal Static IP '$clean_name' - internal addresses don't affect data residency"
                                                continue 2
                                            fi
                                            category="Network"
                                        fi
                                        ;;
                                    "compute.googleapis.com/GlobalAddress")
                                        # Skip global addresses - they're routing resources, not data storage
                                        echo "    ℹ️  Skipping Global IP '$clean_name' - global routing resource (no data residency impact)"
                                        continue 2
                                        ;;
                                    "servicenetworking.googleapis.com/Connection")
                                        # Skip service network connections - they're control plane resources
                                        if [[ "$location" == "global" ]]; then
                                            echo "    ℹ️  Skipping Service Network Connection '$clean_name' - global control plane resource (no data residency impact)"
                                            continue 2
                                        fi
                                        service_name="Service Network Connection"
                                        category="Network"
                                        ;;
                                    "compute.googleapis.com/Subnetwork")
                                        # Check if this is a default subnet and if it's being used
                                        if [[ "$location" != "northamerica-northeast1" && "$location" != "northamerica-northeast2" && "$location" != "ca" && "$location" != "CA" ]]; then
                                            # For non-Canadian subnets, check if they have any instances (unless configured to include all)
                                            if [[ "${INCLUDE_EMPTY_DEFAULT_SUBNETS:-false}" != "true" ]]; then
                                                # Use cached data to count instances in this subnet
                                                instances_in_subnet=$(echo "$instances_cache" | grep -F "$resource_name" | wc -l)
                                                if [[ $instances_in_subnet -gt 0 ]]; then
                                                    service_name="Subnet (with $instances_in_subnet instances)"
                                                    category="Network"
                                                else
                                                    # Skip empty subnets to reduce noise
                                                    echo "    ℹ️  Skipping empty subnet '$clean_name' in non-Canadian region: $location (set INCLUDE_EMPTY_DEFAULT_SUBNETS=true to include)"
                                                    continue 2
                                                fi
                                            else
                                                service_name="Subnet"
                                                category="Network"
                                            fi
                                        else
                                            service_name="Subnet"
                                            category="Network"
                                        fi
                                        ;;
                                    "compute.googleapis.com/GlobalAddress")
                                        service_name="Global IP"
                                        category="Network"
                                        ;;
                                    "compute.googleapis.com/Router")
                                        service_name="Cloud Router"
                                        category="Network"
                                        ;;
                                    "compute.googleapis.com/VpnGateway")
                                        service_name="VPN Gateway"
                                        category="Network"
                                        ;;
                                    "compute.googleapis.com/VpnTunnel")
                                        service_name="VPN Tunnel"
                                        category="Network"
                                        ;;
                                    "compute.googleapis.com/Interconnect")
                                        service_name="Interconnect"
                                        category="Network"
                                        ;;
                                    "compute.googleapis.com/InterconnectAttachment")
                                        service_name="Interconnect Attachment"
                                        category="Network"
                                        ;;
                                    "dns.googleapis.com/ManagedZone")
                                        # Skip DNS zones - they are global control plane resources with no data residency impact
                                        # DNS zones only contain configuration data, not user data subject to residency requirements
                                        echo "    ℹ️  Skipping Cloud DNS zone '$clean_name' - global control plane resource (no data residency impact)"
                                        continue 2
                                        ;;
                                    "servicenetworking.googleapis.com/Connection")
                                        service_name="Service Network Connection"
                                        category="Network"
                                        ;;
                                    *)
                                        service_name="Resource"
                                        category="Other"
                                        ;;
                                esac

                                # Check if location is Canadian
                                if [[ $location == northamerica-northeast1* ]] ||
                                   [[ $location == northamerica-northeast2* ]] ||
                                   [[ $location == "northamerica-northeast1" ]] ||
                                   [[ $location == "northamerica-northeast2" ]] ||
                                   [[ $location == "ca" ]] ||
                                   [[ $location == "CA" ]]; then
                                    echo "    ✓ $service_name '$clean_name' is in Canadian region: $location"
                                    echo "$PROJECT_ID|$service_name: $clean_name ($location)" >> "$COMPLIANT_FILE"
                                else
                                    # Handle empty/null locations and common non-Canadian ones
                                    final_display_location="${display_location:-$location}"
                                    if [[ -z "$final_display_location" ]]; then
                                        final_display_location="Unknown/Global"
                                    fi

                                    # Special handling for VPC networks
                                    if [[ "$asset_type" == "compute.googleapis.com/Network" ]]; then
                                        if [[ "$display_location" == "Global (with non-Canadian resources)" ]] ||
                                           [[ "$display_location" == "Global (with non-Canadian resources in custom subnets)" ]] ||
                                           [[ "$display_location" == "Global (with resources in default non-Canadian subnets)" ]]; then
                                            echo "    ⚠️  $service_name '$clean_name': $final_display_location"
                                            echo "$PROJECT_ID|$service_name: $clean_name ($final_display_location)" >> "$ERRORS_FILE"
                                        else
                                            # VPC networks with only Canadian resources or no resources are compliant
                                            echo "    ✓ $service_name '$clean_name': $final_display_location"
                                            echo "$PROJECT_ID|$service_name: $clean_name ($final_display_location)" >> "$COMPLIANT_FILE"
                                        fi
                                    # Special handling for Global Static IPs with Canadian associations
                                    elif [[ "$asset_type" == "compute.googleapis.com/Address" && "$location" == "global" && "$service_name" == "Global Static IP (Canadian association)" ]]; then
                                        echo "    ✓ $service_name '$clean_name': $final_display_location"
                                        echo "$PROJECT_ID|$service_name: $clean_name ($final_display_location)" >> "$COMPLIANT_FILE"
                                    # Skip certain global network resources that don't impact data residency
                                    elif [[ "$asset_type" == "compute.googleapis.com/GlobalAddress" ]] ||
                                         [[ "$asset_type" == "servicenetworking.googleapis.com/Connection" && "$location" == "global" ]]; then
                                        # These were already skipped above with continue 2
                                        continue 2
                                    else
                                        echo "    ⚠️  $service_name '$clean_name' is NOT in Canadian region: $final_display_location"
                                        echo "$PROJECT_ID|$service_name: $clean_name ($final_display_location)" >> "$ERRORS_FILE"
                                    fi
                                fi
                                break
                            fi
                        done
                    done <<< "$all_resources"
                else
                    echo "    No target resources found or Asset Inventory API not accessible"
                fi

                echo ""
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
        echo "✅ PROJECTS WITH CANADIAN RESOURCES:"
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
        echo "🚨 PROJECTS WITH NON-CANADIAN RESOURCES:"
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

    # Save reports to Google Cloud Storage if enabled
    if [[ "${SAVE_TO_GCS:-false}" == "true" && ! -z "${REPORT_BUCKET}" ]]; then
        echo ""
        echo "Saving compliance reports to Google Cloud Storage..."
        
        # Generate timestamp for unique filenames
        TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
        ERRORS_REPORT="non-compliant-resources_${TIMESTAMP}.csv"
        
        # Upload non-compliant resources if any exist  
        if [[ -s "$ERRORS_FILE" ]]; then
            # Use the existing CSV generation logic for errors
            ERRORS_CSV="${TEMP_DIR}/${ERRORS_REPORT}"
            {
                echo "Project,Resource Type,Resource Name,Location"
                while IFS='|' read -r project resource_field1 resource_field2 resource_field3 resource_field4; do
                    # Handle Artifact Registry format which has more fields
                    if [[ "$resource_field1" == "Artifact Registry" ]]; then
                        # Fields are: project|Artifact Registry|name|format|location
                        echo "\"$project\",\"$resource_field1\",\"$resource_field2\",\"$resource_field4\""
                    else
                        # Handle standard format: project|Type: name (location)
                        resource_type=$(echo "$resource_field1" | cut -d ':' -f1)
                        details=$(echo "$resource_field1" | cut -d ':' -f2-)
                        resource_name=$(echo "$details" | sed -E 's/^[ ]*(.*) \((.*)\)$/\1/')
                        resource_location=$(echo "$details" | sed -E 's/^[ ]*(.*) \((.*)\)$/\2/')
                        echo "\"$project\",\"$resource_type\",\"$resource_name\",\"$resource_location\""
                    fi
                done < "$ERRORS_FILE"
            } > "$ERRORS_CSV"
            
            if gcloud storage cp "$ERRORS_CSV" "gs://${REPORT_BUCKET}/${ERRORS_REPORT}" 2>/dev/null; then
                echo "  ✓ Non-compliant resources report uploaded: gs://${REPORT_BUCKET}/${ERRORS_REPORT}"
                echo "Non-compliant resources saved to bucket: gs://${REPORT_BUCKET}/"
            else
                echo "  ⚠️  Failed to upload non-compliant resources report"
            fi
        else
            echo "No non-compliant resources found - nothing to save to GCS"
        fi
    elif [[ "${SAVE_TO_GCS:-false}" == "true" && -z "${REPORT_BUCKET}" ]]; then
        echo ""
        echo "⚠️  GCS reporting enabled but REPORT_BUCKET not specified"
    fi
fi

# Exit with error code if non-compliant resources were found (for GCP alerting)
if [[ "$GRANT_IAM" != "true" && -s "$ERRORS_FILE" ]]; then
    echo ""
    echo "🚨 EXITING WITH ERROR CODE 1 - Non-compliant resources detected"
    echo "This will trigger GCP Cloud Run job failure for alerting purposes"

    # Clean up temp directory
    rm -rf "$TEMP_DIR"

    exit 1
fi

# Clean up temp directory
rm -rf "$TEMP_DIR"
