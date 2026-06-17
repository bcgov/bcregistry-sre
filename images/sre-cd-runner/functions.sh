#!/bin/bash


# Function to check if a Docker tag exists
tag_exists() {
    local tag="$1"
    local image_path="$2"
    local image_package_path="$3"

    if [[ -z "$tag" || -z "$image_path" || -z "$image_package_path" ]]; then
        echo "❌ IMAGE_PATH or IMAGE_PACKAGE_PATH is not set." >&2
        return 1
    fi

    local result
    result=$(gcloud artifacts docker tags list "$image_path" \
        --filter="tag=${image_package_path}/tags/${tag}" \
        --format="value(tag)" 2>/dev/null)
    [[ -n "$result" ]]
}

# Function to get SHA tag associated with an environment tag
tag_sha() {
    local tag="$1"
    local image_path="$2"
    local image_package_path="$3"
    local deploy_envs="$4"

    if [[ -z "${image_path}" || -z "${image_package_path}" || -z "${deploy_envs}" ]]; then
        echo "❌ IMAGE_PATH, IMAGE_PACKAGE_PATH or DEPLOYMENT_ENVS is not set." >&2
        return 1
    fi

    # Get the version corresponding to the given tag
    local version
    version=$(gcloud artifacts docker tags list "${image_path}" \
        --filter="tag=${image_package_path}/tags/${tag}" \
        --format="value(version)" 2>/dev/null)

    # Get sha tag associated with the version, excluding environment tags and latest tag
    gcloud artifacts docker tags list "${image_path}" \
        --filter="version=${image_package_path}/versions/${version} AND -tag:(latest ${deploy_envs})" \
        --format="value(tag)" 2>/dev/null
}

# Function to tag a Docker image
tag_image() {
    local source_tag="$1"
    local target_tag="$2"
    local image_path="$3"

    if [[ -z "${source_tag}" || -z "${target_tag}" || -z "${image_path}" ]]; then
        echo "❌ source_tag, target_tag or IMAGE_PATH is not set." >&2
        return 1
    fi

    echo "🏷️ Tagging image: ${source_tag} → ${target_tag}"
    gcloud artifacts docker tags add "${image_path}:${source_tag}" "${image_path}:${target_tag}" 2>/dev/null
}

# Function to build and push Docker image.
# Optional 5th arg `build_target` selects a specific Dockerfile stage (multi-stage builds).
build_and_push_image() {
    local image_path="$1"
    local image_package_path="$2"
    local short_sha="$3"
    local target_tag="$4"
    local build_target="${5:-}"

    if [[ -z "${short_sha}" || -z "${image_path}" || -z "${image_package_path}" ]]; then
        echo "❌ short_sha, IMAGE_PATH or IMAGE_PACKAGE_PATH is not set." >&2
        return 1
    fi

    if ! tag_exists "${short_sha}" "${image_path}" "${image_package_path}"; then
        echo "🔨 Building and pushing Docker image: ${short_sha}${build_target:+ (target=${build_target})}"
        docker --version
        local -a base_args=(build -t "${image_path}:${short_sha}")
        # Force target platform when DOCKER_BUILD_PLATFORM is set (e.g. linux/amd64
        # when building from Apple Silicon for Cloud Build VMs).
        [[ -n "${DOCKER_BUILD_PLATFORM:-}" ]] && base_args+=(--platform "${DOCKER_BUILD_PLATFORM}")
        [[ -n "${build_target}" ]] && base_args+=(--target "${build_target}")

        # Try with --cache-from when :latest exists in the registry. Some
        # Docker-compatible CLIs (Apple `container`, certain Buildx-only
        # wrappers) reject various --cache-from forms; fall back to a plain
        # build in that case so the runner image can always be built.
        local built=0
        if tag_exists "latest" "${image_path}" "${image_package_path}"; then
            if docker "${base_args[@]}" --cache-from "type=registry,ref=${image_path}:latest" .; then
                built=1
            elif docker "${base_args[@]}" --cache-from "${image_path}:latest" .; then
                built=1
            else
                echo "⚠️  --cache-from not supported by this docker CLI, retrying without cache." >&2
            fi
        fi
        if (( built == 0 )); then
            docker "${base_args[@]}" .
        fi

        docker push "${image_path}:${short_sha}"
        tag_image "${short_sha}" "latest" "${image_path}"
    else
        echo "✅ Image ${image_path}:${short_sha} already exists. Skipping build."
    fi

    # Tag the image with the target tag
    if [[ -n "${target_tag}" && "${short_sha}" != "${target_tag}" ]]; then
        tag_image "${short_sha}" "${target_tag}" "${image_path}"
    fi
}

