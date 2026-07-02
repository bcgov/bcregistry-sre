#!/bin/bash


# Returns success when the argument is a recognized truthy token used by
# opt-in vault flags: true / yes / 1 / on (case-insensitive). Anything else,
# including empty/unset, is treated as falsey. Kept portable (tr + case) so it
# works under the macOS bash 3.2 used for local builds.
_is_truthy() {
    case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
        true | yes | 1 | on) return 0 ;;
        *) return 1 ;;
    esac
}

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
# When invoked for a main image (no build_target), it also builds a parallel
# <image>-migration image if the Dockerfile exposes a 'migration' stage.
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

    # When building a main image (no explicit build_target), also build a
    # parallel <image>-migration image if the Dockerfile exposes a 'migration'
    # stage. The build_target guard prevents infinite recursion: the migration
    # build re-enters this function with a non-empty target and is skipped here.
    if [[ -z "${build_target}" ]]; then
        build_and_push_migration_image_if_present "${image_path}" "${image_package_path}" \
            "${short_sha}" "${deployment_env}" "${deployment_env_from}"
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

    # Extract VPC settings and container environment variables.
    # ROUTE_ALL_TO_VPC selects the Serverless VPC Access connector (all egress
    # routed to the VPC); otherwise the revision uses Direct VPC egress to
    # SUBNETWORK (+ optional NETWORK / NETWORK_TAGS), private ranges only.
    export VPC_CONNECTOR SUBNETWORK NETWORK NETWORK_TAGS ROUTE_ALL_TO_VPC CLOUD_SQL_PROXY_SIDECAR VAL
    # Read KEY=value from the vault file, stripping surrounding whitespace and
    # quotes. Vault files often quote values (e.g. CLOUD_SQL_PROXY_SIDECAR="yes"),
    # and the raw quotes would otherwise break equality checks and annotations.
    _vault_value() {
        awk -F= -v k="$1" '$1==k{sub(/^[^=]*=/,""); print}' "$2" \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
                  -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/"
    }
    ROUTE_ALL_TO_VPC=$(_vault_value "ROUTE_ALL_TO_VPC" "./devops/vaults.${env_name}")
    VPC_CONNECTOR=$(_vault_value "VPC_CONNECTOR" "./devops/vaults.${env_name}")
    CLOUD_SQL_PROXY_SIDECAR=$(_vault_value "CLOUD_SQL_PROXY_SIDECAR" "./devops/vaults.${env_name}")
    NETWORK=$(op read -n "op://CD/${env_name}/base/EGRESS_NETWORK" 2>/dev/null || true)
    SUBNETWORK=$(op read -n "op://CD/${env_name}/base/EGRESS_SUBNETWORK" 2>/dev/null || true)
    NETWORK_TAGS=$(op read -n "op://CD/${env_name}/base/EGRESS_NETWORK_TAGS" 2>/dev/null || true)

    VAL=$(awk '{f1=f2=$0; sub(/=.*/,"",f1); sub(/[^=]+=/,"",f2); printf "- name: %s\n  value: %s\n",f1,f2}' "./devops/vaults.${env_name}")

    local template_file="./devops/gcp/k8s/${service_type}.template.yaml"
    local temp_file="./devops/gcp/k8s/temp-${service_type}.${env_name}.yaml"
    local output_file="./devops/gcp/k8s/${service_type}.${env_name}.yaml"

    cp "${template_file}" "${temp_file}"

    # Debug: surface the resolved VPC / egress / sidecar inputs so this step is
    # visible in the build log even when none of the branches below fire.
    # (VAL is intentionally not printed as it may contain secret env values.)
    # Network identifiers (connector/network/subnetwork/tags) come from the
    # vault, so report presence only ("set"/"<empty>") rather than the literal
    # topology values. The plain flags below are non-sensitive yes/empty toggles.
    _present() { if [[ -n "${1:-}" ]]; then echo "set"; else echo "<empty>"; fi; }
    echo "🔎 Manifest inputs for ${service_type}/${env_name}:"
    echo "    ROUTE_ALL_TO_VPC=${ROUTE_ALL_TO_VPC:-<empty>}"
    echo "    VPC_CONNECTOR=$(_present "${VPC_CONNECTOR}")"
    echo "    NETWORK=$(_present "${NETWORK}")"
    echo "    SUBNETWORK=$(_present "${SUBNETWORK}")"
    echo "    NETWORK_TAGS=$(_present "${NETWORK_TAGS}")"
    echo "    CLOUD_SQL_PROXY_SIDECAR=${CLOUD_SQL_PROXY_SIDECAR:-<empty>}"

    # Configure VPC egress for Cloud Run.
    # When ROUTE_ALL_TO_VPC is set, route all egress through the Serverless VPC
    # Access connector. Otherwise attach the revision directly to a subnetwork
    # via Direct VPC egress (run.googleapis.com/network-interfaces).
    if _is_truthy "${ROUTE_ALL_TO_VPC}"; then
        # Route all traffic through the legacy Serverless VPC Access connector.
        echo "🔌 VPC connector (all-traffic) → $(_present "${VPC_CONNECTOR}")"
        export EGRESS_MODE="all-traffic" VPC_CONNECTOR
        yq e '.spec.template.metadata.annotations += {"run.googleapis.com/vpc-access-egress": strenv(EGRESS_MODE), "run.googleapis.com/vpc-access-connector": strenv(VPC_CONNECTOR)}' -i "${temp_file}"
        # Drop any stale Direct VPC egress annotation so the two modes never coexist.
        yq e 'del(.spec.template.metadata.annotations."run.googleapis.com/network-interfaces")' -i "${temp_file}"
    elif [[ -n "${SUBNETWORK}" ]]; then
        # Direct VPC egress: build the network-interfaces JSON (network and
        # tags are optional) and store it as a string annotation.
        export NETWORK_INTERFACES
        NETWORK_INTERFACES=$(NETWORK="${NETWORK}" SUBNETWORK="${SUBNETWORK}" NETWORK_TAGS="${NETWORK_TAGS}" yq -n -o=json -I=0 \
            '({"network": strenv(NETWORK), "subnetwork": strenv(SUBNETWORK)} | with_entries(select(.value != ""))) as $base | (strenv(NETWORK_TAGS) | select(. != "") | {"tags": (split(",") | map(sub("^ +| +$"; "")))}) as $tags | [ $base * ($tags // {}) ]')
        echo "🌐 Direct VPC egress (private-ranges-only) → subnetwork: $(_present "${SUBNETWORK}")${NETWORK:+, network: set}"
        export EGRESS_MODE="private-ranges-only"
        yq e '.spec.template.metadata.annotations += {"run.googleapis.com/vpc-access-egress": strenv(EGRESS_MODE), "run.googleapis.com/network-interfaces": strenv(NETWORK_INTERFACES)}' -i "${temp_file}"
        # Drop any stale connector annotation so the two modes never coexist.
        yq e 'del(.spec.template.metadata.annotations."run.googleapis.com/vpc-access-connector")' -i "${temp_file}"
    else
        echo "🚫 No VPC egress configured (ROUTE_ALL_TO_VPC and SUBNETWORK are empty)."
    fi

    echo "🧩 Injecting environment variables into ${service_type} container[0]..."
    if [[ "${service_type}" == "service" ]]; then
        yq e '.spec.template.spec.containers[0].env += env(VAL)' -i "${temp_file}"
    else
        yq e '.spec.template.spec.template.spec.containers[0].env += env(VAL)' -i "${temp_file}"
    fi

    # The Cloud SQL Auth Proxy sidecar is defined directly in the service
    # template. Keep it only when the service opts in with a truthy
    # CLOUD_SQL_PROXY_SIDECAR value (true/yes/1/on, case-insensitive; set in
    # ./devops/vaults.${env_name}); otherwise strip it from the manifest.
    # Its instance connection name comes from the ${cloudsql-instances} Cloud
    # Deploy parameter, so it stays correct across environments.
    if _is_truthy "${CLOUD_SQL_PROXY_SIDECAR:-}"; then
        echo "🛞️ Keeping Cloud SQL Auth Proxy sidecar."
    elif [[ "${service_type}" == "service" ]]; then
        echo "🧹 Removing Cloud SQL Auth Proxy sidecar (CLOUD_SQL_PROXY_SIDECAR not truthy)."
        yq e 'del(.spec.template.spec.containers[] | select(.name == "cloud-sql-proxy"))' -i "${temp_file}"
    else
        echo "🧹 Removing Cloud SQL Auth Proxy sidecar (CLOUD_SQL_PROXY_SIDECAR not truthy)."
        yq e 'del(.spec.template.spec.template.spec.containers[] | select(.name == "cloud-sql-proxy"))' -i "${temp_file}"
    fi

    mv "${temp_file}" "${output_file}"
    echo "✅ Wrote ${service_type} manifest: ${output_file}"
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