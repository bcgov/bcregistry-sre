test_projects = {
  "common-test" = {
    project_id = "c4hnrd-test"
    env = "test"
    instances = [
      {
        instance = "common-db-test"
        databases =  [
              {
                db_name    = "docs"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
              }
            ]
      },
      {
        instance = "notify-db-test"
        databases =  [
              {
                db_name    = "notify"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "notifyuser"
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
      sa-pubsub = {
        roles       = ["projects/c4hnrd-test/roles/rolequeue", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-db-migrate = {
        roles       = ["projects/c4hnrd-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-job = {
        roles       = ["projects/c4hnrd-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/c4hnrd-test/roles/roleapi", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/c4hnrd-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      doc-test-sa = {
        description = "Document Services Service Account"
        resource_roles = [
          {
            resource = "docs_ppr_test"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          },
          {
            resource = "docs_nr_test"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          },
          {
            resource = "docs_mhr_test"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          },
          {
            resource = "docs_business_test"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          }
        ]
      }
    }
  },
  "connect-test" = {
    project_id = "gtksf3-test"
    env = "test"
    instances = [
      {
        instance = "auth-db-test"
        databases =  [
          {
                db_name    = "auth-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "auth"
                database_role_assignment = {
                  readonly = ["syed.riyazzudin@gov.bc.ca", "noor.nayeem@gov.bc.ca", "patty.stemkens@gov.bc.ca", ", "janis.rogers@gov.bc.ca"]
                  readwrite = ["sa-api", "anish.batra@gov.bc.ca"]
                  admin = ["sa-db-migrate"]
                }
              }
            ]
      },
      {
        instance = "pay-db-test"
        databases =  [
          {
                db_name    = "pay-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "pay"
                database_role_assignment = {
                  readonly = ["noor.nayeem@gov.bc.ca", "patty.stemkens@gov.bc.ca", "janis.rogers@gov.bc.ca"]
                  readwrite = ["anish.batra@gov.bc.ca"]
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
              resource = "projects/a083gt-test/locations/northamerica-northeast1/services/namex-pay-test"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            }
          ]
      },
      sa-db-migrate = {
        roles       = ["projects/gtksf3-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-job = {
        roles       = ["projects/gtksf3-test/roles/rolejob"]
        description = "Service Account for running job services"
        resource_roles = [
            {
              resource = "ftp-poller-test"
              roles    = ["roles/storage.legacyBucketWriter"]
              resource_type = "storage_bucket"
            }
        ]
      },
      sa-api = {
        roles       = ["projects/gtksf3-test/roles/roleapi", "roles/cloudsql.client", "roles/iam.serviceAccountTokenCreator", "roles/cloudsql.instanceUser", "roles/serverless.serviceAgent"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "auth-account-mailer-test"
              roles    = ["roles/storage.objectViewer"]
              resource_type = "storage_bucket"
            },
            {
              resource = "auth-accounts-test"
              roles    = ["projects/gtksf3-test/roles/rolestore"]
              resource_type = "storage_bucket"
            },
            {
              resource = "projects/gtksf3-test/topics/auth-event-test"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/gtksf3-test/topics/account-mailer-test"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
        ]
      },
      sa-queue = {
        roles       = ["projects/gtksf3-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-auth-db-standby = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = "Service account used to backup auth db in OpenShift Gold Cluster, as part of disaster recovery plan."
      }
    }
  },
  "bor-test" = {
    project_id = "yfjq17-test"
    env = "test"
    instances = [
      {
        instance = "bor-db-test"
        databases =  [
              {
                db_name    = "bor"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "testUser"
                database_role_assignment = {
                  readonly = []
                  readwrite = []
                  admin = []
                }
              }
            ]
      },
      {
        instance = "btr-db-test"
        databases =  [
              {
                db_name    = "btr"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "testUser"
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
        roles       = ["projects/yfjq17-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfjq17-test/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfjq17-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-solr-importer = {
        roles       = ["projects/yfjq17-test/roles/rolesolrimporter"]
        description = "Service Account for solr importer services"
      }
    }
  },
  "bcr-businesses-test" = {
    project_id = "a083gt-test"
    env = "test"
    instances = [
      {
        instance = "businesses-db-test"
        databases =  [
          {
                db_name    = "business-ar"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "business-ar-api"
                database_role_assignment = {
                  readonly = ["syed.riyazzudin@gov.bc.ca", "gunasegaran.nagarajan@gov.bc.ca", "sa-solr-importer"]
                  readwrite = []
                  admin = []
                }
              },
              {
                db_name    = "business"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "business-api"
                database_role_assignment = {
                  readonly = ["sa-solr-importer", "janis.rogers@gov.bc.ca"]
                  readwrite = ["syed.riyazzudin@gov.bc.ca", "sa-job", "sa-api"]
                  admin = []
                }
              }
            ]
      },
      {
        instance = "namex-db-test"
        databases =  [
          {
                db_name    = "namex"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "userHQH"
                database_role_assignment = {
                  readonly = ["syed.riyazzudin@gov.bc.ca", "vishnu.preddy@gov.bc.ca", "sa-solr-importer", "janis.rogers@gov.bc.ca"]
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
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
        roles       = ["projects/a083gt-test/roles/rolejob", "roles/cloudsql.client", "roles/cloudsql.instanceUser"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-test/roles/roleapi", "roles/iam.serviceAccountTokenCreator", "roles/cloudtasks.enqueuer", "roles/cloudtasks.viewer", "roles/cloudtasks.taskDeleter", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "projects/a083gt-test/locations/northamerica-northeast1/services/namex-solr-synonyms-api-test"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-test/locations/northamerica-northeast1/services/namex-api-test"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-test/topics/namex-emailer-test"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/a083gt-test/topics/namex-nr-state-test"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
          ]
      },
      sa-queue = {
        roles       = ["projects/a083gt-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-bni-file-upload-test = {
        roles       = ["roles/storage.objectCreator"]
        description = "Service Account to upload raw batch files to the BNI storage bucket"
      },
      business-ar-job-proc-paid-test = {
        roles       = ["roles/run.invoker"]
        description = "submit AR back to the SOR"
      },
      sa-lear-db-standby = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = ""
      },
      sa-db-migrate = {
        roles       = ["projects/a083gt-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-solr-importer = {
        roles       = ["projects/a083gt-test/roles/rolesolrimporter"]
        description = "Service Account for solr importer services"
      }
    }
  },
  "business-number-hub-test" = {
    project_id = "keee67-test"
    env = "test"
    instances = [
      {
        instance = "bn-hub-test"
        databases =  [
          {
                db_name    = "bni-hub"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "bni-hub"
          }
        ]
      }
    ]
    service_accounts = {
      bn-batch-processor-test = {
        roles       = ["roles/cloudtasks.admin", "roles/editor", "roles/run.invoker", "roles/storage.admin"]
        description = ""
      },
      bn-tasks-run-invoker-test = {
        roles       = ["roles/editor", "roles/iam.serviceAccountUser", "roles/storage.objectCreator"]
        description = ""
        resource_roles = [
          {
            resource = "projects/keee67-test/serviceAccounts/bn-tasks-run-invoker-test@keee67-test.iam.gserviceaccount.com"
            roles    = ["roles/iam.serviceAccountAdmin"]
            resource_type = "sa_iam_member"
          }
        ]
      },
      sa-bni-file-upload-test = {
        roles       = ["roles/storage.objectCreator"]
        description = "Service Account to upload raw batch files to the BNI storage bucket"
      },
      pubsub-cloud-run-invoker-test = {
      description = ""
      resource_roles = [
          {
            resource = "projects/keee67-test/locations/northamerica-northeast1/services/bn-batch-parser"
            roles    = ["roles/run.invoker"]
            resource_type = "cloud_run"
          }
        ]
      }
    }
  },
  "ppr-test" = {
    project_id = "eogruh-test"
    env = "test"
    instances = [
      {
        instance = "ppr-test-cloudsql"
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
          },
          {
                db_name    = "notify"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "notifyuser"
          },
          {
                db_name    = "jobs"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
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
        roles       = ["projects/eogruh-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/eogruh-test/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/eogruh-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      ppr-temp-verification-sa = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.admin"]
        description = ""
      },
      sa-ppr-documents-test = {
        roles       = ["projects/eogruh-test/roles/ppr_document_storage_test", "roles/cloudsql.client", "roles/iam.serviceAccountTokenCreator"]
        description = ""
        resource_roles = [
          {
            resource = "ppr_documents_test"
            roles    = ["projects/eogruh-test/roles/ppr_document_storage_test"]
            resource_type = "storage_bucket"
          }
        ]
      },
      notify-identity = {
        roles       = ["roles/cloudsql.client"]
        description = ""
      },
      ppr-test-sa = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.admin", "roles/storage.admin"]
        description = "Default service account for ppr cloud services"
        resource_roles = [
            {
              resource = "projects/eogruh-test/locations/northamerica-northeast1/services/gotenberg"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/c4hnrd-test/topics/doc-api-app-create-record"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
          ]
      }
    }
  },
  "search-test" = {
    project_id = "k973yf-test"
    env = "test"
    instances = [
      {
        instance = "search-db-test"
        databases =  [
              {
                db_name    = "search"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "testUser"
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
        roles       = ["roles/compute.admin"]
        description = "Service account used by WIF POC"
        external_roles = [{
          roles        = ["roles/compute.imageUser"]
          project_id  = "k973yf-dev"
        }]
        resource_roles = [
            {
              resource = "projects/k973yf-test/serviceAccounts/107836257140-compute@developer.gserviceaccount.com"
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
        roles       = ["projects/k973yf-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/k973yf-test/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/k973yf-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "web-presence-test" = {
    project_id = "yfthig-test"
    env = "test"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/yfthig-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfthig-test/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfthig-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      github-action-416185190 = {
        roles       = ["roles/cloudbuild.builds.editor", "roles/firebaseauth.admin", "roles/firebasehosting.admin", "roles/run.viewer", "roles/serviceusage.apiKeysViewer", "roles/serviceusage.serviceUsageConsumer", "roles/storage.admin"]
        description = "A service account with permission to deploy to Firebase Hosting for the GitHub repository thorwolpert/fh-test"
      },
      sa-cdcloudrun = {
        roles       = ["projects/yfthig-test/roles/rolecdcloudrun"]
        description = "Service Account for running cdcloudrun services"
      }
    }
  },
  "strr-test" = {
    project_id = "bcrbk9-test"
    env = "test"
    instances = [
      {
        instance = "strr-db-test"
        databases =  [
          {
                db_name    = "strr-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "strr"
                database_role_assignment = {
                  readonly = []
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
        roles       = ["projects/bcrbk9-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/bcrbk9-test/roles/roleapi", "roles/pubsub.publisher", "roles/storage.admin", "roles/storage.objectCreator"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/bcrbk9-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "api-gateway-test" = {
    project_id = "okagqp-test"
    env = "test"
    service_accounts = {
      apigee-test-sa = {
        roles       = ["roles/apigee.apiAdminV2", "roles/apigee.developerAdmin", "roles/logging.admin", "roles/logging.serviceAgent", "roles/storage.admin"]
        description = "Service account for apigee gateway integration including logging"
      }
    }
  }
}