# Run a fresh build OR promote an image from another environment, including
# prod-tag archival. Mirrors the per-env handling previously inlined in
# cloudbuild.yaml so it can be reused for the main app and any auxiliary images.
build_or_promote_image() {
    local image_path="$1"
    local image_package_path="$2"
    local short_sha="$3"
    local deployment_env="$4"
    local deployment_env_from="$5"
    local build_target="${6:-}"

    if [[ -z "${image_path}" || -z "${image_package_path}" || -z "${short_sha}" || -z "${deployment_env}" ]]; then
        echo "❌ image_path, image_package_path, short_sha or deployment_env is not set." >&2
        return 1
    fi

    # Archive the existing 'prod' tag with a dated alias before retagging.
    if [[ "${deployment_env}" == "prod" ]] && tag_exists "prod" "${image_path}" "${image_package_path}"; then
        tag_image "prod" "prod-$(date +%F)" "${image_path}"
    fi

    if [[ -z "${deployment_env_from}" || "${deployment_env_from}" == "${deployment_env}" ]]; then
        build_and_push_image "${image_path}" "${image_package_path}" "${short_sha}" "${deployment_env}" "${build_target}"
    else
        tag_image "${deployment_env_from}" "${deployment_env}" "${image_path}"
    fi
}

# Detect a multi-stage Dockerfile stage whose name contains 'migration'
# (e.g. `FROM ... AS migration`, `AS db-migration`, `AS migration-runner`).
# Echoes the first matching stage name, or nothing if none / not multi-stage.
detect_migration_stage() {
    local dockerfile="${1:-Dockerfile}"
    [[ -f "${dockerfile}" ]] || return 0

    local from_count
    from_count=$(grep -cE '^[[:space:]]*FROM[[:space:]]' "${dockerfile}" || true)
    (( from_count >= 2 )) || return 0

    # Echo the first matching stage name, or nothing if none. The `|| true`
    # is required because under `set -euo pipefail` a non-matching grep
    # exits 1 and would kill the caller (and the entire build) silently.
    grep -iE '^[[:space:]]*FROM[[:space:]].+[[:space:]]+AS[[:space:]]+[A-Za-z0-9_-]*migration[A-Za-z0-9_-]*' "${dockerfile}" \
        | sed -E 's/.*[[:space:]]+[Aa][Ss][[:space:]]+([A-Za-z0-9_-]+).*/\1/' \
        | head -n1 \
        || true
}

# If the repo's Dockerfile is multi-stage and contains a stage whose name
# contains 'migration', build/promote a parallel image at
# <main-image>-migration following the same fresh-build / promote / prod-archive
# pattern as the main image.
build_and_push_migration_image_if_present() {
    local image_path="$1"
    local image_package_path="$2"
    local short_sha="$3"
    local deployment_env="$4"
    local deployment_env_from="$5"

    local stage
    stage=$(detect_migration_stage "Dockerfile")
    [[ -n "${stage}" ]] || return 0

    local migration_image_path="${image_path}-migration"
    local migration_image_package_path="${image_package_path}-migration"

    echo "🧱 Detected migration stage '${stage}' — building $(basename "${migration_image_path}")"
    build_or_promote_image "${migration_image_path}" "${migration_image_package_path}" \
        "${short_sha}" "${deployment_env}" "${deployment_env_from}" "${stage}"
}

merge_vaults() {
    local origin_env="$1"
    local update_env="$2"
    local output_env="$3"

    declare -A update_values

    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        update_values["$key"]="$value"
    done < <(grep -v '^[[:space:]]*$' "$update_env")

    # Remove surrounding quotes from values
    for key in "${!update_values[@]}"; do
        val="${update_values[$key]}"
        val="${val#\'}"
        val="${val%\'}"
        val="${val#\"}"
        val="${val%\"}"
        update_values["$key"]="$val"
    done

    # Output as YAML format only
    {
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            # Remove surrounding quotes
            value="${value#\'}"
            value="${value%\'}"
            value="${value#\"}"
            value="${value%\"}"

            if [[ -n "${update_values[$key]+_}" ]]; then
                val="${update_values[$key]}"
                unset update_values["$key"]
            else
                val="$value"
            fi
            # Escape for YAML
            val="${val//\\/\\\\}"
            val="${val//\"/\\\"}"
            printf '%s: "%s"\n' "$key" "$val"
        done < <(grep -v '^[[:space:]]*$' "$origin_env")

        for key in "${!update_values[@]}"; do
            val="${update_values[$key]}"
            val="${val//\\/\\\\}"
            val="${val//\"/\\\"}"
            printf '%s: "%s"\n' "$key" "$val"
        done
    } > "$output_env"

    echo "🛠️ Updated values written to $output_env (YAML format)" >&2
}

