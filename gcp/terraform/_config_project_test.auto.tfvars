test_projects = {
  "common-test" = {
    project_id = "c4hnrd-test"
    env = "test"
    iam_bindings = [
      {
        role    = "projects/c4hnrd-test/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "brandon.1.sharratt@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "projects/c4hnrd-test/roles/SRE"
        members = [
            "eve.deng@gov.bc.ca",
            "travis.semple@gov.bc.ca",
            "doug.lovett@gov.bc.ca",
        ]
      },
      {
        role    = "roles/run.admin"
        members = ["doug.lovett@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
    ]
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
    iam_bindings = [
      {
        role    = "projects/gtksf3-test/roles/SRE"
        members = [
          "doug.lovett@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "projects/gtksf3-test/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "anish.batra@gov.bc.ca",
          "brandon.1.sharratt@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "felipe.moraes@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "lucas.o'neil@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patty.stemkens@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudsql.admin"
        members = [
          "jia.xu@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
        ]
      },
      {
        role    = "roles/iam.serviceAccountUser"
        members = ["anish.batra@gov.bc.ca"]
      },
      {
        role    = "roles/pubsub.admin"
        members = ["jia.xu@gov.bc.ca"]
      },
      {
        role    = "roles/pubsub.editor"
        members = ["chiu.oddyseus@gov.bc.ca"]
      },
      {
        role    = "roles/run.admin"
        members = ["anish.batra@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
    ]
    resource_iam_bindings = [
      {
        resource      = "auth-static-resources-test"
        resource_type = "storage_bucket"
        roles         = ["roles/storage.objectUser"]
        members       = [
          "jia.xu@gov.bc.ca"
          ]
      },
    ]
    
    instances = [
      {
        instance = "auth-db-test"
        databases =  [
          {
                db_name    = "auth-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "auth"
                database_role_assignment = {
                  readonly = ["syed.riyazzudin@gov.bc.ca", "noor.nayeem@gov.bc.ca", "patty.stemkens@gov.bc.ca"]
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
                  readonly = ["noor.nayeem@gov.bc.ca", "patty.stemkens@gov.bc.ca"]
                  readwrite = ["sa-api", "anish.batra@gov.bc.ca"]
                  admin = ["sa-db-migrate"]
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
    iam_bindings = [
      {
        role    = "projects/yfjq17-test/roles/rolecdcloudrun"
        members = [
          "brandon.1.sharratt@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
        ]
      },
      {
        role    = "projects/yfjq17-test/roles/roledeveloper"
        members = [
          "brandon.1.sharratt@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "gunasegaran.nagarajan@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
          "meng.dong@gov.bc.ca",
        ]
      },
      {
        role    = "projects/yfjq17-test/roles/SRE"
        members = [
          "kial.jinnah@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "hrvoje.fekete@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "hrvoje.fekete@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
        ]
      },
    ]
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
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
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
      sa-db-migrate = {
        roles       = ["projects/yfjq17-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
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
    iam_bindings = [
      {
        role    = "projects/a083gt-test/roles/SRE"
        members = [
          "doug.lovett@gov.bc.ca",
          "Argus.1.Chiu@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "projects/a083gt-test/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "brandon.1.sharratt@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "darci.denis@gov.bc.ca",
          "david.li@gov.bc.ca",
          "david.mckinnon@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "felipe.moraes@gov.bc.ca",
          "gunasegaran.nagarajan@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "lucas.o'neil@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vikas.singh@gov.bc.ca",
          "vishnu.preddy@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudsql.instanceUser"
        members = ["anish.patel@gov.bc.ca"]
      },
      {
        role    = "roles/cloudtasks.viewer"
        members = ["felipe.moraes@gov.bc.ca"]
      },
      {
        role    = "roles/iam.serviceAccountUser"
        members = ["steven.chen@gov.bc.ca"]
      },
      {
        role    = "roles/pubsub.admin"
        members = [
          "brandon.1.sharratt@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "lucas.o'neil@gov.bc.ca",
        ]
      },
      {
        role    = "roles/run.admin"
        members = ["steven.chen@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "darci.denis@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "darci.denis@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
    ]
    instances = [
      {
        instance = "businesses-db-test"
        databases =  [
              {
                db_name    = "business"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "business-api"
                database_role_assignment = {
                  readonly = ["sa-solr-importer"]
                  readwrite = ["syed.riyazzudin@gov.bc.ca", "sa-job", "sa-api"]
                  admin = ["sa-db-migrate"]
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
                  readonly = ["syed.riyazzudin@gov.bc.ca", "vishnu.preddy@gov.bc.ca", "sa-solr-importer"]
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
    iam_bindings = [
      {
        role    = "roles/secretmanager.secretAccessor"
        members = ["thor.wolpert@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = ["patty.stemkens@gov.bc.ca"]
      },
      {
        role    = "projects/keee67-test/roles/roledeveloper"
        members = [
          "patty.stemkens@gov.bc.ca"
        ]
      },
    ]
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
    iam_bindings = [
      {
        role    = "projects/eogruh-test/roles/roledeveloper"
        members = [
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
          "meng.dong@gov.bc.ca",
        ]
      },
      {
        role    = "projects/eogruh-test/roles/SRE"
        members = [
          "doug.lovett@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [ 
          "doug.lovett@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [ 
          "doug.lovett@gov.bc.ca",
        ]
      },
    ]
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
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
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
      sa-db-migrate = {
        roles       = ["projects/eogruh-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
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
    iam_bindings = [
      {
        role    = "projects/k973yf-test/roles/roledeveloper"
        members = [
          "gunasegaran.nagarajan@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
        ]
      },
      {
        role    = "roles/artifactregistry.admin"
        members = ["hrvoje.fekete@gov.bc.ca"]
      },
      {
        role    = "roles/iam.serviceAccountUser"
        members = ["hrvoje.fekete@gov.bc.ca"]
      },
      {
        role    = "roles/run.admin"
        members = ["hrvoje.fekete@gov.bc.ca"]
      },
      {
        role    = "roles/run.sourceDeveloper"
        members = ["hrvoje.fekete@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "hrvoje.fekete@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "hrvoje.fekete@gov.bc.ca",
        ]
      },
      {
        role    = "projects/k973yf-test/roles/SRE"
        members = [
          "kial.jinnah@gov.bc.ca",
        ]
      },
    ]
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
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
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
      sa-db-migrate = {
        roles       = ["projects/k973yf-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
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
    iam_bindings = [
      {
        role    = "projects/yfthig-test/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "brandon.1.sharratt@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "projects/yfthig-test/roles/SRE"
        members = [
          "omid.x.zamani@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
        ]
      },
      {
        role    = "roles/firebase.admin"
        members = [
          "eve.deng@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
    ]
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
    iam_bindings = [
      {
        role    = "projects/bcrbk9-test/roles/roledeveloper"
        members = [
          "dietrich.wolpert@gov.bc.ca",
          "janis.rogers@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudsql.instanceUser"
        members = ["andriy.bolyachevets@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
    ]
    instances = [
      {
        instance = "strr-db-test"
        databases =  [
          {
                db_name    = "strr-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "strr"
                database_role_assignment = {
                  readonly = ["sa-job"]
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
      sa-db-migrate = {
        roles       = ["projects/bcrbk9-test/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
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
    iam_bindings = [
      {
        role    = "projects/okagqp-test/roles/roledeveloper"
        members = ["travis.semple@gov.bc.ca"]
      },
      {
        role    = "projects/okagqp-test/roles/SRE"
        members = [
          "doug.lovett@gov.bc.ca",
        ]
      },
      {
        role    = "roles/apigee.admin"
        members = [
          "doug.lovett@gov.bc.ca",
        ]
      },
    ]
    service_accounts = {
      apigee-test-sa = {
        roles       = ["roles/apigee.apiAdminV2", "roles/apigee.developerAdmin", "roles/logging.admin", "roles/logging.serviceAgent", "roles/storage.admin"]
        description = "Service account for apigee gateway integration including logging"
      }
    }
  }
}
