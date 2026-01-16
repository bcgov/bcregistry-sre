# Updating Terraform Configuration for Google Cloud's Custom Roles and Service Accounts

## Prerequisites
Before updating Terraform configuration, ensure you have the following:

- A working Terraform setup (`terraform` CLI installed - make sure you install 64-bit version of Terraform binary)
- Access to the repository where the Terraform configuration is stored
- Check that your account can impersonate terraform service account: 
```
gcloud iam service-accounts get-iam-policy terraform-sa@c4hnrd-tools.iam.gserviceaccount.com \
  --format="json"
```

## Steps to Update Terraform Configuration

1. Clone the Repository
2. Create a New Branch
3. Modify Terraform Configuration in `.tfvars` files

### Configuration Files

There are six configuration files that can be modified:

- `_config_project_dev.auto.tfvars` - For dev environment project configurations
- `_config_project_test.auto.tfvars` - For test environment project configurations
- `_config_project_prod.auto.tfvars` - For prod environment project configurations
- `_config_project_other.auto.tfvars` - For sandbox and tools project configurations
- `_config_environment_custom_roles.auto.tfvars` - For environment-specific custom roles
- `_config_global_custom_roles.auto.tfvars` - For global custom roles across all projects

### Structure of Project Configuration files (`_config_project_*.auto.tfvars`):

All project configuration files define projects using the following structure:

```
dev_projects or test_projects or prod_projects or other_projects = {
  "project-name" = {
    project_id       = ...  # Unique ID for the project
    env              = ...  # Environment (e.g., dev, test, prod, sandbox, tools)

    service_accounts = {    # Map of service accounts, where each account has
      sa-name = {
        roles         = []  # List of IAM roles assigned to the service account
        description   = ""  # Description of the service account

        external_roles = [{ # Optional list of roles in other projects
          roles           = [] # List of roles granted on an external project
          project_id      = "" # Project where the roles are granted
        }]

        resource_roles = [{ # Optional list of resource specific roles
          resource        = "" # Specific resource URI (e.g., bucket, topic)
          roles           = [] # List of roles assigned to the resource
          resource_type   = "" # Type of resource (e.g., storage_bucket, pubsub_topic)
        }]
      }
    }

    custom_roles     = {    # Optional map of custom roles in the project
      role-name = {
        title         = ""  # Name of the custom IAM role
        description   = ""  # Description of the custom role
        permissions   = []  # List of permissions assigned to the role
      }
    }

    pam_bindings     = [    # Optional list of PAM entitlements
      {
        role         = ""   # Custom role name in the entitlement
        principals   = []   # List of principals that can be granted the role
        role_type    = ""   # Optional value, when set to 'custom' ensures custom role URI is properly generated
      }
    ]

    instances        = [    # Optional list of CloudSQL instances
      {
        instance     = ""   # Instance name
        databases    = [    # List of databases
          {
            db_name    = ""  # Database name
            roles      = []  # List of created custom roles to be managed by Terraform, e.g. ["readonly", "readwrite", "admin"]
            owner      = ""  # Database owner/role creator
            agent      = ""  # Optional database agent user
            database_role_assignment = {  # Map of custom role assignments
              readonly   = []  # List of users/service accounts to be granted readonly role
              readwrite  = []  # List of users/service accounts to be granted readwrite role
              admin      = []  # List of users/service accounts to be granted admin role
            }
          }
        ]
      }
    ]
  }
}
```

For example, if you want to grant sa-pubsub service account in Connect Dev an invoker role for Cloud Run in Business Dev:

![invoker-grant](./images/cloud-run-invoker-role.png)

### Structure of `_config_environment_custom_roles.auto.tfvars`:

```
environments = {
  "environment-name" = {
    environment_custom_roles = [{ # List of custom roles shared across all projects in the environment
      title                    # Name of the custom IAM role
      permissions              # List of permissions assigned to the role
      description              # Description of the custom role
    }]

    pam_bindings              = [    # Optional list of PAM (privileged access management) entitlements
      {
        role                  # Custom role name in the enetitlement
        principals            # List of principals that can be granted the role
        role_type             # Optional value, when set to 'custom' ensures custom role URI is properply generated
      }
    ]

    database_role_assignment   = {   # Optional map of custom role assignments
                                    (roles will apply to all databases in the corresponnding env, that are listed in `project_account_bindings.auto.tfvars`)
      readonly               # list of ...@gov.bc.ca emails to be granted db custom roles
      readwrite              # list of ...@gov.bc.ca emails to be granted db custom roles
      admin                  # list of ...@gov.bc.ca emails to be granted db custom roles
    }
  }
}
```

