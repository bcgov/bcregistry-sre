other_projects = {
  "common-sandbox" = {
    project_id = "c4hnrd-sandbox"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/c4hnrd-sandbox/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudsql.instanceUser"
        members = ["patrick.wei@gov.bc.ca"]
      },
      {
        role    = "roles/owner"
        members = [
          "max.wardle@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "steven.chen@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "steven.chen@gov.bc.ca",
        ]
      },
    ]
    instances = [
      {
        instance = "notify-db-sandbox"
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
      sa-db-migrate = {
        roles       = ["projects/c4hnrd-sandbox/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/c4hnrd-sandbox/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/c4hnrd-sandbox/roles/roleapi", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/c4hnrd-sandbox/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "connect-sandbox" = {
    project_id = "gtksf3-tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/gtksf3-tools/roles/SRE"
        members = [
          "doug.lovett@gov.bc.ca",
        ]
      },
      {
        role    = "projects/gtksf3-tools/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
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
          "andriy.bolyachevets@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudsql.instanceUser"
        members = ["thor.wolpert@gov.bc.ca"]
      },
      {
        role    = "roles/editor"
        members = [
          "jia.xu@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/owner"
        members = [
          "thor.wolpert@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "siddharth.chaturvedi@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
    ]
    instances = [
      {
        instance = "auth-db-sandbox"
        databases =  [
          {
                db_name    = "auth-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "auth"
                database_role_assignment = {
                  readonly = []
                  readwrite = ["sa-api"]
                  admin = ["sa-db-migrate"]
                }
              }
            ]
      },
      {
        instance = "pay-db-sandbox"
        databases =  [
          {
                db_name    = "pay-db"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "postgres"
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
      sa-db-migrate = {
        roles       = ["projects/gtksf3-tools/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/gtksf3-tools/roles/rolejob"]
        description = "Service Account for running job services"

      },
      sa-api = {
        roles       = ["projects/gtksf3-tools/roles/roleapi", "roles/cloudsql.client", "roles/iam.serviceAccountTokenCreator", "roles/cloudsql.instanceUser", "roles/serverless.serviceAgent"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "auth-account-mailer-sandbox"
              roles    = ["roles/storage.objectViewer"]
              resource_type = "storage_bucket"
            },
            {
              resource = "auth-accounts-sandbox"
              roles    = ["projects/gtksf3-tools/roles/rolestore"]
              resource_type = "storage_bucket"
            },
            {
              resource = "projects/gtksf3-tools/topics/auth-event-sandbox"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/gtksf3-tools/topics/account-mailer-sandbox"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
        ]
      },
      sa-queue = {
        roles       = ["projects/gtksf3-tools/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "bor-sandbox" = {
    project_id = "yfjq17-tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/yfjq17-tools/roles/roledeveloper"
        members = [
          "dietrich.wolpert@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "meng.dong@gov.bc.ca",
        ]
      },
      {
        role    = "roles/artifactregistry.repoAdmin"
        members = [
          "brandon.1.sharratt@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
        ]
      },
      {
        role    = "roles/owner"
        members = [
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "hrvoje.fekete@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "hrvoje.fekete@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
        ]
      },
    ]
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/yfjq17-tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfjq17-tools/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/yfjq17-tools/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      btr-cd = {
        roles       = ["roles/editor"]
        description = ""
      },
      sa-solr-importer = {
        roles       = ["projects/yfjq17-tools/roles/rolesolrimporter"]
        description = "Service Account for solr importer services"
      }
    }
  },
  "bcr-businesses-tools" = {
    project_id = "a083gt-tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/a083gt-tools/roles/SRE"
        members = [
          "doug.lovett@gov.bc.ca",
        ]
      },
      {
        role    = "projects/a083gt-tools/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "doug.lovett@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/owner"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
    ]
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/a083gt-tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-tools/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/a083gt-tools/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-solr-importer = {
        roles       = ["projects/a083gt-tools/roles/rolesolrimporter"]
        description = "Service Account for solr importer services"
      }
    }
  },
  "business-number-hub-sandbox" = {
    project_id = "keee67-tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "roles/securitycenter.assetsViewer"
        members = ["andriy.bolyachevets@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = ["andriy.bolyachevets@gov.bc.ca"]
      },
    ]
  },
  "ppr-sandbox" = {
    project_id = "eogruh-sandbox"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/eogruh-sandbox/roles/roledeveloper"
        members = [
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "meng.dong@gov.bc.ca",
        ]
      },
      {
        role    = "roles/resourcemanager.projectOwnerInvitee"
        members = ["patrick.wei@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
        ]
      },
    ]
    instances = [
      {
        instance = "ppr-sandbox-pgdb"
        databases =  [
              {
                db_name    = "ppr"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "user4ca"
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
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/eogruh-sandbox/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/eogruh-sandbox/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/eogruh-sandbox/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      ppr-sandbox-sa = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.admin", "roles/storage.admin"]
        description = "Default service account for ppr cloud services"
      }
    }
  },
  "search-sandbox" = {
    project_id = "k973yf--tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "roles/editor"
        members = ["patrick.wei@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = ["patrick.wei@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = ["patrick.wei@gov.bc.ca"]
      },
    ]
    instances = [
      {
        instance = "search-db-integration"
        databases =  [
              {
                db_name    = "search"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "int_user"
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
        roles       = ["projects/k973yf--tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/k973yf--tools/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/k973yf--tools/roles/rolequeue"]
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
            resource = "projects/k973yf--tools/serviceAccounts/854458797060-compute@developer.gserviceaccount.com"
            roles    = ["roles/iam.serviceAccountUser"]
            resource_type = "sa_iam_member"
          }
        ]
      }
    }
  },
  "web-presence-sandbox" = {
    project_id = "yfthig-tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/yfthig-tools/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
        ]
      },
      {
        role    = "roles/owner"
        members = [
          "max.wardle@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "steven.chen@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "max.wardle@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
          "steven.chen@gov.bc.ca",
        ]
      },
    ]
    service_accounts = {
      sa-job = {
        roles       = ["projects/yfthig-tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfthig-tools/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-cdcloudrun = {
        roles       = ["projects/yfthig-tools/roles/rolecdcloudrun"]
        description = "Service Account for running cdcloudrun services"
      }
    }
  },
  "strr-sandbox" = {
    project_id = "bcrbk9-tools"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/bcrbk9-tools/roles/roledeveloper"
        members = [
          "dietrich.wolpert@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
        ]
      },
      {
        role    = "roles/owner"
        members = [
          "max.wardle@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "max.wardle@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "max.wardle@gov.bc.ca",
          "patrick.wei@gov.bc.ca",
        ]
      },
    ]
    instances = [
      {
        instance = "strr-db-sandbox"
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
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-db-migrate = {
        roles       = ["projects/bcrbk9-tools/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-job = {
        roles       = ["projects/bcrbk9-tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/bcrbk9-tools/roles/roleapi", "roles/storage.admin"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/bcrbk9-tools/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  },
  "api-gateway-sandbox" = {
    project_id = "okagqp-sandbox"
    env = "sandbox"
    iam_bindings = [
    ]
    service_accounts = {
      apigee-sandbox-sa = {
        roles       = ["roles/apigee.developerAdmin", "roles/bigquery.dataEditor", "roles/bigquery.jobUser", "roles/iam.serviceAccountTokenCreator", "roles/logging.admin", "roles/storage.admin"]
        description = "Service account for the BC Registries Apigee sandbox/uat environment."
      }
    }
  },
  "bcr-businesses-sandbox" = {
    project_id = "a083gt-integration"
    env = "sandbox"
    iam_bindings = [
      {
        role    = "projects/a083gt-integration/roles/cloud_sql_proxy_user"
        members = ["john.a.m.lane@gov.bc.ca"]
      },
      {
        role    = "projects/a083gt-integration/roles/roledeveloper"
        members = [
          "chiu.oddyseus@gov.bc.ca",
          "david.mckinnon@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "lucas.o'neil@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudsql.client"
        members = ["john.a.m.lane@gov.bc.ca"]
      },
      {
        role    = "roles/cloudsql.viewer"
        members = ["john.a.m.lane@gov.bc.ca"]
      },
      {
        role    = "roles/editor"
        members = ["vysakh.menon@gov.bc.ca"]
      },
      {
        role    = "roles/iam.serviceAccountTokenCreator"
        members = ["andriy.bolyachevets@gov.bc.ca"]
      },
      {
        role    = "roles/iam.serviceAccountUser"
        members = [
          "hongjing.chen@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
        ]
      },
      {
        role    = "roles/owner"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
        ]
      },
      {
        role    = "roles/pubsub.admin"
        members = [
          "hongjing.chen@gov.bc.ca",
          "travis.semple@gov.bc.ca",
        ]
      },
      {
        role    = "roles/pubsub.editor"
        members = ["ketaki.deodhar@gov.bc.ca"]
      },
      {
        role    = "roles/run.admin"
        members = [
          "hongjing.chen@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "john.a.m.lane@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "steven.chen@gov.bc.ca",
        ]
      },
      {
        role    = "roles/securitycenter.findingsViewer"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "john.a.m.lane@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "steven.chen@gov.bc.ca",
        ]
      },
      {
        role    = "roles/storage.objectUser"
        members = ["ketaki.deodhar@gov.bc.ca"]
      },
    ]
    instances = [
      {
        instance = "businesses-db-integration"
        databases =  [
              {
                db_name    = "businesses"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "business_app"
                database_role_assignment = {
                  readonly = ["sa-solr-importer"]
                  readwrite = ["sa-job", "sa-api"]
                  admin = []
                }
              }
            ]
      },
      {
        instance = "namex-db-integration"
        databases = [
          {
                db_name    = "namex"
                roles      = ["readonly", "readwrite", "admin"]
                owner      = "userHQH"
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
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/a083gt-integration/roles/rolejob", "roles/cloudsql.client", "roles/cloudsql.instanceUser"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-integration/roles/roleapi", "roles/iam.serviceAccountTokenCreator", "roles/cloudtasks.enqueuer", "roles/cloudtasks.viewer", "roles/cloudtasks.taskDeleter", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
        description = "Service Account for running api services"
        resource_roles = [
            {
              resource = "projects/a083gt-prod/locations/northamerica-northeast1/services/namex-solr-synonyms-api-prod"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-integration/locations/northamerica-northeast1/services/namex-api-sandbox"
              roles    = ["roles/run.invoker"]
              resource_type = "cloud_run"
            },
            {
              resource = "projects/a083gt-integration/topics/namex-emailer-sandbox"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            },
            {
              resource = "projects/a083gt-integration/topics/namex-nr-state-sandbox"
              roles    = ["roles/pubsub.publisher"]
              resource_type = "pubsub_topic"
            }
          ]
      },
      sa-queue = {
        roles       = ["projects/a083gt-integration/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      sa-cdcloudrun = {
        roles       = ["projects/a083gt-integration/roles/rolecdcloudrun"]
        description = "Service Account for running cdcloudrun services"
      },
      sa-db-migrate = {
        roles       = ["projects/a083gt-integration/roles/roledbmigrate"]
        description = "Service Account for running db alembic migration job"
      },
      sa-lear-migrate = {
        roles       = ["projects/a083gt-integration/roles/roleapi", "roles/cloudsql.client", "roles/cloudsql.admin"]
        description = "Service Account for migrating db from openshift"
        resource_roles = [
            { resource = "projects/358864940488/secrets/OC_TOKEN_cc892f-sandbox"
              roles    = ["roles/secretmanager.secretAccessor"]
              resource_type = "secret_manager"
            },
            {
              resource = "lear-db-dump-sandbox"
              roles    = ["roles/storage.admin"]
              resource_type = "storage_bucket"
            }
          ]
      },
        sa-solr-importer = {
          roles       = ["projects/a083gt-integration/roles/rolesolrimporter"]
          description = "Service Account for solr importer services"
      }
    }
  },
  "common-tools" = {
    project_id = "c4hnrd-tools"
    env = "tools"
    iam_bindings = [
      {
        role    = "projects/c4hnrd-tools/roles/SRE"
        members = [
          "kial.jinnah@gov.bc.ca",
        ]
      },
      {
        role    = "projects/c4hnrd-tools/roles/roledeveloper"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "brandon.1.sharratt@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "dietrich.wolpert@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "hrvoje.fekete@gov.bc.ca",
          "jia.xu@gov.bc.ca",
          "karim.jazzar@gov.bc.ca",
          "ketaki.deodhar@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "meng.dong@gov.bc.ca",
          "omid.x.zamani@gov.bc.ca",
          "rajandeep.kaur@gov.bc.ca",
          "severin.beauvais@gov.bc.ca",
          "steven.chen@gov.bc.ca",
          "syed.riyazzudin@gov.bc.ca",
          "thayne.werdal@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vishnu.preddy@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/artifactregistry.admin"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "travis.semple@gov.bc.ca",
          "vysakh.menon@gov.bc.ca",
        ]
      },
      {
        role    = "roles/artifactregistry.reader"
        members = [
          "anish.batra@gov.bc.ca",
          "brandon.1.sharratt@gov.bc.ca",
          "jia.xu@gov.bc.ca",
        ]
      },
      {
        role    = "roles/cloudasset.owner"
        members = ["anish.patel@gov.bc.ca"]
      },
      {
        role    = "roles/securitycenter.assetsViewer"
        members = [
          "Argus.1.Chiu@gov.bc.ca",
          "Chris.Gabel@gov.bc.ca",
          "chiu.oddyseus@gov.bc.ca",
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
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
          "eve.deng@gov.bc.ca",
          "hongjing.chen@gov.bc.ca",
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
    custom_roles = {
      cdcloudbuild = {
        title = "CD Cloud Build"
        description = "Role for cloud deploy CD flow."
        permissions = [
          "artifactregistry.tags.list",
          "artifactregistry.tags.update",
          "resourcemanager.projects.get",
          "iam.serviceAccounts.actAs",
          "secretmanager.versions.access",
          "cloudbuild.builds.create",
          "cloudbuild.builds.get",
          "storage.buckets.get",
          "storage.buckets.list",
          "storage.buckets.create",
          "storage.buckets.delete",
          "storage.objects.create",
          "storage.objects.get",
          "storage.objects.delete",
          "storage.objects.list",
          "artifactregistry.repositories.downloadArtifacts",
          "artifactregistry.repositories.get",
          "artifactregistry.repositories.uploadArtifacts",
          "artifactregistry.tags.create",
          "artifactregistry.tags.delete",
          "artifactregistry.tags.get",
          "serviceusage.services.get"
        ]
      },
      cdclouddeploy = {
        title = "CD Cloud Deploy"
        description = "Role for cloud deploy CD flow."
        permissions = [
          "resourcemanager.projects.get",
          "cloudbuild.builds.create",
          "cloudbuild.builds.get",
          "cloudbuild.builds.list",
          "iam.serviceAccounts.actAs",
          "pubsub.topics.publish",
          "serviceusage.services.use",
          "storage.buckets.create",
          "storage.buckets.get",
          "storage.buckets.delete",
          "clouddeploy.config.get",
          "clouddeploy.deliveryPipelines.create",
          "clouddeploy.deliveryPipelines.get",
          "clouddeploy.deliveryPipelines.list",
          "clouddeploy.deliveryPipelines.update",
          "clouddeploy.jobRuns.get",
          "clouddeploy.jobRuns.list",
          "clouddeploy.jobRuns.terminate",
          "clouddeploy.locations.get",
          "clouddeploy.locations.list",
          "clouddeploy.operations.cancel",
          "clouddeploy.operations.get",
          "clouddeploy.operations.list",
          "clouddeploy.releases.abandon",
          "clouddeploy.releases.create",
          "clouddeploy.releases.get",
          "clouddeploy.releases.list",
          "clouddeploy.rollouts.advance",
          "clouddeploy.rollouts.cancel",
          "clouddeploy.rollouts.create",
          "clouddeploy.rollouts.get",
          "clouddeploy.rollouts.ignoreJob",
          "clouddeploy.rollouts.list",
          "clouddeploy.rollouts.retryJob",
          "clouddeploy.rollouts.rollback",
          "clouddeploy.targets.create",
          "clouddeploy.targets.get",
          "clouddeploy.targets.getIamPolicy",
          "clouddeploy.targets.list",
          "clouddeploy.targets.update",
          "logging.logEntries.create",
          "run.executions.cancel",
          "run.executions.get",
          "run.executions.list",
          "run.jobs.get",
          "run.jobs.list",
          "run.jobs.run",
          "run.locations.list",
          "run.operations.get",
          "run.operations.list",
          "run.revisions.get",
          "run.revisions.list",
          "run.routes.get",
          "run.routes.list",
          "run.services.get",
          "run.services.list",
          "run.tasks.get",
          "run.tasks.list",
          "source.repos.get",
          "source.repos.list"
        ]
      }
    }
    service_accounts = {
      sa-compliance-scanner = {
        roles       = ["projects/c4hnrd-tools/roles/rolejob"]
        description = "Service Account for compliance scanning job"
        resource_roles = [
            {
              resource = "gcp-residency-compliance-checker-reports"
              roles    = ["roles/storage.admin"]
              resource_type = "storage_bucket"
            }
          ]
      },
      sa-cloud-function-sql-manager = {
        description = "Service Account for running cloudsql updates"
        external_roles = [{
          roles      = ["roles/cloudsql.admin"]
          project_id = "a083gt-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "a083gt-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "a083gt-integration"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "a083gt-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "mvnjri-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "c4hnrd-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "c4hnrd-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "c4hnrd-sandbox"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "c4hnrd-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "c4hnrd-tools"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "gtksf3-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "gtksf3-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "gtksf3-tools"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "gtksf3-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "yfjq17-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "yfjq17-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "yfjq17-tools"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "yfjq17-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "keee67-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "keee67-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "keee67-tools"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "keee67-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "eogruh-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "eogruh-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "eogruh-sandbox"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "eogruh-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "k973yf-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "k973yf-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "k973yf--tools"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "k973yf-prod"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "bcrbk9-dev"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "bcrbk9-test"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "bcrbk9-tools"
        },
        {
          roles      = ["roles/cloudsql.admin"]
          project_id = "bcrbk9-prod"
        }
      ]
        resource_roles = [
            {
              resource = "common-tools-sql"
              roles    = ["roles/storage.objectAdmin"]
              resource_type = "storage_bucket"
            }
          ]
      },
      sa-job = {
        roles       = ["projects/c4hnrd-tools/roles/rolejob", "projects/c4hnrd-tools/roles/cdcloudrun"]
        description = "Service Account for running job services"
      },
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-api = {
        roles       = ["projects/c4hnrd-tools/roles/roleapi", "roles/cloudtrace.agent"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/c4hnrd-tools/roles/rolequeue"]
        description = "Service Account for running queue services"
      },
      github-actions = {
        roles       = ["projects/c4hnrd-tools/roles/cdcloudbuild", "projects/c4hnrd-tools/roles/cdclouddeploy", "roles/cloudbuild.builds.builder", "roles/cloudbuild.builds.editor", "roles/iam.serviceAccountTokenCreator", "roles/iam.serviceAccountUser", "roles/run.developer", "roles/run.viewer", "roles/storage.admin"]
        description = "A service account with permission to deploy from GitHub repository"
        resource_roles = [
          {
            resource = "projects/c4hnrd-tools/serviceAccounts/github-actions@c4hnrd-tools.iam.gserviceaccount.com"
            roles    = ["roles/cloudbuild.serviceAgent"]
            resource_type = "sa_iam_member"
          }
        ]
      }
    }
  }
}
