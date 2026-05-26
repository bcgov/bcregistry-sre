# Copilot Instructions — bcregistry-sre

## Project Overview

This is the **BC Registries SRE** infrastructure-as-code and tooling repo. It manages GCP IAM, PAM (Privileged Access Management), database roles, alerting, and operational scripts for the BC Registries service portfolio. It is **not** an application — it's an ops/platform repo.

## Repository Structure

| Path | Purpose |
|------|---------|
| `gcp/terraform/` | Terraform IaC for IAM, PAM, DB roles, alerts across all GCP projects |
| `gcp/scripts/` | Python scanning/reporting scripts (inventory, uptime, Apigee, SRE reports) |
| `gcp/iam/` | Shell scripts for IAM user management and custom role generation |
| `gcp/pam/` | PAM entitlement infra (Cloud Functions + shell generators) |
| `gcp/project_setup/` | GCP project bootstrapping (CloudSQL, alerts, permissions) |
| `gcp/synthetic-monitor/` | Mocha-based synthetic monitoring deployed via Cloud Deploy |
| `downpage/` | Static maintenance page (nginx container, OpenShift + GCP deployable) |
| `images/` | Docker images for CI/CD runners and utilities |

## Terraform Conventions

- **Workspace-per-environment**: workspaces are `dev`, `test`, `prod`, `other`, `mpf`. The `main.tf` selects project configs dynamically based on `terraform.workspace`.
- **Config files**: project definitions live in `_config_project_*.auto.tfvars` files, environment-level roles in `_config_environment_custom_roles.auto.tfvars`.
- **Modules** (`gcp/terraform/modules/`): `iam`, `pam`, `db_roles`, `db_role_assignment`, `db_role_management`, `alert`, `project`.
- **Helper script**: use `./tf.sh plan dev` / `./tf.sh apply prod` / `./tf.sh status` — not raw terraform commands.
- **Backend**: GCS bucket `common-tools-terraform-state`, prefix `iam`.
- **Region**: default `northamerica-northeast1` (Montréal).

## Python Scripts (`gcp/scripts/`)

- Managed with **uv** (see `pyproject.toml`, `uv.lock`). Python ≥ 3.12.
- Run all scans: `uv run --project gcp/scripts gcp/scripts/__main__.py`
- Run a group: `uv run --project gcp/scripts gcp/scripts/__main__.py --only inventory`
- Output goes to `gcp/scripts/output/`.
- Scripts use Google Cloud SDK auth (`google-auth`, `google-cloud-*`) and expect ADC or service account credentials.

## Shell Script Patterns

- IAM scripts (`gcp/iam/`) follow a verb pattern: `add_user.sh`, `remove_user.sh`, `cd.sh`, `sre.sh`.
- Terraform wrapper `tf.sh` handles workspace selection, init, plan, and apply with color output.
- Docker images in `images/` each have a `build.sh` for local builds.

## Key Conventions

1. **No application code** — this repo only contains infrastructure, tooling, and ops automation.
2. **GCP-first** — all cloud resources target GCP (org ID `168766599236`).
3. **Least-privilege IAM** — custom roles are generated from curated permission lists (`gcp/iam/sre-role/`), with explicit exclusion lists.
4. **PAM for elevated access** — temporary privilege grants via PAM entitlements, not permanent role bindings.
5. **Terraform variable structure** — projects are `map(object({...}))` with optional fields using `optional()` types; always provide defaults.