### Structure of `_config_global_custom_roles.auto.tfvars`:

```
global_database_role_assignment = {  # Global database role assignments
  readonly = []   # List of users/emails granted readonly access to all databases
  readwrite = []  # List of users/emails granted readwrite access to all databases
  admin = []      # List of users/emails granted admin access to all databases
}

global_custom_roles = {  # Map of global custom roles
  role-name = {
    title = ""        # Name of the custom IAM role
    description = ""  # Description of the custom role
    permissions = []  # List of permissions assigned to the role
  }
}
```

## Terraform Workspaces

This configuration uses **Terraform workspaces** to separate state by environment. Each workspace manages only the resources for its corresponding environment.

> **⚠️ Important:** Always use the `tf.sh` helper script instead of running `terraform` commands directly. The script handles environment setup, workspace selection, and prevents common mistakes.

### Workspace Structure

| Workspace | Config Variable | Manages |
|-----------|-----------------|---------|
| `dev` | `var.dev_projects` | All dev environment projects |
| `test` | `var.test_projects` | All test environment projects |
| `prod` | `var.prod_projects` | All prod environment projects |
| `other` | `var.other_projects` | Sandbox and tools projects |
| `default` | (none) | Shared resources only (SQL role scripts in GCS) |

### State Files

State is stored in GCS bucket `common-tools-terraform-state` with prefix `iam`:
- `gs://common-tools-terraform-state/iam/default.tfstate` — default workspace
- `gs://common-tools-terraform-state/iam/env:/dev/default.tfstate` — dev workspace
- `gs://common-tools-terraform-state/iam/env:/test/default.tfstate` — test workspace
- `gs://common-tools-terraform-state/iam/env:/prod/default.tfstate` — prod workspace
- `gs://common-tools-terraform-state/iam/env:/other/default.tfstate` — other workspace

### Using the tf.sh Helper Script

The `tf.sh` script is the **recommended way** to run Terraform commands. It automatically:
- Loads the `.env` file with required credentials
- Selects the correct workspace
- Prevents accidentally running against the wrong environment

```bash
# Check status of all workspaces
./tf.sh status

# Plan for a specific environment
./tf.sh plan dev
./tf.sh plan prod

# Plan all workspaces
./tf.sh plan all

# Apply changes to a specific environment
./tf.sh apply dev
./tf.sh apply prod

# List workspaces
./tf.sh list
```

### Shared Resources

The `default` workspace manages shared resources that all environments depend on:
- SQL role definition scripts (`readonly.sql`, `readwrite.sql`, `admin.sql`) uploaded to `gs://common-tools-sql/`

Environment workspaces reference these scripts but don't manage them. If you update the SQL scripts:
```bash
./tf.sh apply default
./tf.sh apply all
```

### Global and Environment Configuration

The following tfvars files are **shared inputs** loaded by all workspaces:
- `_config_global_custom_roles.auto.tfvars` — Global custom roles and DB role assignments
- `_config_environment_custom_roles.auto.tfvars` — Environment-level settings

Changes to these files affect resources in multiple workspaces. After modifying them:
```bash
./tf.sh apply all
```

## Applying Changes

4. After merging the new branch into main you can manually run [Terraform-GCS](https://github.com/bcgov/bcregistry-sre/blob/main/.github/workflows/terraform-gcs.yaml) github action
5. Output of terraform plan can be reviewed in https://github.com/bcgov/bcregistry-sre/actions/workflows/terraform-gcs.yaml
6. Alternatively, you can run changes locally before pushing to main using the `tf.sh` script.

### Applying Changes Locally

> **⚠️ Always use `./tf.sh` instead of bare `terraform` commands.**

```bash
# Preview changes for dev
./tf.sh plan dev

# Apply changes to dev
./tf.sh apply dev

# Apply changes to all environments
./tf.sh apply all

# Check resource counts across all workspaces
./tf.sh status
```

If you must use bare terraform commands (not recommended), ensure you:
1. Source the environment file: `set -a && source .env && set +a`
2. Select the correct workspace: `terraform workspace select <env>`
3. Run plan/apply for that workspace only