# Generate secrets file
generate_secrets_file() {
    local env="$1"
    local file_path="$2"

    echo "🔑 Generating secrets for environment: ${env}..."

    # Set environment variable for vault file
    export APP_ENV="${env}"

    # Remove empty lines and comment lines (lines starting with #)
    awk 'NF && $1 !~ /^#/' "${file_path}" > ./devops/vaults.env.tmp
    if ! op inject -f -i ./devops/vaults.env.tmp -o ./devops/vaults."${env}"; then
        echo "❌ Error: Failed to generate secrets via 1Password vault." >&2
        return 1
    fi
    # Remove lines where the value is just a hyphen (e.g., MY_VAR=-)
    sed -i '/^[A-Za-z_][A-Za-z0-9_]*="-"[[:space:]]*$/d' ./devops/vaults."${env}"
}

# Generate manifest for each environment
generate_manifest() {
    local service_type="$1"
    local env_name="$2"
    export APP_ENV="${env_name}"

    if [[ -z "${service_type}" || -z "${env_name}" ]]; then
        echo "❌ service_type or env_name is not set." >&2
        return 1
    fi

    echo "🛠️ Generating ${service_type} manifest for environment: ${env_name}..."

    # Generate secrets base on vault mapping file
    # This file should contain the mapping of secrets to environment variables
    generate_secrets_file "${env_name}" "./devops/vaults.gcp.env"

    # Extract VPC connector and environment variables
    export VPC_CONNECTOR
    VPC_CONNECTOR=$(awk -F= '/^VPC_CONNECTOR/ {print $2}' "./devops/vaults.${env_name}")
    export VAL
    VAL=$(awk '{f1=f2=$0; sub(/=.*/,"",f1); sub(/[^=]+=/,"",f2); printf "- name: %s\n  value: %s\n",f1,f2}' "./devops/vaults.${env_name}")
    export ROUTE_ALL_TO_VPC
    ROUTE_ALL_TO_VPC=$(awk -F= '/^ROUTE_ALL_TO_VPC/ {print $2}' "./devops/vaults.${env_name}")

    local template_file="./devops/gcp/k8s/${service_type}.template.yaml"
    local temp_file="./devops/gcp/k8s/temp-${service_type}.${env_name}.yaml"
    local output_file="./devops/gcp/k8s/${service_type}.${env_name}.yaml"

    cp "${template_file}" "${temp_file}"

    if [[ -n "${VPC_CONNECTOR}" ]]; then
        echo "🌐 Adding VPC connector configuration..."
        if [[ -n "${ROUTE_ALL_TO_VPC}" ]]; then
            echo "Routing all traffic to VPC"
            yq e '.spec.template.metadata.annotations += {"run.googleapis.com/vpc-access-egress": "all-traffic", "run.googleapis.com/vpc-access-connector": env(VPC_CONNECTOR)}' -i "${temp_file}"
        else
            echo "Routing internal traffic to VPC"
            yq e '.spec.template.metadata.annotations += {"run.googleapis.com/vpc-access-egress": "private-ranges-only", "run.googleapis.com/vpc-access-connector": env(VPC_CONNECTOR)}' -i "${temp_file}"
        fi
    fi

    if [[ "${service_type}" == "service" ]]; then
        yq e '.spec.template.spec.containers[0].env += env(VAL)' -i "${temp_file}"
    else
        yq e '.spec.template.spec.template.spec.containers[0].env += env(VAL)' -i "${temp_file}"
    fi

    mv "${temp_file}" "${output_file}"
}

# Remove unused targets from Cloud Deploy manifest
remove_unused_deployments() {
    local -a targets_full=($1)
    local -a targets_current=($2)
    local project_name="$3"

    # Calculate environments to remove
    local -a to_remove
    mapfile -t to_remove < <(comm -23 <(printf "%s\n" "${targets_full[@]}" | sort) <(printf "%s\n" "${targets_current[@]}" | sort))

    for env_name in "${to_remove[@]}"; do
        export TARGET="${project_name}-${env_name}"
        echo "🧹 Removing unused deployment target: ${TARGET}"
        yq e 'del(.serialPipeline.stages[] | select(.targetId == env(TARGET)))' -i "./devops/gcp/clouddeploy.yaml"
    done
}