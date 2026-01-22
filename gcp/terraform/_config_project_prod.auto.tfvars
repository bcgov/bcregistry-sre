prod_projects = {
  "analytics-int-prod" = {
    project_id = "mvnjri-prod"
    env = "prod"
    instances = [
      {
        instance = "fin-warehouse-prod"
        databases =  [
              {
                db_name    = "fin_warehouse"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "pay"
                database_role_assignment = {
                  readonly = ["sa-notebook@c4hnrd-prod.iam.gserviceaccount.com", "sa-job@gtksf3-prod.iam.gserviceaccount.com", "758264625079-compute@developer.gserviceaccount.com", "vikas.singh@gov.bc.ca",  "severin.beauvais@gov.bc.ca", "darci.denis@gov.bc.ca", "jia.xu@gov.bc.ca", "vysakh.menon@gov.bc.ca", "michael.kagis@gov.bc.ca", "tyson.graham@gov.bc.ca", "varek.boettcher@gov.bc.ca", "michelle.hohertz@gov.bc.ca", "david.draker@gov.bc.ca", "jordan.merrick@gov.bc.ca","harshiv.bagha@gov.bc.ca", "Brett.cassidy@gov.bc.ca", "jay.sharp@gov.bc.ca", "james.mcfarlane@gov.bc.ca", "melissa.stanton@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "john.a.m.lane@gov.bc.ca", "sa-strr-analytics@bcrbk9-prod.iam.gserviceaccount.com", "patty.stemkens@gov.bc.ca"]
                  readwrite = ["mike.huffman@gov.bc.ca", "genevieve.primeau@gov.bc.ca", "monica.mow@gov.bc.ca", "anushka.halder@gov.bc.ca"]
                  admin = []
                }
              }
            ]
      },
      {
        instance = "fin-warehouse-prod-clone"
        databases =  [
              {
                db_name    = "fin_warehouse"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "pay"
                database_role_assignment = {
                  readonly = ["sa-notebook@c4hnrd-prod.iam.gserviceaccount.com", "sa-job@gtksf3-prod.iam.gserviceaccount.com", "758264625079-compute@developer.gserviceaccount.com", "vikas.singh@gov.bc.ca", "severin.beauvais@gov.bc.ca", "darci.denis@gov.bc.ca", "jia.xu@gov.bc.ca", "vysakh.menon@gov.bc.ca", "michael.kagis@gov.bc.ca", "tyson.graham@gov.bc.ca", "varek.boettcher@gov.bc.ca", "michelle.hohertz@gov.bc.ca", "david.draker@gov.bc.ca", "jordan.merrick@gov.bc.ca", "harshiv.bagha@gov.bc.ca", "Brett.cassidy@gov.bc.ca", "jay.sharp@gov.bc.ca", "james.mcfarlane@gov.bc.ca", "melissa.stanton@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "john.a.m.lane@gov.bc.ca", "sa-strr-analytics@bcrbk9-prod.iam.gserviceaccount.com", "patty.stemkens@gov.bc.ca"]
                  readwrite = ["mike.huffman@gov.bc.ca", "genevieve.primeau@gov.bc.ca", "monica.mow@gov.bc.ca", "anushka.halder@gov.bc.ca"]
                  admin = []
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pam-function = {
        roles       = ["projects/mvnjri-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/560428767344/secrets/DATA_WAREHOUSE_PAY_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/mvnjri-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/mvnjri-prod/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/mvnjri-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      jupyter-dashboard-int-prod = {
        roles       = ["roles/iam.serviceAccountUser"]
        description = ""
      },
      sa-staff-warehouse-mvnjri = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.instanceUser", "roles/cloudsql.viewer"]
        description = "Service Account for enabling staff connecton to data warehouse"
      },
      fin-warehouse-bucket-writer = {
        roles       = ["roles/iam.serviceAccountUser", "roles/storage.objectCreator", "roles/storage.objectViewer"]
        description = ""
        resource_roles = [
          {
            resource = "projects/mvnjri-prod/serviceAccounts/fin-warehouse-bucket-writer@mvnjri-prod.iam.gserviceaccount.com"
            roles    = ["roles/iam.serviceAccountUser"]
            resource_type = "sa_iam_member"
          }
        ]
      },
      github-actions = {
        roles       = ["roles/iam.serviceAccountUser", "roles/serviceusage.apiKeysViewer", "roles/storage.objectAdmin"]
        description = " Data syncing between bcgov-registries/analytics sql files and data warehouse bucket"
      },
      sa-analytics-fin-warehouse = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = "fin_warehouse database access"
      },
      client-sql-proxy-service-accnt = {
        roles       = ["roles/cloudsql.admin", "roles/cloudsql.client", "roles/cloudsql.editor"]
        description = ""
      }
    }
    pam_bindings = [
      {
        role       = "roleitops"
        principals = ["user:Brett.cassidy@gov.bc.ca", "user:andriy.bolyachevets@gov.bc.ca", "user:david.draker@gov.bc.ca", "user:harshiv.bagha@gov.bc.ca", "user:jay.sharp@gov.bc.ca", "user:jordan.merrick@gov.bc.ca", "user:tyson.graham@gov.bc.ca"]
        role_type = "custom"
      }
    ]
  },
  "common-prod" = {
    project_id = "c4hnrd-prod"
    env = "prod"
    instances = [
      {
        instance = "common-db-prod"
        databases =  [
              {
                db_name    = "docs"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
                database_role_assignment = {
                  readonly = ["aimee.gao@gov.bc.ca", "dietrich.wolpert@gov.bc.ca", "eason.pan@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "lekshmi.gokul@gov.bc.ca", "megan.a.wong@gov.bc.ca", "lucas.o'neil@gov.bc.ca", "ketaki.deodhar@gov.bc.ca", "thayne.werdal@gov.bc.ca"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      },
      {
        instance = "notify-db-prod"
        databases =  [
              {
                db_name    = "notify"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "notifyuser"
                database_role_assignment = {
                  readonly = ["aimee.gao@gov.bc.ca", "dietrich.wolpert@gov.bc.ca", "eason.pan@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "lekshmi.gokul@gov.bc.ca", "megan.a.wong@gov.bc.ca", "lucas.o'neil@gov.bc.ca", "ketaki.deodhar@gov.bc.ca", "thayne.werdal@gov.bc.ca", "steven.chen@gov.bc.ca", "eve.deng@gov.bc.ca"]
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pam-function = {
        roles       = ["projects/c4hnrd-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/185633972304/secrets/NOTIFY_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/185633972304/secrets/USER4CA_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-db-migrate = {
        roles       = ["projects/c4hnrd-prod/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-pubsub = {
        roles       = ["projects/c4hnrd-prod/roles/rolequeue", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/c4hnrd-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-notebook = {
        roles       = ["projects/c4hnrd-prod/roles/rolejob", ]
        description = "Service Account for running notebook services"
        resource_roles = [
          {
            resource = "projects/185633972304/secrets/NOTIFY_CLIENT_SECRET"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/185633972304/secrets/BING_API_KEY"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/185633972304/secrets/BING_ID"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/185633972304/secrets/VIRUS_TOTAL_API_KEY"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/185633972304/secrets/GOOGLE_API_KEY"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
        external_roles = [{
          roles        = ["roles/cloudsql.instanceUser", "roles/run.serviceAgent", "roles/cloudsql.client"]
          project_id  = "mvnjri-prod"
        }]
      },
      sa-api = {
        roles       = ["projects/c4hnrd-prod/roles/roleapi", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/c4hnrd-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      doc-prod-sa = {
        description = "Document Services Service Account"
        resource_roles = [
          {
            resource = "docs_ppr_prod"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          },
          {
            resource = "docs_nr_prod"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          },
          {
            resource = "docs_mhr_prod"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          },
          {
            resource = "docs_business_prod"
            roles    = ["roles/storage.admin"]
            resource_type = "storage_bucket"
          }
        ]
      }
    }
    pam_bindings = [
     {
       role       = "roleitops"
       role_type = "custom"
     }
   ]
  },
  "connect-prod" = {
    project_id = "gtksf3-prod"
    env = "prod"
    instances = [
      {
        instance = "auth-db-prod"
        databases =  [
          {
                db_name    = "auth-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "auth"
                database_role_assignment = {
                  readonly = ["ketaki.deodhar@gov.bc.ca","dietrich.wolpert@gov.bc.ca", "hongjing.chen@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "jia.xu@gov.bc.ca", "syed.riyazzudin@gov.bc.ca", "megan.a.wong@gov.bc.ca", "thayne.werdal@gov.bc.ca", "anushka.halder@gov.bc.ca"]
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
                }
              }
            ]
      },
      {
        instance = "pay-db-prod"
        databases =  [
          {
                db_name    = "pay-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "pay"
                database_role_assignment = {
                  readonly = ["ketaki.deodhar@gov.bc.ca","dietrich.wolpert@gov.bc.ca", "hongjing.chen@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "jia.xu@gov.bc.ca", "syed.riyazzudin@gov.bc.ca", "megan.a.wong@gov.bc.ca", "thayne.werdal@gov.bc.ca", "anushka.halder@gov.bc.ca"]
                  readwrite = ["steven.chen@gov.bc.ca", "eve.deng@gov.bc.ca"]
                  admin = []
                }
          }
        ]
      }
    ]
    service_accounts = {
      sa-ocp-db-migrate = {
        roles       = ["projects/gtksf3-prod/roles/roleapi", "roles/cloudsql.client", "roles/cloudsql.admin"]
        description = "Service Account for migrating db from openshift"
        resource_roles = [
            { resource = "projects/758264625079/secrets/OC_TOKEN_78c88a-prod"
              roles    = ["roles/secretmanager.secretAccessor"]
              resource_type = "secret_manager"
            },
            {
              resource = "pay-db-dump-prod"
              roles    = ["roles/storage.admin"]
              resource_type = "storage_bucket"
            }
          ]
      },
      sa-pam-function = {
        roles       = ["projects/gtksf3-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/758264625079/secrets/AUTH_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-db-migrate = {
        roles       = ["projects/gtksf3-prod/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
        resource_roles = [
            {
              resource = "projects/a083gt-prod/locations/northamerica-northeast1/services/namex-pay-prod"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            }
          ]
      },
      sa-job = {
        roles       = ["projects/gtksf3-prod/roles/rolejob"]
        description = "Service Account for running job services"
        resource_roles = [
            {
              resource = "ftp-poller-prod"
              roles    = ["roles/storage.legacyBucketWriter"]
              resource_type = "storage_bucket"
            }
        ]
      },
      sa-api = {
        roles       = ["projects/gtksf3-prod/roles/roleapi", "roles/cloudsql.client", "roles/iam.serviceAccountTokenCreator", "roles/cloudsql.instanceUser", "roles/serverless.serviceAgent"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "auth-account-mailer-prod"
              roles    = ["roles/storage.objectViewer"]
              resource_type = "storage_bucket"
            },
            {
              resource = "auth-accounts-prod"
              roles    = ["projects/gtksf3-prod/roles/rolestore"]
              resource_type = "storage_bucket"
            },
            {
              resource = "projects/gtksf3-prod/topics/auth-event-prod"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/gtksf3-prod/topics/account-mailer-prod"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
        ]
      },
      sa-queue = {
        roles       = ["projects/gtksf3-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      auth-db-bucket-writer = {
        roles       = ["roles/iam.serviceAccountUser", "roles/storage.objectAdmin", "roles/storage.objectCreator", "roles/storage.objectViewer"]
        description = "Service Account for syncing anon extension masking rule files to auth-db dump bucket"
      },
      sa-auth-db-standby = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = "Service account used to backup auth db in OpenShift Gold Cluster, as part of disaster recovery plan."
      }
    }
    pam_bindings = [
     {
       role       = "roleitops"
       role_type = "custom"
     }
   ]
  },
  "bor-prod" = {
    project_id = "yfjq17-prod"
    env = "prod"
    instances = [
      {
        instance = "bor-db-prod"
        databases =  [
              {
                db_name    = "bor"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "prodUser"
                database_role_assignment = {
                  readonly = ["dietrich.wolpert@gov.bc.ca", "megan.a.wong@gov.bc.ca"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pam-function = {
        roles       = ["projects/yfjq17-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/291970782611/secrets/BOR_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/yfjq17-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfjq17-prod/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfjq17-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-solr-importer = {
       roles       = ["projects/yfjq17-prod/roles/rolesolrimporter"]
       description = "Service Account for solr importer services"
      }
    }
  },
  "bcr-businesses-prod" = {
    project_id = "a083gt-prod"
    env = "prod"
    instances = [
      {
        instance = "businesses-db-prod"
        databases =  [
          {
                db_name    = "business-ar"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "business-ar-api"
                database_role_assignment = {
                  readonly = ["sa-solr-importer"]
                  readwrite = []
                  admin = []
                }
              },
              {
                db_name    = "business"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "business-api"
                database_role_assignment = {
                  readonly = ["sa-solr-importer", "sa-notebook", "vikas.singh@gov.bc.ca", "syed.riyazzudin@gov.bc.ca", "severin.beauvais@gov.bc.ca", "mihai.dinu@gov.bc.ca", "vysakh.menon@gov.bc.ca", "thayne.werdal@gov.bc.ca", "aimee.gao@gov.bc.ca", "david.li@gov.bc.ca", "dietrich.wolpert@gov.bc.ca", "eason.pan@gov.bc.ca", "hongjing.chen@gov.bc.ca", "hrvoje.fekete@gov.bc.ca", "megan.a.wong@gov.bc.ca", "lucas.o'neil@gov.bc.ca", "ketaki.deodhar@gov.bc.ca", "kial.jinnah@gov.bc.ca", "steven.chen@gov.bc.ca", "eve.deng@gov.bc.ca"]
                  readwrite = ["sa-job", "sa-api"]
                  admin = []
                }
              }
            ]
      },
      {
        instance = "namex-db-prod"
        databases =  [
          {
                db_name    = "namex"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "userHQH"
                database_role_assignment = {
                  readonly = ["kial.jinnah@gov.bc.ca", "sa-solr-importer"]
                  readwrite = ["sa-api", "steven.chen@gov.bc.ca", "eve.deng@gov.bc.ca"]
                  admin = ["sa-db-migrate"]
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pam-function = {
        roles       = ["projects/a083gt-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/698952081000/secrets/BUSINESS_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/698952081000/secrets/BUSINESS_AR_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/a083gt-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-prod/roles/roleapi", "roles/iam.serviceAccountTokenCreator", "roles/cloudtasks.enqueuer", "roles/cloudtasks.viewer", "roles/cloudtasks.taskDeleter", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "projects/a083gt-prod/locations/northamerica-northeast1/services/namex-solr-synonyms-api-prod"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-prod/locations/northamerica-northeast1/services/namex-api-prod"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-prod/topics/namex-emailer-prod"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/a083gt-prod/topics/namex-nr-state-prod"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
          ]
      },
      sa-queue = {
        roles       = ["projects/a083gt-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-lear-db-standby = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = "Service account used to backup business db in OpenShift Gold Cluster, as part of disaster recovery plan."
      },
      sa-notebook = {
        roles       = ["roles/cloudsql.instanceUser", "roles/run.serviceAgent", "roles/cloudsql.client"]
        description = "Run notebook jobs in ocp."
      },
      sa-db-migrate = {
        roles       = ["projects/a083gt-prod/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-solr-importer = {
        roles       = ["projects/a083gt-prod/roles/rolesolrimporter"]
        description = "Service Account for solr importer services"
      },
      business-ar-job-proc-paid-prod = {
        roles       = ["roles/run.invoker"]
        description = "submit AR back to the SOR"
      }
    }
    pam_bindings = [
     {
       role       = "roleitops"
       role_type = "custom"
     }
   ]
  },
  "business-number-hub-prod" = {
    project_id = "keee67-prod"
    env = "prod"
    instances = [
      {
        instance = "bn-hub-prod"
        databases =  [
          {
                db_name    = "bni-hub"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "bni-hub"
          },
          {
                db_name    = "vans-db-prod"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "vans-prod"
          }
        ]
      }
    ]
    service_accounts = {
      sa-pam-function = {
        roles       = ["projects/keee67-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/747107125812/secrets/BNI_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          },
          {
            resource = "projects/747107125812/secrets/VANS_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      bn-tasks-run-invoker-prod = {
        roles       = ["roles/editor", "roles/iam.serviceAccountUser"]
        description = ""
      },
      bn-batch-processor-prod = {
        roles       = ["roles/cloudtasks.admin", "roles/editor"]
        description = ""
      },
      sa-bni-file-upload-prod = {
        roles       = ["roles/storage.objectCreator"]
        description = "Service Account to upload raw batch files to the BNI storage bucket"
      },
      pubsub-cloud-run-invoker-prod = {
      description = ""
      resource_roles = [
          {
            resource = "projects/keee67-prod/locations/northamerica-northeast1/services/bn-batch-parser"
            roles    = ["roles/run.invoker"]
            resource_type = "cloud_run"
          }
        ]
      }
    }
  },
  "ppr-prod" = {
    project_id = "eogruh-prod"
    env = "prod"
    instances = [
      {
        instance = "ppr-prod"
        databases =  [
          {
                db_name    = "ppr"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
                database_role_assignment = {
                  readonly = ["eve.deng@gov.bc.ca"]
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
      sa-pam-function = {
        roles       = ["projects/eogruh-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/1060957300107/secrets/PPR_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/eogruh-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/eogruh-prod/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/eogruh-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      ppr-prod-sa = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.admin", "roles/storage.admin"]
        description = "Default service account for ppr cloud services"
        resource_roles = [
            {
              resource = "projects/eogruh-prod/locations/northamerica-northeast1/services/gotenberg"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/c4hnrd-prod/topics/doc-api-app-create-record"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
          ]
      },
      sa-ppr-document-storage = {
        roles       = ["projects/eogruh-prod/roles/CustomStorageAdmin", "roles/iam.serviceAccountTokenCreator"]
        description = "Default service account for ppr cloud services"
      },
      document-pubsub-invoker = {
        roles       = ["roles/pubsub.admin"]
        description = ""
        resource_roles = [
            {
              resource = "projects/eogruh-prod/locations/northamerica-northeast1/services/document-delivery-service"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            }
          ]
      },
      sa-analytics-status-update-not = {
        roles       = ["roles/cloudsql.client", "roles/cloudsql.viewer"]
        description = ""
      },
      bc-ppr-client-direct-docs-prod = {
        roles       = ["projects/eogruh-prod/roles/CustomStorageAdmin", "roles/iam.serviceAccountTokenCreator"]
        description = ""
      }
    }
    pam_bindings = [
     {
       role       = "roleitops"
       role_type = "custom"
     }
   ]
  },
  "search-prod" = {
    project_id = "k973yf-prod"
    env = "prod"
    instances = [
      {
        instance = "search-db-prod"
        databases =  [
              {
                db_name    = "search"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "search_service"
                database_role_assignment = {
                  readonly = ["hrvoje.fekete@gov.bc.ca"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      }
    ]
    service_accounts = {
      sa-pam-function = {
        roles       = ["projects/k973yf-prod/roles/rolepam"]
        description = "Service Account for running PAM entitlement grant and revoke cloud functions"
        resource_roles = [
          {
            resource = "projects/357033077029/secrets/SEARCH_USER_PASSWORD"
            roles    = ["roles/secretmanager.secretAccessor"]
            resource_type = "secret_manager"
          }
        ]
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/k973yf-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/k973yf-prod/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/k973yf-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      gha-wif = {
        roles       = ["roles/compute.admin"]
        description = "Service account used by WIF POC"
        external_roles = [{
          roles        = ["roles/compute.imageUser"]
          project_id  = "k973yf-dev"
        }]
        resource_roles = [
          {
            resource = "projects/k973yf-prod/serviceAccounts/357033077029-compute@developer.gserviceaccount.com"
            roles    = ["roles/iam.serviceAccountUser"]
            resource_type = "sa_iam_member"
          }
        ]
      }
    }
    pam_bindings = [
     {
       role       = "roleitops"
       role_type = "custom"
     }
   ]
  },
  "web-presence-prod" = {
    project_id = "yfthig-prod"
    env = "prod"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/yfthig-prod/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfthig-prod/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfthig-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      github-actions = {
        roles       = ["roles/cloudbuild.builds.editor", "roles/firebaseauth.admin", "roles/firebasehosting.admin", "roles/run.viewer", "roles/serviceusage.apiKeysViewer", "roles/serviceusage.serviceUsageConsumer", "roles/storage.admin"]
        description = "A service account with permission to deploy to Firebase Hosting for the GitHub repository"
      }
    }
  },
  "strr-prod" = {
    project_id = "bcrbk9-prod"
    env = "prod"
    instances = [
      {
        instance = "strr-db-prod"
        databases =  [
          {
                db_name    = "strr-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "strr"
                database_role_assignment = {
                  readonly = ["dietrich.wolpert@gov.bc.ca", "mike.huffman@gov.bc.ca", "anushka.halder@gov.bc.ca",  "sa-strr-analytics@bcrbk9-prod.iam.gserviceaccount.com"]
                  readwrite = []
                  admin = []
                }
              }
            ]
      }
    ]
    custom_roles = {
      rolenotebookuser = {
        title = "Notebook User"
        description = "Role notebook user."
        permissions = [
          "cloudsql.instances.connect",
          "cloudsql.instances.get",
          "serviceusage.services.use"
        ]
      }
    }
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/bigquery.dataOwner", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/bcrbk9-prod/roles/rolejob", "roles/pubsub.publisher"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/bcrbk9-prod/roles/roleapi", "roles/pubsub.publisher", "roles/storage.admin", "roles/storage.objectCreator"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/bcrbk9-prod/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-strr-analytics = {
        roles       = ["projects/bcrbk9-prod/roles/rolenotebookuser", "roles/run.invoker", "roles/cloudsql.instanceUser", "roles/cloudsql.client"]
        external_roles = [{
          roles        = ["roles/cloudsql.instanceUser", "roles/run.serviceAgent", "roles/cloudsql.client"]
          project_id  = "mvnjri-prod"
        }]
        description = "Service Account for running notebooks services"
      }
    }
  },
  "api-gateway-prod" = {
    project_id = "okagqp-prod"
    env = "prod"
    service_accounts = {
      apigee-prod-sa = {
        roles       = ["roles/apigee.developerAdmin", "roles/bigquery.dataEditor", "roles/bigquery.jobUser", "roles/iam.serviceAccountTokenCreator", "roles/logging.admin", "roles/storage.admin"]
        description = "Service account for the BC Registries Apigee prod environment."
        external_roles = [{
          roles        = ["roles/cloudfunctions.invoker"]
          project_id  = "mvnjri-prod"
        }]
        resource_roles = [
            {
              resource = "projects/yfjq17-prod/locations/northamerica-northeast1/services/pam-request-grant-create-bor"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/keee67-prod/locations/northamerica-northeast1/services/pam-request-grant-create-vans-db-prod"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/keee67-prod/locations/northamerica-northeast1/services/pam-request-grant-create-bni-hub"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/gtksf3-prod/locations/northamerica-northeast1/services/pam-request-grant-create-auth-db"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/c4hnrd-prod/locations/northamerica-northeast1/services/pam-request-grant-create-docs"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/c4hnrd-prod/locations/northamerica-northeast1/services/pam-request-grant-create-notify"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-prod/locations/northamerica-northeast1/services/pam-request-grant-create-legal-entities"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-prod/locations/northamerica-northeast1/services/pam-request-grant-create-business-ar"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/k973yf-prod/locations/northamerica-northeast1/services/pam-request-grant-create-search"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/eogruh-prod/locations/northamerica-northeast1/services/pam-request-grant-create-ppr"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/mvnjri-prod/locations/northamerica-northeast1/services/pam-request-grant-create"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            }
          ]
      }
    }
  }
}
