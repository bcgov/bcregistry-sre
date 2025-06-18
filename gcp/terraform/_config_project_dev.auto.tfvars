dev_projects = {
  "analytics-int-dev" = {
    project_id = "mvnjri-dev"
    env = "dev"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/mvnjri-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/mvnjri-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/mvnjri-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "common-dev" = {
    project_id = "c4hnrd-dev"
    env = "dev"
    instances = [
      {
        instance = "common-db-dev"
        databases =  [
              {
                db_name    = "docs"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
              }
            ]
      },
      {
        instance = "notify-db-dev"
        databases =  [
              {
                db_name    = "notify"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "notifyuser"
                agent      = "postgres"
                database_role_assignment = {
                  readonly = []
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-db-migrate = {
        roles       = ["projects/c4hnrd-dev/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-pubsub = {
        roles       = ["projects/c4hnrd-dev/roles/rolequeue", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/c4hnrd-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/c4hnrd-dev/roles/roleapi", "roles/cloudsql.instanceUser", "roles/serverless.serviceAgent"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/c4hnrd-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      open-shift-artifact-registry = {
        roles       = ["roles/artifactregistry.serviceAgent", "roles/cloudbuild.builds.builder", "roles/containerregistry.ServiceAgent"]
        description = ""
      },
      documentai-workflow-service-ac = {
        roles       = ["roles/composer.environmentAndStorageObjectViewer", "roles/documentai.apiUser", "roles/eventarc.eventReceiver", "roles/logging.logWriter", "roles/serviceusage.serviceUsageConsumer", "roles/storage.objectUser", "roles/storagetransfer.user", "roles/workflows.invoker"]
        description = ""
        resource_roles = [
          { resource = "projects/c4hnrd-dev/locations/asia/repositories/asia.gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          },
          { resource = "projects/c4hnrd-dev/locations/europe/repositories/eu.gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          },
          { resource = "projects/c4hnrd-dev/locations/us/repositories/gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          },
          { resource = "projects/c4hnrd-dev/locations/us/repositories/us.gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          }
        ]
      },
      doc-dev-sa = {
        roles       = ["roles/artifactregistry.serviceAgent", "roles/compute.admin", "roles/storage.admin"]
        description = "Document Services Service Account"
        resource_roles = [
          { resource = "projects/c4hnrd-dev/locations/asia/repositories/asia.gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          },
          { resource = "projects/c4hnrd-dev/locations/europe/repositories/eu.gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          },
          { resource = "projects/c4hnrd-dev/locations/us/repositories/gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          },
          { resource = "projects/c4hnrd-dev/locations/us/repositories/us.gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          }
        ]
      },
      synthetic-monitoring = {
        roles       = ["roles/cloudfunctions.developer", "roles/logging.logWriter", "roles/monitoring.editor", "roles/run.admin", "roles/run.serviceAgent", "roles/secretmanager.secretAccessor", "roles/secretmanager.viewer"]
        description = "POC for synthetic monitoring"
        resource_roles = [
          { resource = "registries-synthetic-monitor"
            roles    = ["roles/storage.legacyBucketReader", "roles/storage.objectAdmin"]
            resource_type = "storage_bucket"
          },
          { resource = "projects/366678529892/secrets/PWDIDIR"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          { resource = "projects/366678529892/secrets/USERNAMEIDIR"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          { resource = "projects/366678529892/secrets/PWDSCBC"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          { resource = "projects/366678529892/secrets/USERNAMESCBC"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      }
    }
  },
  "connect-dev" = {
    project_id = "gtksf3-dev"
    env = "dev"
    instances = [
      {
        instance = "auth-db-dev"
        databases =  [
          {
                db_name    = "auth-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "auth"
                agent      = "postgres"
                database_role_assignment = {
                  readonly = ["thayne.werdal@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "rajandeep.kaur@gov.bc.ca", "felipe.moraes@gov.bc.ca", "sergey.popov@gov.bc.ca", "syed.riyazzudin@gov.bc.ca", "severin.beauvais@gov.bc.ca", "karim.jazzar@gov.bc.ca"]
                  readwrite = ["ken.li@gov.bc.ca"]
                  admin = []
                }
              }
            ]
      },
      {
        instance = "pay-db-dev"
        databases =  [
          {
                db_name    = "pay-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "pay"
                agent      = "postgres"
                database_role_assignment = {
                  readonly = ["felipe.moraes@gov.bc.ca", "sergey.popov@gov.bc.ca"]
                  readwrite = ["ken.li@gov.bc.ca", "travis.semple@gov.bc.ca"]
                  admin = []
                }
          }
        ]
      }
    ]
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
        resource_roles = [
            {
              resource = "projects/a083gt-dev/locations/northamerica-northeast1/services/namex-pay-dev"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            }
          ]
      },
      sa-job = {
        roles       = ["projects/gtksf3-dev/roles/rolejob"]
        description = "Service Account for running job services"
        resource_roles = [
            {
              resource = "ftp-poller-dev"
              roles    = ["roles/storage.legacyBucketWriter"]
              resource_type = "storage_bucket"
            }
        ]
      },
      sa-api = {
        roles       = ["projects/gtksf3-dev/roles/roleapi", "roles/iam.serviceAccountTokenCreator"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "auth-account-mailer-dev"
              roles    = ["roles/storage.objectViewer"]
              resource_type = "storage_bucket"
            },
            {
              resource = "auth-accounts-dev"
              roles    = ["projects/gtksf3-dev/roles/rolestore"]
              resource_type = "storage_bucket"
            },
            {
              resource = "projects/gtksf3-dev/topics/auth-event-dev"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/gtksf3-dev/topics/account-mailer-dev"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
        ]
      },
      sa-queue = {
        roles       = ["projects/gtksf3-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      pay-test = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = ""
      },
      pay-pubsub-sa = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for handling pay pusub subscriptions"
        external_roles = [{
          roles       = ["roles/iam.serviceAccountTokenCreator", "roles/run.invoker"]
          project_id  = "bcrbk9-dev"
        },
        {
          roles        = ["roles/iam.serviceAccountTokenCreator", "roles/run.invoker"]
          project_id  = "a083gt-dev"
        }
      ]

      },
      sa-auth-db-standby-759 = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = "Service account used to backup auth db in OpenShift Gold Cluster, as part of disaster recovery plan."
      },
      sre-role-testing-account = {
        roles       = ["projects/gtksf3-dev/roles/SRE"]
        description = ""
      }
    }
  },
  "bor-dev" = {
    project_id = "yfjq17-dev"
    env = "dev"
    instances = [
      {
        instance = "bor-db"
        databases =  [
              {
                db_name    = "bor"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "devUser"
                database_role_assignment = {
                  readonly = []
                  readwrite = []
                  admin = []
                }
              }
            ]
      },
      {
        instance = "btr-db-dev"
        databases =  [
              {
                db_name    = "btr"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "devUser"
                database_role_assignment = {
                  readonly = ["gunasegaran.nagarajan@gov.bc.ca", "sa-solr-importer"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/yfjq17-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfjq17-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfjq17-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-solr-importer = {
      roles       = ["projects/yfjq17-dev/roles/rolesolrimporter"]
      description = "Service Account for solr importer services"
      }
    }
  },
  "bcr-businesses-dev" = {
      project_id = "a083gt-dev"
      env = "dev"
      instances = [
        {
          instance = "businesses-db-dev"
          databases =  [
            {
                  db_name    = "business-ar"
                  roles      = ["readonly", "readwrite", "admin"]
                  owner      = "business-ar-api"
                  database_role_assignment = {
                    readonly = ["syed.riyazzudin@gov.bc.ca", "vishnu.preddy@gov.bc.ca", "gunasegaran.nagarajan@gov.bc.ca"]
                    readwrite = []
                    admin = []
                  }
                },
                {
                  db_name    = "business"
                  roles      = ["readonly", "readwrite", "admin"]
                  owner      = "business-api"
                  database_role_assignment = {
                    readonly = ["sa-solr-importer"]
                    readwrite = []
                    admin = []
                  }
                }
              ]
        },
        {
          instance = "namex-db-dev"
          databases =  [
            {
                  db_name    = "namex"
                  roles      = ["readonly", "readwrite", "admin"]
                  owner      = "userHQH"
                  database_role_assignment = {
                    readonly = ["rajandeep.kaur@gov.bc.ca", "felipe.moraes@gov.bc.ca", "syed.riyazzudin@gov.bc.ca", "vishnu.preddy@gov.bc.ca", "sa-solr-importer"]
                    readwrite = []
                    admin = []
                  }
                }
              ]
        }
      ]
      service_accounts = {
        sa-db-migrate = {
          roles       = ["projects/a083gt-dev/roles/roleapi", "roles/cloudsql.client", "roles/cloudsql.admin"]
          description = "Service Account for migrating db from openshift"
          resource_roles = [
              { resource = "projects/475224072965/secrets/OC_TOKEN_cc892f-dev"
                roles    = ["roles/secretmanager.secretAccessor"]
                resource_type = "secret_manager"
              },
              {
                resource = "lear_ocp_dumps"
                roles    = ["roles/storage.admin"]
                resource_type = "storage_bucket"
              }
            ]
        },
        sa-pubsub = {
          roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
          description = "Service Account for running pubsub services"
        },
        sa-job = {
          roles       = ["projects/a083gt-dev/roles/rolejob"]
          description = "Service Account for running job services"
        },
        sa-api = {
          roles       = ["projects/a083gt-dev/roles/roleapi", "roles/iam.serviceAccountTokenCreator", "roles/cloudtasks.enqueuer", "roles/cloudtasks.viewer", "roles/cloudtasks.taskDeleter"]
          description = "Service Account for running api services"
          resource_roles = [
              {
                resource = "projects/a083gt-dev/locations/northamerica-northeast1/services/namex-solr-synonyms-api-dev"
                roles    = ["roles/run.invoker"]
                resource_type = "cloud_run"
              },
              {
                resource = "projects/a083gt-dev/locations/northamerica-northeast1/services/namex-api-dev"
                roles    = ["roles/run.invoker"]
                resource_type = "cloud_run"
              },
              {
                resource = "projects/a083gt-dev/topics/namex-emailer-dev"
                roles    = ["roles/pubsub.publisher"]
                resource_type = "pubsub_topic"
              },
              {
                resource = "projects/a083gt-dev/topics/namex-nr-state-dev"
                roles    = ["roles/pubsub.publisher"]
                resource_type = "pubsub_topic"
              }
            ]
        },
        sa-queue = {
          roles       = ["projects/a083gt-dev/roles/rolequeue"]
          description = "Service Account for running queue services"
        },
        business-ar-job-process-paid = {
          roles       = ["roles/run.invoker"]
          description = ""
        },
        sa-lear-db-standby = {
          roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
          description = ""
        },
        sa-bni-file-upload-dev = {
          roles       = ["roles/storage.objectCreator"]
          description = "Service Account to upload raw batch files to the BNI storage bucket"
        },
        business-pubsub-sa = {
          roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
          description = ""
        },
        sa-solr-importer = {
          roles       = ["projects/a083gt-dev/roles/rolesolrimporter"]
          description = "Service Account for solr importer services"
      }
    }
  },
  "business-number-hub-dev" = {
    project_id = "keee67-dev"
    env = "dev"
    instances = [
      {
        instance = "hub-dev"
        databases =  [
          {
                db_name    = "auth-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "auth"
          },
          {
                db_name    = "vans-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "vans"
          }
        ]
      }
    ]
    service_accounts = {
      bn-tasks-cloud-run-invoker = {
        roles       = ["roles/cloudtasks.enqueuer", "roles/iam.serviceAccountUser", "roles/run.invoker"]
        description = "BN Tasks Cloud Run Invoker"
      },
      sa-bni-file-upload-dev = {
        roles       = ["roles/storage.objectCreator"]
        description = "Service Account to upload raw batch files to the BNI storage bucket"
      },
      pubsub-cloud-run-invoker = {
      description = ""
      resource_roles = [
          {
            resource = "projects/keee67-dev/locations/northamerica-northeast1/services/bn-batch-parser"
            roles    = ["roles/run.invoker"]
            resource_type = "cloud_run"
          }
        ]
      }
    }
  },
  "ppr-dev" = {
    project_id = "eogruh-dev"
    env = "dev"
    instances = [
      {
        instance = "ppr-dev-cloudsql"
        databases =  [
          {
                db_name    = "ppr"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
                database_role_assignment = {
                  readonly = ["divya.chandupatla@gov.bc.ca"]
                  readwrite = []
                  admin = []
                }
          }
        ]
      }
    ]
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-api = {
        roles       = ["projects/eogruh-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/eogruh-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-ppr-db-standby = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = ""
      },
      ppr-dev-sa = {
        roles       = ["roles/containerregistry.ServiceAgent", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.admin", "roles/pubsub.serviceAgent", "roles/storage.admin", "roles/storage.objectCreator"]
        description = "Default service account for ppr cloud services"
        resource_roles = [
          { resource = "eogruh-dev_cloudbuild"
            roles    = ["roles/storage.legacyBucketWriter"]
            resource_type = "storage_bucket"
          },
          { resource = "projects/c4hnrd-dev/topics/doc-api-app-create-record"
            roles    = ["roles/pubsub.publisher"]
            resource_type = "pubsub_topic"
          },
          { resource = "projects/eogruh-dev/locations/us/repositories/gcr.io"
            roles    = ["roles/artifactregistry.repoAdmin"]
            resource_type = "artifact_registry"
          }
        ]
      }
    }
  },
  "search-dev" = {
    project_id = "k973yf-dev"
    env = "dev"
    instances = [
      {
        instance = "search-db-dev"
        databases =  [
              {
                db_name    = "search"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "devUser"
                database_role_assignment = {
                  readonly = ["gunasegaran.nagarajan@gov.bc.ca"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      }
    ]
    service_accounts = {
      gha-wif = {
        roles       = ["roles/compute.admin", "roles/storage.objectAdmin"]
        description = "Service account used by WIF POC"
        resource_roles = [
          {
            resource = "projects/k973yf-dev/serviceAccounts/952634948388-compute@developer.gserviceaccount.com"
            roles    = ["roles/iam.serviceAccountUser"]
            resource_type = "sa_iam_member"
          }
        ]
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/k973yf-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/k973yf-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/k973yf-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "web-presence-dev" = {
    project_id = "yfthig-dev"
    env = "dev"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/yfthig-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfthig-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfthig-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      apigee-dev-sa = {
        roles       = ["roles/logging.admin", "roles/storage.admin"]
        description = "Service account for BC Registries Apigee dev environment."
      },
      github-action-467311281 = {
        roles       = ["roles/cloudbuild.builds.editor", "roles/firebaseauth.admin", "roles/firebasehosting.admin", "roles/run.viewer", "roles/serviceusage.apiKeysViewer", "roles/serviceusage.serviceUsageConsumer", "roles/storage.admin"]
        description = "A service account with permission to deploy to Firebase Hosting for the GitHub repository thorwolpert/bcregistry"
      }
    }
  },
  "strr-dev" = {
    project_id = "bcrbk9-dev"
    env = "dev"
    instances = [
      {
        instance = "strr-db-dev"
        databases =  [
          {
                db_name    = "strr-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "strr"
                database_role_assignment = {
                  readonly = ["sergey.popov@gov.bc.ca"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/bcrbk9-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/bcrbk9-dev/roles/roleapi", "roles/pubsub.publisher", "roles/storage.admin", "roles/storage.objectCreator"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/bcrbk9-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-eventarc = {
        roles       = ["roles/eventarc.eventReceiver", "roles/run.invoker"]
        description = "Service Account for running queue services"
      },
      test-notebook-dev = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.instanceUser", "roles/cloudsql.schemaViewer"]
        description = "used with the test services"
      },
      client-sql-proxy-service-accnt = {
        roles       = ["roles/cloudsql.admin", "roles/cloudsql.client"]
        description = ""
      }
    }
  },
  "analytics-ext-dev" = {
    project_id = "sbgmug-dev"
    env = "dev"
  },
  "api-gateway-dev" = {
    project_id = "okagqp-dev"
    env = "dev"
    service_accounts = {
      apigee-dev-sa = {
        roles       = ["roles/logging.admin", "roles/storage.admin"]
        description = "Service accont for apigee gateway integration including logging."
      }
    }
  }
}
