projects = {
  "analytics-int-prod" = {
    project_id = "mvnjri-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
    #     description = "Service Account for running pubsub services	"
    #   },
    #   sa-job = {
    #     roles       = ["projects/mvnjri-prod/roles/roleapi"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/mvnjri-prod/roles/rolejob"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/mvnjri-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "common-prod" = {
    project_id = "c4hnrd-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["projects/c4hnrd-prod/roles/rolequeue", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/c4hnrd-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/c4hnrd-prod/roles/roleapi", "roles/cloudsql.instanceUser", "roles/run.serviceAgent"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/c4hnrd-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "connect-prod" = {
    project_id = "gtksf3-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/gtksf3-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/gtksf3-prod/roles/roleapi", "roles/cloudsql.client"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/gtksf3-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "bor-prod" = {
    project_id = "yfjq17-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/yfjq17-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/yfjq17-prod/roles/roleapi"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/yfjq17-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "bcr-businesses-prod" = {
    project_id = "a083gt-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/a083gt-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/a083gt-prod/roles/roleapi"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/a083gt-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "business-number-hub-prod" = {
    project_id = "keee67-prod"
    env = "prod"
  }
  "ppr-prod" = {
    project_id = "eogruh-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/eogruh-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   }
    #   sa-api = {
    #     roles       = ["projects/eogruh-prod/roles/roleapi"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/eogruh-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "search-prod" = {
    project_id = "k973yf-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/k973yf-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/k973yf-prod/roles/roleapi"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/k973yf-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "web-presence-prod" = {
    project_id = "yfthig-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/yfthig-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/yfthig-prod/roles/roleapi"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/yfthig-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "strr-prod" = {
    project_id = "bcrbk9-prod"
    env = "prod"
    # service_accounts = {
    #   sa-pubsub = {
    #     roles       = ["roles/bigquery.dataOwner", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
    #     description = "Service Account for running pubsub services"
    #   },
    #   sa-job = {
    #     roles       = ["projects/bcrbk9-prod/roles/rolejob"]
    #     description = "Service Account for running job services"
    #   },
    #   sa-api = {
    #     roles       = ["projects/bcrbk9-prod/roles/roleapi"]
    #     description = "Service Account for running api services"
    #   },
    #   sa-queue = {
    #     roles       = ["projects/bcrbk9-prod/roles/rolequeue"]
    #     description = "Service Account for running queue services"
    #   }
    # }
  }
  "analytics-ext-prod" = {
    project_id = "sbgmug-prod"
    env = "prod"
  }
  "api-gateway-prod" = {
    project_id = "okagqp-prod"
    env = "prod"
  }
  "common-test" = {
    project_id = "c4hnrd-test"
    env = "test"
    service_accounts = {
      sa-pubsub = {
        roles       = ["projects/c4hnrd-test/roles/rolequeue", "roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
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
      }
    }
  }
  "connect-test" = {
    project_id = "gtksf3-test"
    env = "test"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/gtksf3-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/gtksf3-test/roles/roleapi", "roles/cloudsql.client"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/gtksf3-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  }
  "bor-test" = {
    project_id = "yfjq17-test"
    env = "test"
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
      }
    }
  }
  "bcr-businesses-test" = {
    project_id = "a083gt-test"
    env = "test"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/a083gt-test/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-test/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/a083gt-test/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  }
  "business-number-hub-test" = {
    project_id = "keee67-test"
    env = "test"
  }
  "ppr-test" = {
    project_id = "eogruh-test"
    env = "test"
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
      }
    }
  }
  "search-test" = {
    project_id = "k973yf-test"
    env = "test"
  }
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
      }
    }
  }
  "strr-test" = {
    project_id = "bcrbk9-test"
    env = "test"
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
  }
  "analytics-ext-test" = {
    project_id = "sbgmug-test"
    env = "test"
  }
  "api-gateway-test" = {
    project_id = "okagqp-test"
    env = "test"
  }
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
  }
  "common-dev" = {
    project_id = "c4hnrd-dev"
    env = "dev"
    service_accounts = {
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
      }
    }
  }
  "connect-dev" = {
    project_id = "gtksf3-dev"
    env = "dev"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/gtksf3-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/gtksf3-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/gtksf3-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  }
  "bor-dev" = {
    project_id = "yfjq17-dev"
    env = "dev"
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
      }
    }
  }
  "bcr-businesses-dev" = {
    project_id = "a083gt-dev"
    env = "dev"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/a083gt-dev/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-dev/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/a083gt-dev/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  }
  "business-number-hub-dev" = {
    project_id = "keee67-dev"
    env = "dev"
  }
  "ppr-dev" = {
    project_id = "eogruh-dev"
    env = "dev"
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
      }
    }
  }
  "search-dev" = {
    project_id = "k973yf-dev"
    env = "dev"
  }
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
      }
    }
  }
  "strr-dev" = {
    project_id = "bcrbk9-dev"
    env = "dev"
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
      }
    }
  }
  "analytics-ext-dev" = {
    project_id = "sbgmug-dev"
    env = "dev"
  }
  "api-gateway-dev" = {
    project_id = "okagqp-dev"
    env = "dev"
  }
  "common-sandbox" = {
    project_id = "c4hnrd-sandbox"
    env = "sandbox"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/c4hnrd-sandbox/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/c4hnrd-sandbox/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/c4hnrd-sandbox/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  }
  "connect-sandbox" = {
    project_id = "gtksf3-tools"
    env = "sandbox"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/gtksf3-tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/gtksf3-tools/roles/roleapi", "roles/cloudsql.client"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/gtksf3-tools/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
  }
  "bor-sandbox" = {
    project_id = "yfjq17-tools"
    env = "sandbox"
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
      }
    }
  }
  "bcr-businesses-tools" = {
    project_id = "a083gt-tools"
    env = "sandbox"
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
      }
    }
  }
  "business-number-hub-sandbox" = {
    project_id = "keee67-tools"
    env = "sandbox"
  }
  "ppr-sandbox" = {
    project_id = "eogruh-sandbox"
    env = "sandbox"
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
      }
    }
  }
  "search-sandbox" = {
    project_id = "k973yf--tools"
    env = "sandbox"
  }
  "web-presence-sandbox" = {
    project_id = "yfthig-tools"
    env = "sandbox"
    service_accounts = {
      sa-job = {
        roles       = ["projects/yfthig-tools/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/yfthig-tools/roles/roleapi"]
        description = "Service Account for running api services"
      }
    }
  }
  "strr-sandbox" = {
    project_id = "bcrbk9-tools"
    env = "sandbox"
    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber"]
        description = "Service Account for running pubsub services"
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
  }
  "analytics-ext-sandbox" = {
    project_id = "sbgmug-sandbox"
    env = "sandbox"
  }
  "api-gateway-sandbox" = {
    project_id = "okagqp-sandbox"
    env = "sandbox"
  }
  "bcr-businesses-sandbox" = {
    project_id = "a083gt-integration"
    env = "sandbox"

    service_accounts = {
      sa-pubsub = {
        roles       = ["roles/iam.serviceAccountTokenCreator", "roles/pubsub.publisher", "roles/pubsub.subscriber", "roles/run.invoker"]
        description = "Service Account for running pubsub services"
      },
      sa-job = {
        roles       = ["projects/a083gt-integration/roles/rolejob"]
        description = "Service Account for running job services"
      },
      sa-api = {
        roles       = ["projects/a083gt-integration/roles/roleapi"]
        description = "Service Account for running api services"
      },
      sa-queue = {
        roles       = ["projects/a083gt-integration/roles/rolequeue"]
        description = "Service Account for running queue services"
      }
    }
    custom_roles = {
      # "testTFRole2" = {
      #   permissions = ["run.routes.list"]
      #   description  = ""
      # }
    }
  }
  "common-tools" = {
    project_id = "c4hnrd-tools"
    env = "tools"
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
      }
    }
  }

}

environments = {
  "sandbox" = {
    environment_service_accounts = {
      # sa-job = {
      #   roles       = ["roles/rolejob"]
      #   description = "Service Account for running pubsub services"
      # }
    }

    environment_custom_roles = {
      roledeveloper = {
        title = "Role Developer"
        description = "Role for Developer."
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.get",
          "serviceusage.services.list",
          "storage.managedFolders.get",
          "storage.objects.get",
          "storage.objects.list",
          "storage.buckets.get",
          "storage.buckets.list",
          "artifactregistry.repositories.get",
          "artifactregistry.tags.get",
          "run.locations.list",
          "run.operations.get",
          "run.operations.list",
          "run.revisions.get",
          "run.revisions.list",
          "run.executions.get",
          "run.executions.list",
          "run.services.get",
          "run.services.list",
          "run.routes.get",
          "run.routes.list",
          "run.jobs.get",
          "run.jobs.list",
          "run.jobs.run",
          "appengine.applications.get",
          "cloudscheduler.jobs.enable",
          "cloudscheduler.jobs.fullView",
          "cloudscheduler.jobs.get",
          "cloudscheduler.jobs.list",
          "cloudscheduler.jobs.pause",
          "cloudscheduler.jobs.run",
          "cloudscheduler.locations.get",
          "cloudscheduler.locations.list",
          "pubsub.topics.get",
          "pubsub.topics.list",
          "pubsub.topics.publish",
          "pubsub.subscriptions.list",
          "pubsub.snapshots.list",
          "monitoring.dashboards.get",
          "monitoring.timeSeries.list",
          "logging.exclusions.get",
          "logging.exclusions.list",
          "logging.links.get",
          "logging.links.list",
          "logging.logEntries.list",
          "logging.logMetrics.get",
          "logging.logMetrics.list",
          "logging.logs.list",
          "logging.operations.get",
          "logging.operations.list",
          "logging.queries.create",
          "logging.queries.delete",
          "logging.queries.get",
          "logging.queries.list",
          "logging.queries.listShared",
          "logging.queries.update",
          "logging.views.get",
          "logging.views.list",
          "cloudsql.databases.get",
          "cloudsql.databases.list",
          "cloudsql.instances.get",
          "cloudsql.instances.list",
          "cloudsql.instances.connect",
          "cloudsql.instances.executeSql",
          "cloudsql.users.get",
          "cloudsql.users.list",
          "cloudbuild.builds.get",
          "cloudbuild.builds.list",
          "cloudbuild.connections.list",
          "cloudbuild.repositories.list",
          "clouddeploy.config.get",
          "clouddeploy.deliveryPipelines.get",
          "clouddeploy.deliveryPipelines.list",
          "clouddeploy.jobRuns.get",
          "clouddeploy.jobRuns.list",
          "clouddeploy.locations.get",
          "clouddeploy.locations.list",
          "clouddeploy.operations.get",
          "clouddeploy.operations.list",
          "clouddeploy.releases.get",
          "clouddeploy.releases.list",
          "clouddeploy.rollouts.get",
          "clouddeploy.rollouts.list",
          "clouddeploy.targets.get",
          "clouddeploy.targets.list",
          "firebase.clients.get",
          "firebase.clients.list",
          "firebase.projects.get",
          "firebasehosting.sites.get",
          "firebasehosting.sites.list",
          "cloudconfig.configs.get",
          "cloudconfig.configs.update"
        ]
      }
    }
  }
  "dev" = {
    environment_custom_roles = {
      roledeveloper = {
        title = "Role Developer"
        description = "Role for Developer."
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.get",
          "serviceusage.services.list",
          "artifactregistry.repositories.get",
          "artifactregistry.tags.get",
          "cloudbuild.builds.get",
          "cloudbuild.builds.list",
          "cloudbuild.connections.list",
          "cloudbuild.repositories.list",
          "cloudconfig.configs.get",
          "cloudconfig.configs.update",
          "clouddeploy.config.get",
          "clouddeploy.deliveryPipelines.get",
          "clouddeploy.deliveryPipelines.list",
          "clouddeploy.jobRuns.get",
          "clouddeploy.jobRuns.list",
          "clouddeploy.locations.get",
          "clouddeploy.locations.list",
          "clouddeploy.operations.get",
          "clouddeploy.operations.list",
          "clouddeploy.releases.get",
          "clouddeploy.releases.list",
          "clouddeploy.rollouts.get",
          "clouddeploy.rollouts.list",
          "clouddeploy.targets.get",
          "clouddeploy.targets.list",
          "appengine.applications.get",
          "cloudscheduler.jobs.create",
          "cloudscheduler.jobs.delete",
          "cloudscheduler.jobs.enable",
          "cloudscheduler.jobs.fullView",
          "cloudscheduler.jobs.get",
          "cloudscheduler.jobs.list",
          "cloudscheduler.jobs.pause",
          "cloudscheduler.jobs.run",
          "cloudscheduler.jobs.update",
          "cloudscheduler.locations.get",
          "cloudscheduler.locations.list",
          "cloudsql.databases.get",
          "cloudsql.databases.list",
          "cloudsql.instances.get",
          "cloudsql.instances.list",
          "cloudsql.instances.connect",
          "cloudsql.instances.executeSql",
          "cloudsql.users.get",
          "cloudsql.users.list",
          "cloudtrace.traces.get",
          "firebase.clients.get",
          "firebase.clients.list",
          "firebase.projects.get",
          "firebasehosting.sites.get",
          "firebasehosting.sites.list",
          "logging.exclusions.get",
          "logging.exclusions.list",
          "logging.links.get",
          "logging.links.list",
          "logging.logEntries.list",
          "logging.logMetrics.get",
          "logging.logMetrics.list",
          "logging.logs.list",
          "logging.operations.get",
          "logging.operations.list",
          "logging.queries.create",
          "logging.queries.delete",
          "logging.queries.get",
          "logging.queries.list",
          "logging.queries.listShared",
          "logging.queries.update",
          "logging.views.get",
          "logging.views.list",
          "monitoring.dashboards.get",
          "monitoring.timeSeries.list",
          "pubsub.snapshots.list",
          "pubsub.subscriptions.consume",
          "pubsub.subscriptions.create",
          "pubsub.subscriptions.delete",
          "pubsub.subscriptions.get",
          "pubsub.subscriptions.list",
          "pubsub.subscriptions.update",
          "pubsub.topics.attachSubscription",
          "pubsub.topics.create",
          "pubsub.topics.delete",
          "pubsub.topics.detachSubscription",
          "pubsub.topics.get",
          "pubsub.topics.list",
          "pubsub.topics.publish",
          "pubsub.topics.update",
          "pubsub.topics.updateTag",
          "run.configurations.get",
          "run.configurations.list",
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
          "run.routes.invoke",
          "run.routes.list",
          "run.services.get",
          "run.services.list",
          "run.services.update",
          "run.tasks.get",
          "run.tasks.list",
          "serviceusage.services.use",
          "serviceusage.services.list",
          "storage.managedFolders.get",
          "storage.objects.get",
          "storage.objects.list",
          "storage.buckets.get",
          "storage.buckets.list"
        ]
      }
    }
    environment_service_accounts = {
      # sa-job = {
      #   roles       = ["roles/rolejob"]
      #   description = "Service Account for running job services"
      # }

    }
  }
  "test" = {
    environment_custom_roles = {
      roledeveloper = {
        title = "Role Developer"
        description = "Role for Developer."
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.get",
          "serviceusage.services.list",
          "storage.managedFolders.get",
          "storage.objects.get",
          "storage.objects.list",
          "storage.buckets.get",
          "storage.buckets.list",
          "artifactregistry.repositories.get",
          "artifactregistry.tags.get",
          "run.locations.list",
          "run.operations.get",
          "run.operations.list",
          "run.revisions.get",
          "run.revisions.list",
          "run.executions.get",
          "run.executions.list",
          "run.services.get",
          "run.services.list",
          "run.routes.get",
          "run.routes.list",
          "run.jobs.get",
          "run.jobs.list",
          "run.jobs.run",
          "appengine.applications.get",
          "cloudscheduler.jobs.enable",
          "cloudscheduler.jobs.fullView",
          "cloudscheduler.jobs.get",
          "cloudscheduler.jobs.list",
          "cloudscheduler.jobs.pause",
          "cloudscheduler.jobs.run",
          "cloudscheduler.locations.get",
          "cloudscheduler.locations.list",
          "pubsub.topics.get",
          "pubsub.topics.list",
          "pubsub.topics.publish",
          "pubsub.subscriptions.list",
          "pubsub.snapshots.list",
          "monitoring.dashboards.get",
          "monitoring.timeSeries.list",
          "logging.exclusions.get",
          "logging.exclusions.list",
          "logging.links.get",
          "logging.links.list",
          "logging.logEntries.list",
          "logging.logMetrics.get",
          "logging.logMetrics.list",
          "logging.logs.list",
          "logging.operations.get",
          "logging.operations.list",
          "logging.queries.create",
          "logging.queries.delete",
          "logging.queries.get",
          "logging.queries.list",
          "logging.queries.listShared",
          "logging.queries.update",
          "logging.views.get",
          "logging.views.list",
          "cloudsql.databases.get",
          "cloudsql.databases.list",
          "cloudsql.instances.get",
          "cloudsql.instances.list",
          "cloudsql.instances.connect",
          "cloudsql.instances.executeSql",
          "cloudsql.users.get",
          "cloudsql.users.list",
          "cloudbuild.builds.get",
          "cloudbuild.builds.list",
          "cloudbuild.connections.list",
          "cloudbuild.repositories.list",
          "clouddeploy.config.get",
          "clouddeploy.deliveryPipelines.get",
          "clouddeploy.deliveryPipelines.list",
          "clouddeploy.jobRuns.get",
          "clouddeploy.jobRuns.list",
          "clouddeploy.locations.get",
          "clouddeploy.locations.list",
          "clouddeploy.operations.get",
          "clouddeploy.operations.list",
          "clouddeploy.releases.get",
          "clouddeploy.releases.list",
          "clouddeploy.rollouts.get",
          "clouddeploy.rollouts.list",
          "clouddeploy.targets.get",
          "clouddeploy.targets.list",
          "firebase.clients.get",
          "firebase.clients.list",
          "firebase.projects.get",
          "firebasehosting.sites.get",
          "firebasehosting.sites.list",
          "cloudconfig.configs.get",
          "cloudconfig.configs.update"
        ]
      }
    }
    environment_service_accounts = {
      # sa-job = {
      #   roles       = ["roles/rolejob"]
      #   description = "Service Account for running job services"
      # }

    }
  }
  "prod" = {
    environment_custom_roles = {
      roleba = {
        title = "Role BA"
        description = "Role for Business Analyst."
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.list",
          "cloudsql.databases.get",
          "cloudsql.databases.list",
          "cloudsql.instances.get",
          "cloudsql.instances.list",
          "cloudsql.instances.connect",
          "cloudsql.instances.executeSql",
          "cloudsql.users.get",
          "cloudsql.users.list",
          "cloudsql.backupRuns.get",
          "cloudsql.backupRuns.list"
        ]
      },
      roleitops = {
        title = "Role IT Ops"
        description = "Role for IT Ops."
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.list",
          "monitoring.dashboards.get",
          "monitoring.timeSeries.list",
          "logging.exclusions.get",
          "logging.exclusions.list",
          "logging.links.get",
          "logging.links.list",
          "logging.logEntries.list",
          "logging.logMetrics.get",
          "logging.logMetrics.list",
          "logging.logs.list",
          "logging.operations.get",
          "logging.operations.list",
          "logging.queries.create",
          "logging.queries.delete",
          "logging.queries.get",
          "logging.queries.list",
          "logging.queries.listShared",
          "logging.queries.update",
          "logging.views.get",
          "logging.views.list",
          "cloudsql.databases.get",
          "cloudsql.databases.list",
          "cloudsql.instances.get",
          "cloudsql.instances.list",
          "cloudsql.instances.connect",
          "cloudsql.instances.executeSql",
          "cloudsql.users.get",
          "cloudsql.users.list",
          "cloudsql.backupRuns.get",
          "cloudsql.backupRuns.list"
        ]
      },
      roledeveloper = {
        title = "Role Developer"
        description = "Role for Developer."
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.get",
          "serviceusage.services.list",
          "storage.managedFolders.get",
          "storage.objects.get",
          "storage.objects.list",
          "storage.buckets.get",
          "storage.buckets.list",
          "artifactregistry.repositories.get",
          "artifactregistry.tags.get",
          "run.locations.list",
          "run.operations.get",
          "run.operations.list",
          "run.revisions.get",
          "run.revisions.list",
          "run.executions.get",
          "run.executions.list",
          "run.services.get",
          "run.services.list",
          "run.routes.get",
          "run.routes.list",
          "run.jobs.get",
          "run.jobs.list",
          "run.jobs.run",
          "appengine.applications.get",
          "cloudscheduler.jobs.enable",
          "cloudscheduler.jobs.fullView",
          "cloudscheduler.jobs.get",
          "cloudscheduler.jobs.list",
          "cloudscheduler.jobs.pause",
          "cloudscheduler.jobs.run",
          "cloudscheduler.locations.get",
          "cloudscheduler.locations.list",
          "pubsub.topics.get",
          "pubsub.topics.list",
          "pubsub.topics.publish",
          "pubsub.subscriptions.list",
          "pubsub.snapshots.list",
          "monitoring.dashboards.get",
          "monitoring.timeSeries.list",
          "logging.exclusions.get",
          "logging.exclusions.list",
          "logging.links.get",
          "logging.links.list",
          "logging.logEntries.list",
          "logging.logMetrics.get",
          "logging.logMetrics.list",
          "logging.logs.list",
          "logging.operations.get",
          "logging.operations.list",
          "logging.queries.create",
          "logging.queries.delete",
          "logging.queries.get",
          "logging.queries.list",
          "logging.queries.listShared",
          "logging.queries.update",
          "logging.views.get",
          "logging.views.list",
          "cloudsql.databases.get",
          "cloudsql.databases.list",
          "cloudsql.instances.get",
          "cloudsql.instances.list",
          "cloudsql.instances.connect",
          "cloudsql.instances.executeSql",
          "cloudsql.users.get",
          "cloudsql.users.list",
          "cloudbuild.builds.get",
          "cloudbuild.builds.list",
          "cloudbuild.connections.list",
          "cloudbuild.repositories.list",
          "clouddeploy.config.get",
          "clouddeploy.deliveryPipelines.get",
          "clouddeploy.deliveryPipelines.list",
          "clouddeploy.jobRuns.get",
          "clouddeploy.jobRuns.list",
          "clouddeploy.locations.get",
          "clouddeploy.locations.list",
          "clouddeploy.operations.get",
          "clouddeploy.operations.list",
          "clouddeploy.releases.get",
          "clouddeploy.releases.list",
          "clouddeploy.rollouts.get",
          "clouddeploy.rollouts.list",
          "clouddeploy.targets.get",
          "clouddeploy.targets.list",
          "firebase.clients.get",
          "firebase.clients.list",
          "firebase.projects.get",
          "firebasehosting.sites.get",
          "firebasehosting.sites.list",
          "cloudconfig.configs.get",
          "cloudconfig.configs.update"
        ]
      }
    }
    environment_service_accounts = {
      # sa-job = {
      #   roles       = ["roles/rolejob"]
      #   description = "Service Account for running job services"
      # }
    }
  }
  "tools" = {
    environment_custom_roles = {
      roledeveloper = {
          title = "Role Developer"
          description = "Role for Developer."
          permissions = [
            "resourcemanager.projects.get",
            "serviceusage.services.get",
            "serviceusage.services.list",
            "storage.managedFolders.get",
            "storage.objects.get",
            "storage.objects.list",
            "storage.buckets.get",
            "storage.buckets.list",
            "artifactregistry.repositories.get",
            "artifactregistry.tags.get",
            "run.locations.list",
            "run.operations.get",
            "run.operations.list",
            "run.revisions.get",
            "run.revisions.list",
            "run.executions.get",
            "run.executions.list",
            "run.services.get",
            "run.services.list",
            "run.routes.get",
            "run.routes.list",
            "run.jobs.get",
            "run.jobs.list",
            "run.jobs.run",
            "appengine.applications.get",
            "cloudscheduler.jobs.enable",
            "cloudscheduler.jobs.fullView",
            "cloudscheduler.jobs.get",
            "cloudscheduler.jobs.list",
            "cloudscheduler.jobs.pause",
            "cloudscheduler.jobs.run",
            "cloudscheduler.locations.get",
            "cloudscheduler.locations.list",
            "pubsub.topics.get",
            "pubsub.topics.list",
            "pubsub.topics.publish",
            "pubsub.subscriptions.list",
            "pubsub.snapshots.list",
            "monitoring.dashboards.get",
            "monitoring.timeSeries.list",
            "logging.exclusions.get",
            "logging.exclusions.list",
            "logging.links.get",
            "logging.links.list",
            "logging.logEntries.list",
            "logging.logMetrics.get",
            "logging.logMetrics.list",
            "logging.logs.list",
            "logging.operations.get",
            "logging.operations.list",
            "logging.queries.create",
            "logging.queries.delete",
            "logging.queries.get",
            "logging.queries.list",
            "logging.queries.listShared",
            "logging.queries.update",
            "logging.views.get",
            "logging.views.list",
            "cloudsql.databases.get",
            "cloudsql.databases.list",
            "cloudsql.instances.get",
            "cloudsql.instances.list",
            "cloudsql.instances.connect",
            "cloudsql.instances.executeSql",
            "cloudsql.users.get",
            "cloudsql.users.list",
            "cloudbuild.builds.get",
            "cloudbuild.builds.list",
            "cloudbuild.connections.list",
            "cloudbuild.repositories.list",
            "clouddeploy.config.get",
            "clouddeploy.deliveryPipelines.get",
            "clouddeploy.deliveryPipelines.list",
            "clouddeploy.jobRuns.get",
            "clouddeploy.jobRuns.list",
            "clouddeploy.locations.get",
            "clouddeploy.locations.list",
            "clouddeploy.operations.get",
            "clouddeploy.operations.list",
            "clouddeploy.releases.get",
            "clouddeploy.releases.list",
            "clouddeploy.rollouts.get",
            "clouddeploy.rollouts.list",
            "clouddeploy.targets.get",
            "clouddeploy.targets.list",
            "firebase.clients.get",
            "firebase.clients.list",
            "firebase.projects.get",
            "firebasehosting.sites.get",
            "firebasehosting.sites.list",
            "cloudconfig.configs.get",
            "cloudconfig.configs.update"
          ]
      }
    }
  }
}


# global_service_accounts = {
#   "global-sa" = {
#     roles       = ["roles/storage.admin"]
#     description = "global service account"
#   }
# }

# global_custom_roles = {
#   "globalRole" = {
#     permissions = ["run.routes.list"]
#     description = "global custom role"
#   }
# }

global_service_accounts = {
  }

global_custom_roles = {
  rolequeue = {
    title = "Role Queue"
    description = "Role for Queue services."
    permissions = [
      "cloudsql.instances.get",
      "cloudsql.instances.connect",
      "run.routes.invoke",
      "run.routes.list",
      "run.routes.get",
      "run.services.update",
      "run.services.create",
      "run.services.list",
      "run.services.get",
      "run.executions.list",
      "run.executions.get",
      "artifactregistry.tags.get",
      "artifactregistry.repositories.get",
      "artifactregistry.repositories.downloadArtifacts",
      "storage.objects.list",
      "storage.objects.get",
      "storage.managedFolders.get",
      "clientauthconfig.clients.list",
      "resourcemanager.projects.get",
      "iam.serviceAccounts.actAs",
      "iam.serviceAccounts.getAccessToken"
    ]
  },
  rolejob = {
    title = "Role Job"
    description = "Role for cloud run CD flow."
    permissions = [
      "resourcemanager.projects.get",
      "iam.serviceAccounts.actAs",
      "iam.serviceAccounts.getAccessToken",
      "clientauthconfig.clients.list",
      "storage.managedFolders.get",
      "storage.objects.get",
      "storage.objects.list",
      "artifactregistry.repositories.downloadArtifacts",
      "artifactregistry.repositories.get",
      "artifactregistry.tags.get",
      "run.executions.get",
      "run.executions.list",
      "run.jobs.get",
      "run.jobs.list",
      "run.jobs.create",
      "run.jobs.update",
      "run.jobs.run",
      "run.routes.get",
      "run.routes.list",
      "run.routes.invoke",
      "cloudsql.instances.connect",
      "cloudsql.instances.get"
    ]
  },
  rolecdcloudrun = {
    title = "CD Cloud Run"
    description = "Role for cloud run CD flow (new)."
    permissions = [
      "resourcemanager.projects.get",
      "iam.serviceAccounts.actAs",
      "iam.serviceAccounts.getAccessToken",
      "clientauthconfig.clients.list",
      "storage.managedFolders.get",
      "storage.objects.get",
      "storage.objects.list",
      "artifactregistry.repositories.downloadArtifacts",
      "artifactregistry.repositories.get",
      "artifactregistry.tags.get",
      "run.executions.get",
      "run.executions.list",
      "run.jobs.get",
      "run.jobs.list",
      "run.jobs.create",
      "run.jobs.update",
      "run.jobs.run",
      "run.revisions.list",
      "run.revisions.get",
      "run.services.get",
      "run.services.list",
      "run.services.create",
      "run.services.update",
      "run.routes.get",
      "run.routes.list",
      "run.routes.invoke",
      "cloudsql.instances.connect",
      "cloudsql.instances.get",
      "cloudscheduler.jobs.create",
      "cloudscheduler.jobs.delete",
      "cloudscheduler.jobs.get",
      "cloudscheduler.jobs.list"
    ]
  },
  roleapi = {
    title = "Role API"
    description = "Role for API services."
    permissions = [
      "resourcemanager.projects.get",
      "iam.serviceAccounts.actAs",
      "iam.serviceAccounts.getAccessToken",
      "clientauthconfig.clients.list",
      "storage.managedFolders.get",
      "storage.objects.get",
      "storage.objects.list",
      "artifactregistry.repositories.downloadArtifacts",
      "artifactregistry.repositories.get",
      "artifactregistry.tags.get",
      "run.executions.get",
      "run.executions.list",
      "run.services.get",
      "run.services.list",
      "run.services.create",
      "run.services.update",
      "run.routes.get",
      "run.routes.list",
      "run.routes.invoke",
      "cloudsql.instances.connect",
      "cloudsql.instances.get"
    ]
  },
  SRE = {
    title = "Role SRE"
    description = "Role for SRE."
    permissions = [
      "artifactregistry.aptartifacts.create",
      "artifactregistry.attachments.create",
      "artifactregistry.attachments.delete",
      "artifactregistry.attachments.get",
      "artifactregistry.attachments.list",
      "artifactregistry.dockerimages.get",
      "artifactregistry.dockerimages.list",
      "artifactregistry.files.delete",
      "artifactregistry.files.download",
      "artifactregistry.files.get",
      "artifactregistry.files.list",
      "artifactregistry.files.update",
      "artifactregistry.files.upload",
      "artifactregistry.kfpartifacts.create",
      "artifactregistry.locations.get",
      "artifactregistry.locations.list",
      "artifactregistry.mavenartifacts.get",
      "artifactregistry.mavenartifacts.list",
      "artifactregistry.npmpackages.get",
      "artifactregistry.npmpackages.list",
      "artifactregistry.packages.delete",
      "artifactregistry.packages.get",
      "artifactregistry.packages.list",
      "artifactregistry.packages.update",
      "artifactregistry.projectsettings.get",
      "artifactregistry.projectsettings.update",
      "artifactregistry.pythonpackages.get",
      "artifactregistry.pythonpackages.list",
      "artifactregistry.repositories.create",
      "artifactregistry.repositories.createOnPush",
      "artifactregistry.repositories.createTagBinding",
      "artifactregistry.repositories.delete",
      "artifactregistry.repositories.deleteArtifacts",
      "artifactregistry.repositories.deleteTagBinding",
      "artifactregistry.repositories.downloadArtifacts",
      "artifactregistry.repositories.get",
      "artifactregistry.repositories.getIamPolicy",
      "artifactregistry.repositories.list",
      "artifactregistry.repositories.listEffectiveTags",
      "artifactregistry.repositories.listTagBindings",
      "artifactregistry.repositories.readViaVirtualRepository",
      "artifactregistry.repositories.setIamPolicy",
      "artifactregistry.repositories.update",
      "artifactregistry.repositories.uploadArtifacts",
      "artifactregistry.rules.create",
      "artifactregistry.rules.delete",
      "artifactregistry.rules.get",
      "artifactregistry.rules.list",
      "artifactregistry.rules.update",
      "artifactregistry.tags.create",
      "artifactregistry.tags.delete",
      "artifactregistry.tags.get",
      "artifactregistry.tags.list",
      "artifactregistry.tags.update",
      "artifactregistry.versions.delete",
      "artifactregistry.versions.get",
      "artifactregistry.versions.list",
      "artifactregistry.versions.update",
      "artifactregistry.yumartifacts.create",
      "autoscaling.sites.getIamPolicy",
      "autoscaling.sites.readRecommendations",
      "autoscaling.sites.setIamPolicy",
      "autoscaling.sites.writeMetrics",
      "autoscaling.sites.writeState",
      "bigquery.bireservations.get",
      "bigquery.bireservations.update",
      "bigquery.capacityCommitments.create",
      "bigquery.capacityCommitments.delete",
      "bigquery.capacityCommitments.get",
      "bigquery.capacityCommitments.list",
      "bigquery.capacityCommitments.update",
      "bigquery.config.get",
      "bigquery.config.update",
      "bigquery.connections.create",
      "bigquery.connections.delegate",
      "bigquery.connections.delete",
      "bigquery.connections.get",
      "bigquery.connections.getIamPolicy",
      "bigquery.connections.list",
      "bigquery.connections.setIamPolicy",
      "bigquery.connections.update",
      "bigquery.connections.updateTag",
      "bigquery.connections.use",
      "bigquery.dataPolicies.create",
      "bigquery.dataPolicies.delete",
      "bigquery.dataPolicies.get",
      "bigquery.dataPolicies.getIamPolicy",
      "bigquery.dataPolicies.list",
      "bigquery.dataPolicies.setIamPolicy",
      "bigquery.dataPolicies.update",
      "bigquery.datasets.create",
      "bigquery.datasets.createTagBinding",
      "bigquery.datasets.delete",
      "bigquery.datasets.deleteTagBinding",
      "bigquery.datasets.get",
      "bigquery.datasets.getIamPolicy",
      "bigquery.datasets.link",
      "bigquery.datasets.listEffectiveTags",
      "bigquery.datasets.listSharedDatasetUsage",
      "bigquery.datasets.listTagBindings",
      "bigquery.datasets.setIamPolicy",
      "bigquery.datasets.update",
      "bigquery.datasets.updateTag",
      "bigquery.jobs.create",
      "bigquery.jobs.delete",
      "bigquery.jobs.get",
      "bigquery.jobs.list",
      "bigquery.jobs.listAll",
      "bigquery.jobs.listExecutionMetadata",
      "bigquery.jobs.update",
      "bigquery.models.create",
      "bigquery.models.delete",
      "bigquery.models.export",
      "bigquery.models.getData",
      "bigquery.models.getMetadata",
      "bigquery.models.list",
      "bigquery.models.updateData",
      "bigquery.models.updateMetadata",
      "bigquery.models.updateTag",
      "bigquery.readsessions.create",
      "bigquery.readsessions.getData",
      "bigquery.readsessions.update",
      "bigquery.reservationAssignments.create",
      "bigquery.reservationAssignments.delete",
      "bigquery.reservationAssignments.list",
      "bigquery.reservationAssignments.search",
      "bigquery.reservations.create",
      "bigquery.reservations.delete",
      "bigquery.reservations.get",
      "bigquery.reservations.list",
      "bigquery.reservations.update",
      "bigquery.routines.create",
      "bigquery.routines.delete",
      "bigquery.routines.get",
      "bigquery.routines.list",
      "bigquery.routines.update",
      "bigquery.routines.updateTag",
      "bigquery.rowAccessPolicies.create",
      "bigquery.rowAccessPolicies.delete",
      "bigquery.rowAccessPolicies.getIamPolicy",
      "bigquery.rowAccessPolicies.list",
      "bigquery.rowAccessPolicies.setIamPolicy",
      "bigquery.rowAccessPolicies.update",
      "bigquery.savedqueries.create",
      "bigquery.savedqueries.delete",
      "bigquery.savedqueries.get",
      "bigquery.savedqueries.list",
      "bigquery.savedqueries.update",
      "bigquery.tables.createIndex",
      "bigquery.tables.createSnapshot",
      "bigquery.tables.createTagBinding",
      "bigquery.tables.deleteIndex",
      "bigquery.tables.deleteSnapshot",
      "bigquery.tables.deleteTagBinding",
      "bigquery.tables.getIamPolicy",
      "bigquery.tables.listEffectiveTags",
      "bigquery.tables.listTagBindings",
      "bigquery.tables.replicateData",
      "bigquery.tables.restoreSnapshot",
      "bigquery.tables.setIamPolicy",
      "bigquery.transfers.get",
      "bigquery.transfers.update",
      "cloudbuild.builds.approve",
      "cloudbuild.builds.create",
      "cloudbuild.builds.get",
      "cloudbuild.builds.list",
      "cloudbuild.builds.update",
      "cloudbuild.connections.create",
      "cloudbuild.connections.delete",
      "cloudbuild.connections.fetchLinkableRepositories",
      "cloudbuild.connections.get",
      "cloudbuild.connections.getIamPolicy",
      "cloudbuild.connections.list",
      "cloudbuild.connections.setIamPolicy",
      "cloudbuild.connections.update",
      "cloudbuild.integrations.create",
      "cloudbuild.integrations.delete",
      "cloudbuild.integrations.get",
      "cloudbuild.integrations.list",
      "cloudbuild.integrations.update",
      "cloudbuild.operations.get",
      "cloudbuild.operations.list",
      "cloudbuild.repositories.accessReadToken",
      "cloudbuild.repositories.accessReadWriteToken",
      "cloudbuild.repositories.create",
      "cloudbuild.repositories.delete",
      "cloudbuild.repositories.fetchGitRefs",
      "cloudbuild.repositories.get",
      "cloudbuild.repositories.list",
      "cloudbuild.workerpools.create",
      "cloudbuild.workerpools.delete",
      "cloudbuild.workerpools.get",
      "cloudbuild.workerpools.list",
      "cloudbuild.workerpools.update",
      "cloudbuild.workerpools.use",
      "cloudconfig.configs.get",
      "cloudconfig.configs.update",
      "clouddebugger.breakpoints.create",
      "clouddebugger.breakpoints.delete",
      "clouddebugger.breakpoints.get",
      "clouddebugger.breakpoints.list",
      "clouddebugger.breakpoints.listActive",
      "clouddebugger.breakpoints.update",
      "clouddebugger.debuggees.create",
      "clouddebugger.debuggees.list",
      "clouddeploy.automationRuns.cancel",
      "clouddeploy.automationRuns.get",
      "clouddeploy.automationRuns.list",
      "clouddeploy.automations.create",
      "clouddeploy.automations.delete",
      "clouddeploy.automations.get",
      "clouddeploy.automations.list",
      "clouddeploy.automations.update",
      "clouddeploy.config.get",
      "clouddeploy.customTargetTypes.create",
      "clouddeploy.customTargetTypes.delete",
      "clouddeploy.customTargetTypes.get",
      "clouddeploy.customTargetTypes.getIamPolicy",
      "clouddeploy.customTargetTypes.list",
      "clouddeploy.customTargetTypes.setIamPolicy",
      "clouddeploy.customTargetTypes.update",
      "clouddeploy.deliveryPipelines.create",
      "clouddeploy.deliveryPipelines.createTagBinding",
      "clouddeploy.deliveryPipelines.delete",
      "clouddeploy.deliveryPipelines.deleteTagBinding",
      "clouddeploy.deliveryPipelines.get",
      "clouddeploy.deliveryPipelines.getIamPolicy",
      "clouddeploy.deliveryPipelines.list",
      "clouddeploy.deliveryPipelines.listEffectiveTags",
      "clouddeploy.deliveryPipelines.listTagBindings",
      "clouddeploy.deliveryPipelines.setIamPolicy",
      "clouddeploy.deliveryPipelines.update",
      "clouddeploy.deployPolicies.create",
      "clouddeploy.deployPolicies.delete",
      "clouddeploy.deployPolicies.get",
      "clouddeploy.deployPolicies.list",
      "clouddeploy.deployPolicies.override",
      "clouddeploy.deployPolicies.update",
      "clouddeploy.jobRuns.get",
      "clouddeploy.jobRuns.list",
      "clouddeploy.jobRuns.terminate",
      "clouddeploy.locations.get",
      "clouddeploy.locations.list",
      "clouddeploy.operations.cancel",
      "clouddeploy.operations.delete",
      "clouddeploy.operations.get",
      "clouddeploy.operations.list",
      "clouddeploy.releases.abandon",
      "clouddeploy.releases.create",
      "clouddeploy.releases.delete",
      "clouddeploy.releases.get",
      "clouddeploy.releases.list",
      "clouddeploy.rollouts.advance",
      "clouddeploy.rollouts.approve",
      "clouddeploy.rollouts.cancel",
      "clouddeploy.rollouts.create",
      "clouddeploy.rollouts.get",
      "clouddeploy.rollouts.ignoreJob",
      "clouddeploy.rollouts.list",
      "clouddeploy.rollouts.retryJob",
      "clouddeploy.rollouts.rollback",
      "clouddeploy.targets.create",
      "clouddeploy.targets.createTagBinding",
      "clouddeploy.targets.delete",
      "clouddeploy.targets.deleteTagBinding",
      "clouddeploy.targets.get",
      "clouddeploy.targets.getIamPolicy",
      "clouddeploy.targets.list",
      "clouddeploy.targets.listEffectiveTags",
      "clouddeploy.targets.listTagBindings",
      "clouddeploy.targets.setIamPolicy",
      "clouddeploy.targets.update",
      "cloudfunctions.functions.call",
      "cloudfunctions.functions.create",
      "cloudfunctions.functions.delete",
      "cloudfunctions.functions.get",
      "cloudfunctions.functions.getIamPolicy",
      "cloudfunctions.functions.invoke",
      "cloudfunctions.functions.list",
      "cloudfunctions.functions.setIamPolicy",
      "cloudfunctions.functions.sourceCodeGet",
      "cloudfunctions.functions.sourceCodeSet",
      "cloudfunctions.functions.update",
      "cloudfunctions.locations.list",
      "cloudfunctions.operations.get",
      "cloudfunctions.operations.list",
      "cloudmessaging.messages.create",
      "cloudnotifications.activities.list",
      "cloudscheduler.jobs.create",
      "cloudscheduler.jobs.delete",
      "cloudscheduler.jobs.enable",
      "cloudscheduler.jobs.fullView",
      "cloudscheduler.jobs.get",
      "cloudscheduler.jobs.list",
      "cloudscheduler.jobs.pause",
      "cloudscheduler.jobs.run",
      "cloudscheduler.jobs.update",
      "cloudscheduler.locations.get",
      "cloudscheduler.locations.list",
      "cloudsecurityscanner.crawledurls.list",
      "cloudsecurityscanner.results.get",
      "cloudsecurityscanner.results.list",
      "cloudsecurityscanner.scanruns.get",
      "cloudsecurityscanner.scanruns.getSummary",
      "cloudsecurityscanner.scanruns.list",
      "cloudsecurityscanner.scanruns.stop",
      "cloudsecurityscanner.scans.create",
      "cloudsecurityscanner.scans.delete",
      "cloudsecurityscanner.scans.get",
      "cloudsecurityscanner.scans.list",
      "cloudsecurityscanner.scans.run",
      "cloudsecurityscanner.scans.update",
      "cloudsql.backupRuns.create",
      "cloudsql.backupRuns.delete",
      "cloudsql.backupRuns.get",
      "cloudsql.backupRuns.list",
      "cloudsql.databases.create",
      "cloudsql.databases.delete",
      "cloudsql.databases.get",
      "cloudsql.databases.list",
      "cloudsql.databases.update",
      "cloudsql.instances.addServerCa",
      "cloudsql.instances.addServerCertificate",
      "cloudsql.instances.clone",
      "cloudsql.instances.connect",
      "cloudsql.instances.create",
      "cloudsql.instances.createTagBinding",
      "cloudsql.instances.delete",
      "cloudsql.instances.deleteTagBinding",
      "cloudsql.instances.demoteMaster",
      "cloudsql.instances.executeSql",
      "cloudsql.instances.export",
      "cloudsql.instances.failover",
      "cloudsql.instances.get",
      "cloudsql.instances.getDiskShrinkConfig",
      "cloudsql.instances.import",
      "cloudsql.instances.list",
      "cloudsql.instances.listEffectiveTags",
      "cloudsql.instances.listServerCas",
      "cloudsql.instances.listServerCertificates",
      "cloudsql.instances.listTagBindings",
      "cloudsql.instances.login",
      "cloudsql.instances.migrate",
      "cloudsql.instances.performDiskShrink",
      "cloudsql.instances.promoteReplica",
      "cloudsql.instances.reencrypt",
      "cloudsql.instances.resetReplicaSize",
      "cloudsql.instances.resetSslConfig",
      "cloudsql.instances.restart",
      "cloudsql.instances.restoreBackup",
      "cloudsql.instances.rotateServerCa",
      "cloudsql.instances.rotateServerCertificate",
      "cloudsql.instances.startReplica",
      "cloudsql.instances.stopReplica",
      "cloudsql.instances.truncateLog",
      "cloudsql.instances.update",
      "cloudsql.schemas.view",
      "cloudsql.sslCerts.create",
      "cloudsql.sslCerts.delete",
      "cloudsql.sslCerts.get",
      "cloudsql.sslCerts.list",
      "cloudsql.users.create",
      "cloudsql.users.delete",
      "cloudsql.users.get",
      "cloudsql.users.list",
      "cloudsql.users.update",
      "cloudtasks.cmekConfig.get",
      "cloudtasks.cmekConfig.update",
      "cloudtasks.locations.get",
      "cloudtasks.locations.list",
      "cloudtasks.queues.create",
      "cloudtasks.queues.delete",
      "cloudtasks.queues.get",
      "cloudtasks.queues.getIamPolicy",
      "cloudtasks.queues.list",
      "cloudtasks.queues.pause",
      "cloudtasks.queues.purge",
      "cloudtasks.queues.resume",
      "cloudtasks.queues.setIamPolicy",
      "cloudtasks.queues.update",
      "cloudtasks.tasks.create",
      "cloudtasks.tasks.delete",
      "cloudtasks.tasks.fullView",
      "cloudtasks.tasks.get",
      "cloudtasks.tasks.list",
      "cloudtasks.tasks.run",
      "cloudtoolresults.executions.create",
      "cloudtoolresults.executions.get",
      "cloudtoolresults.executions.list",
      "cloudtoolresults.executions.update",
      "cloudtoolresults.histories.create",
      "cloudtoolresults.histories.get",
      "cloudtoolresults.histories.list",
      "cloudtoolresults.settings.create",
      "cloudtoolresults.settings.get",
      "cloudtoolresults.settings.update",
      "cloudtoolresults.steps.create",
      "cloudtoolresults.steps.get",
      "cloudtoolresults.steps.list",
      "cloudtoolresults.steps.update",
      "cloudtrace.insights.get",
      "cloudtrace.insights.list",
      "cloudtrace.stats.get",
      "cloudtrace.tasks.create",
      "cloudtrace.tasks.delete",
      "cloudtrace.tasks.get",
      "cloudtrace.tasks.list",
      "cloudtrace.traceScopes.create",
      "cloudtrace.traceScopes.delete",
      "cloudtrace.traceScopes.get",
      "cloudtrace.traceScopes.list",
      "cloudtrace.traceScopes.update",
      "cloudtrace.traces.get",
      "cloudtrace.traces.list",
      "cloudtrace.traces.patch",
      "compute.addresses.createInternal",
      "compute.addresses.deleteInternal",
      "compute.addresses.get",
      "compute.addresses.list",
      "compute.addresses.listEffectiveTags",
      "compute.addresses.listTagBindings",
      "compute.addresses.useInternal",
      "compute.externalVpnGateways.get",
      "compute.externalVpnGateways.list",
      "compute.externalVpnGateways.listEffectiveTags",
      "compute.externalVpnGateways.listTagBindings",
      "compute.externalVpnGateways.use",
      "compute.firewalls.get",
      "compute.firewalls.list",
      "compute.firewalls.listEffectiveTags",
      "compute.firewalls.listTagBindings",
      "compute.instanceSettings.get",
      "compute.interconnectAttachments.get",
      "compute.interconnectAttachments.list",
      "compute.interconnectAttachments.listEffectiveTags",
      "compute.interconnectAttachments.listTagBindings",
      "compute.interconnectLocations.get",
      "compute.interconnectLocations.list",
      "compute.interconnectRemoteLocations.get",
      "compute.interconnectRemoteLocations.list",
      "compute.interconnects.get",
      "compute.interconnects.list",
      "compute.interconnects.listEffectiveTags",
      "compute.interconnects.listTagBindings",
      "compute.interconnects.use",
      "compute.networkAttachments.get",
      "compute.networkAttachments.list",
      "compute.networkAttachments.listEffectiveTags",
      "compute.networkAttachments.listTagBindings",
      "compute.networks.access",
      "compute.networks.get",
      "compute.networks.getEffectiveFirewalls",
      "compute.networks.getRegionEffectiveFirewalls",
      "compute.networks.list",
      "compute.networks.listEffectiveTags",
      "compute.networks.listPeeringRoutes",
      "compute.networks.listTagBindings",
      "compute.networks.use",
      "compute.networks.useExternalIp",
      "compute.projects.get",
      "compute.regions.get",
      "compute.regions.list",
      "compute.routers.get",
      "compute.routers.getRoutePolicy",
      "compute.routers.list",
      "compute.routers.listBgpRoutes",
      "compute.routers.listEffectiveTags",
      "compute.routers.listRoutePolicies",
      "compute.routers.listTagBindings",
      "compute.routes.get",
      "compute.routes.list",
      "compute.routes.listEffectiveTags",
      "compute.routes.listTagBindings",
      "compute.serviceAttachments.get",
      "compute.serviceAttachments.list",
      "compute.serviceAttachments.listEffectiveTags",
      "compute.serviceAttachments.listTagBindings",
      "compute.subnetworks.get",
      "compute.subnetworks.list",
      "compute.subnetworks.listEffectiveTags",
      "compute.subnetworks.listTagBindings",
      "compute.subnetworks.use",
      "compute.subnetworks.useExternalIp",
      "compute.targetVpnGateways.get",
      "compute.targetVpnGateways.list",
      "compute.targetVpnGateways.listEffectiveTags",
      "compute.targetVpnGateways.listTagBindings",
      "compute.vpnGateways.get",
      "compute.vpnGateways.list",
      "compute.vpnGateways.listEffectiveTags",
      "compute.vpnGateways.listTagBindings",
      "compute.vpnGateways.use",
      "compute.vpnTunnels.get",
      "compute.vpnTunnels.list",
      "compute.vpnTunnels.listEffectiveTags",
      "compute.vpnTunnels.listTagBindings",
      "compute.zones.get",
      "compute.zones.list",
      "containeranalysis.notes.attachOccurrence",
      "containeranalysis.notes.create",
      "containeranalysis.notes.delete",
      "containeranalysis.notes.get",
      "containeranalysis.notes.getIamPolicy",
      "containeranalysis.notes.list",
      "containeranalysis.notes.listOccurrences",
      "containeranalysis.notes.setIamPolicy",
      "containeranalysis.notes.update",
      "containeranalysis.occurrences.create",
      "containeranalysis.occurrences.delete",
      "containeranalysis.occurrences.get",
      "containeranalysis.occurrences.getIamPolicy",
      "containeranalysis.occurrences.list",
      "containeranalysis.occurrences.setIamPolicy",
      "containeranalysis.occurrences.update",
      "databasecenter.fleetHealthStats.list",
      "databasecenter.fleetStats.list",
      "databasecenter.locations.list",
      "databasecenter.products.list",
      "databasecenter.resourceGroups.list",
      "databasecenter.userLabels.list",
      "databaseinsights.activeQueries.fetch",
      "databaseinsights.activeQuery.terminate",
      "databaseinsights.activitySummary.fetch",
      "databaseinsights.aggregatedEvents.query",
      "databaseinsights.aggregatedStats.query",
      "databaseinsights.clusterEvents.query",
      "databaseinsights.instanceEvents.query",
      "databaseinsights.locations.get",
      "databaseinsights.locations.list",
      "databaseinsights.recommendations.query",
      "databaseinsights.resourceRecommendations.query",
      "databaseinsights.timeSeries.query",
      "databaseinsights.workloadRecommendations.fetch",
      "dataprocessing.datasources.get",
      "dataprocessing.datasources.list",
      "dataprocessing.datasources.update",
      "dataprocessing.featurecontrols.list",
      "dataprocessing.featurecontrols.update",
      "dataprocessing.groupcontrols.get",
      "dataprocessing.groupcontrols.list",
      "dataprocessing.groupcontrols.update",
      "datastore.backupSchedules.create",
      "datastore.backupSchedules.delete",
      "datastore.backupSchedules.get",
      "datastore.backupSchedules.list",
      "datastore.backupSchedules.update",
      "datastore.backups.delete",
      "datastore.backups.get",
      "datastore.backups.list",
      "datastore.backups.restoreDatabase",
      "datastore.databases.bulkDelete",
      "datastore.databases.create",
      "datastore.databases.createTagBinding",
      "datastore.databases.delete",
      "datastore.databases.deleteTagBinding",
      "datastore.databases.export",
      "datastore.databases.get",
      "datastore.databases.getMetadata",
      "datastore.databases.import",
      "datastore.databases.list",
      "datastore.databases.listEffectiveTags",
      "datastore.databases.listTagBindings",
      "datastore.databases.update",
      "datastore.entities.allocateIds",
      "datastore.entities.create",
      "datastore.entities.delete",
      "datastore.entities.get",
      "datastore.entities.list",
      "datastore.entities.update",
      "datastore.indexes.create",
      "datastore.indexes.delete",
      "datastore.indexes.get",
      "datastore.indexes.list",
      "datastore.indexes.update",
      "datastore.keyVisualizerScans.get",
      "datastore.keyVisualizerScans.list",
      "datastore.locations.get",
      "datastore.locations.list",
      "datastore.namespaces.get",
      "datastore.namespaces.list",
      "datastore.operations.cancel",
      "datastore.operations.delete",
      "datastore.operations.get",
      "datastore.operations.list",
      "datastore.statistics.get",
      "datastore.statistics.list",
      "deploymentmanager.compositeTypes.create",
      "deploymentmanager.compositeTypes.delete",
      "deploymentmanager.compositeTypes.get",
      "deploymentmanager.compositeTypes.list",
      "deploymentmanager.compositeTypes.update",
      "deploymentmanager.deployments.cancelPreview",
      "deploymentmanager.deployments.create",
      "deploymentmanager.deployments.delete",
      "deploymentmanager.deployments.get",
      "deploymentmanager.deployments.getIamPolicy",
      "deploymentmanager.deployments.list",
      "deploymentmanager.deployments.setIamPolicy",
      "deploymentmanager.deployments.stop",
      "deploymentmanager.deployments.update",
      "deploymentmanager.manifests.get",
      "deploymentmanager.manifests.list",
      "deploymentmanager.operations.get",
      "deploymentmanager.operations.list",
      "deploymentmanager.resources.get",
      "deploymentmanager.resources.list",
      "deploymentmanager.typeProviders.create",
      "deploymentmanager.typeProviders.delete",
      "deploymentmanager.typeProviders.get",
      "deploymentmanager.typeProviders.getType",
      "deploymentmanager.typeProviders.list",
      "deploymentmanager.typeProviders.listTypes",
      "deploymentmanager.typeProviders.update",
      "deploymentmanager.types.create",
      "deploymentmanager.types.delete",
      "deploymentmanager.types.get",
      "deploymentmanager.types.list",
      "deploymentmanager.types.update",
      "errorreporting.applications.list",
      "errorreporting.errorEvents.create",
      "errorreporting.errorEvents.delete",
      "errorreporting.errorEvents.list",
      "errorreporting.groupMetadata.get",
      "errorreporting.groupMetadata.update",
      "errorreporting.groups.list",
      "firebase.billingPlans.get",
      "firebase.billingPlans.update",
      "firebase.clients.create",
      "firebase.clients.delete",
      "firebase.clients.get",
      "firebase.clients.list",
      "firebase.clients.undelete",
      "firebase.clients.update",
      "firebase.links.create",
      "firebase.links.delete",
      "firebase.links.list",
      "firebase.links.update",
      "firebase.playLinks.get",
      "firebase.playLinks.list",
      "firebase.playLinks.update",
      "firebase.projects.delete",
      "firebase.projects.get",
      "firebase.projects.update",
      "firebaseabt.experimentresults.get",
      "firebaseabt.experiments.create",
      "firebaseabt.experiments.delete",
      "firebaseabt.experiments.get",
      "firebaseabt.experiments.list",
      "firebaseabt.experiments.update",
      "firebaseabt.projectmetadata.get",
      "firebaseanalytics.resources.googleAnalyticsEdit",
      "firebaseanalytics.resources.googleAnalyticsReadAndAnalyze",
      "firebaseappcheck.appAttestConfig.get",
      "firebaseappcheck.appAttestConfig.update",
      "firebaseappcheck.debugTokens.get",
      "firebaseappcheck.debugTokens.update",
      "firebaseappcheck.deviceCheckConfig.get",
      "firebaseappcheck.deviceCheckConfig.update",
      "firebaseappcheck.playIntegrityConfig.get",
      "firebaseappcheck.playIntegrityConfig.update",
      "firebaseappcheck.recaptchaEnterpriseConfig.get",
      "firebaseappcheck.recaptchaEnterpriseConfig.update",
      "firebaseappcheck.recaptchaV3Config.get",
      "firebaseappcheck.recaptchaV3Config.update",
      "firebaseappcheck.resourcePolicies.get",
      "firebaseappcheck.resourcePolicies.update",
      "firebaseappcheck.safetyNetConfig.get",
      "firebaseappcheck.safetyNetConfig.update",
      "firebaseappcheck.services.get",
      "firebaseappcheck.services.update",
      "firebaseappdistro.groups.list",
      "firebaseappdistro.groups.update",
      "firebaseappdistro.releases.list",
      "firebaseappdistro.releases.update",
      "firebaseappdistro.testers.list",
      "firebaseappdistro.testers.update",
      "firebaseauth.configs.create",
      "firebaseauth.configs.get",
      "firebaseauth.configs.getHashConfig",
      "firebaseauth.configs.getSecret",
      "firebaseauth.configs.update",
      "firebaseauth.users.create",
      "firebaseauth.users.createSession",
      "firebaseauth.users.delete",
      "firebaseauth.users.get",
      "firebaseauth.users.sendEmail",
      "firebaseauth.users.update",
      "firebasecrash.issues.update",
      "firebasecrash.reports.get",
      "firebasecrashlytics.config.get",
      "firebasecrashlytics.config.update",
      "firebasecrashlytics.data.get",
      "firebasecrashlytics.issues.get",
      "firebasecrashlytics.issues.list",
      "firebasecrashlytics.issues.update",
      "firebasecrashlytics.sessions.get",
      "firebasedynamiclinks.destinations.list",
      "firebasedynamiclinks.destinations.update",
      "firebasedynamiclinks.domains.create",
      "firebasedynamiclinks.domains.delete",
      "firebasedynamiclinks.domains.get",
      "firebasedynamiclinks.domains.list",
      "firebasedynamiclinks.domains.update",
      "firebasedynamiclinks.links.create",
      "firebasedynamiclinks.links.get",
      "firebasedynamiclinks.links.list",
      "firebasedynamiclinks.links.update",
      "firebasedynamiclinks.stats.get",
      "firebaseextensions.configs.create",
      "firebaseextensions.configs.delete",
      "firebaseextensions.configs.list",
      "firebaseextensions.configs.update",
      "firebasehosting.sites.create",
      "firebasehosting.sites.delete",
      "firebasehosting.sites.get",
      "firebasehosting.sites.list",
      "firebasehosting.sites.update",
      "firebasemessagingcampaigns.campaigns.create",
      "firebasemessagingcampaigns.campaigns.delete",
      "firebasemessagingcampaigns.campaigns.get",
      "firebasemessagingcampaigns.campaigns.list",
      "firebasemessagingcampaigns.campaigns.start",
      "firebasemessagingcampaigns.campaigns.stop",
      "firebasemessagingcampaigns.campaigns.update",
      "firebasenotifications.messages.create",
      "firebasenotifications.messages.delete",
      "firebasenotifications.messages.get",
      "firebasenotifications.messages.list",
      "firebasenotifications.messages.update",
      "firebaseperformance.config.update",
      "firebaseperformance.data.get",
      "firebaserules.releases.create",
      "firebaserules.releases.delete",
      "firebaserules.releases.get",
      "firebaserules.releases.getExecutable",
      "firebaserules.releases.list",
      "firebaserules.releases.update",
      "firebaserules.rulesets.create",
      "firebaserules.rulesets.delete",
      "firebaserules.rulesets.get",
      "firebaserules.rulesets.list",
      "firebaserules.rulesets.test",
      "firebasestorage.buckets.addFirebase",
      "firebasestorage.buckets.get",
      "firebasestorage.buckets.list",
      "firebasestorage.buckets.removeFirebase",
      "firebasestorage.defaultBucket.create",
      "firebasestorage.defaultBucket.delete",
      "firebasestorage.defaultBucket.get",
      "iam.denypolicies.get",
      "iam.denypolicies.list",
      "iam.googleapis.com/oauthClientCredentials.create",
      "iam.googleapis.com/oauthClientCredentials.delete",
      "iam.googleapis.com/oauthClientCredentials.get",
      "iam.googleapis.com/oauthClientCredentials.list",
      "iam.googleapis.com/oauthClientCredentials.update",
      "iam.googleapis.com/oauthClients.get",
      "iam.googleapis.com/oauthClients.list",
      "iam.googleapis.com/oauthClients.undelete",
      "iam.googleapis.com/workloadIdentityPoolProviderKeys.create",
      "iam.googleapis.com/workloadIdentityPoolProviderKeys.delete",
      "iam.googleapis.com/workloadIdentityPoolProviderKeys.get",
      "iam.googleapis.com/workloadIdentityPoolProviderKeys.list",
      "iam.googleapis.com/workloadIdentityPoolProviderKeys.undelete",
      "iam.googleapis.com/workloadIdentityPoolProviders.create",
      "iam.googleapis.com/workloadIdentityPoolProviders.delete",
      "iam.googleapis.com/workloadIdentityPoolProviders.get",
      "iam.googleapis.com/workloadIdentityPoolProviders.list",
      "iam.googleapis.com/workloadIdentityPoolProviders.undelete",
      "iam.googleapis.com/workloadIdentityPoolProviders.update",
      "iam.googleapis.com/workloadIdentityPools.delete",
      "iam.googleapis.com/workloadIdentityPools.get",
      "iam.googleapis.com/workloadIdentityPools.list",
      "iam.googleapis.com/workloadIdentityPools.undelete",
      "iam.googleapis.com/workloadIdentityPools.update",
      "iam.operations.get",
      "iam.policybindings.get",
      "iam.policybindings.list",
      "iam.principalaccessboundarypolicies.get",
      "iam.principalaccessboundarypolicies.list",
      "iam.roles.get",
      "iam.roles.list",
      "iam.roles.undelete",
      "iam.serviceAccountKeys.create",
      "iam.serviceAccountKeys.delete",
      "iam.serviceAccountKeys.disable",
      "iam.serviceAccountKeys.enable",
      "iam.serviceAccountKeys.get",
      "iam.serviceAccountKeys.list",
      "iam.serviceAccounts.actAs",
      "iam.serviceAccounts.createTagBinding",
      "iam.serviceAccounts.deleteTagBinding",
      "iam.serviceAccounts.disable",
      "iam.serviceAccounts.enable",
      "iam.serviceAccounts.get",
      "iam.serviceAccounts.getIamPolicy",
      "iam.serviceAccounts.list",
      "iam.serviceAccounts.listEffectiveTags",
      "iam.serviceAccounts.listTagBindings",
      "iam.serviceAccounts.setIamPolicy",
      "iam.serviceAccounts.undelete",
      "iam.workloadIdentityPools.createPolicyBinding",
      "iam.workloadIdentityPools.deletePolicyBinding",
      "iam.workloadIdentityPools.searchPolicyBindings",
      "iap.projects.getSettings",
      "iap.projects.updateSettings",
      "iap.tunnel.getIamPolicy",
      "iap.tunnel.setIamPolicy",
      "iap.tunnelDestGroups.accessViaIAP",
      "iap.tunnelDestGroups.create",
      "iap.tunnelDestGroups.delete",
      "iap.tunnelDestGroups.get",
      "iap.tunnelDestGroups.getIamPolicy",
      "iap.tunnelDestGroups.list",
      "iap.tunnelDestGroups.remediate",
      "iap.tunnelDestGroups.setIamPolicy",
      "iap.tunnelDestGroups.update",
      "iap.tunnelInstances.accessViaIAP",
      "iap.tunnelInstances.getIamPolicy",
      "iap.tunnelInstances.setIamPolicy",
      "iap.tunnelLocations.getIamPolicy",
      "iap.tunnelLocations.setIamPolicy",
      "iap.tunnelZones.getIamPolicy",
      "iap.tunnelZones.setIamPolicy",
      "iap.tunnelinstances.remediate",
      "iap.web.getIamPolicy",
      "iap.web.getSettings",
      "iap.web.setIamPolicy",
      "iap.web.updateSettings",
      "iap.webServiceVersions.getIamPolicy",
      "iap.webServiceVersions.getSettings",
      "iap.webServiceVersions.remediate",
      "iap.webServiceVersions.setIamPolicy",
      "iap.webServiceVersions.updateSettings",
      "iap.webServices.getIamPolicy",
      "iap.webServices.getSettings",
      "iap.webServices.setIamPolicy",
      "iap.webServices.updateSettings",
      "iap.webTypes.getIamPolicy",
      "iap.webTypes.getSettings",
      "iap.webTypes.setIamPolicy",
      "iap.webTypes.updateSettings",
      "identitytoolkit.tenants.create",
      "identitytoolkit.tenants.delete",
      "identitytoolkit.tenants.get",
      "identitytoolkit.tenants.getIamPolicy",
      "identitytoolkit.tenants.list",
      "identitytoolkit.tenants.setIamPolicy",
      "identitytoolkit.tenants.update",
      "logging.buckets.copyLogEntries",
      "logging.buckets.create",
      "logging.buckets.createTagBinding",
      "logging.buckets.delete",
      "logging.buckets.deleteTagBinding",
      "logging.buckets.get",
      "logging.buckets.list",
      "logging.buckets.listEffectiveTags",
      "logging.buckets.listTagBindings",
      "logging.buckets.undelete",
      "logging.buckets.update",
      "logging.exclusions.create",
      "logging.exclusions.delete",
      "logging.exclusions.get",
      "logging.exclusions.list",
      "logging.exclusions.update",
      "logging.fields.access",
      "logging.links.create",
      "logging.links.delete",
      "logging.links.get",
      "logging.links.list",
      "logging.locations.get",
      "logging.locations.list",
      "logging.logEntries.create",
      "logging.logEntries.download",
      "logging.logEntries.list",
      "logging.logEntries.route",
      "logging.logMetrics.create",
      "logging.logMetrics.delete",
      "logging.logMetrics.get",
      "logging.logMetrics.list",
      "logging.logMetrics.update",
      "logging.logServiceIndexes.list",
      "logging.logServices.list",
      "logging.logs.delete",
      "logging.logs.list",
      "logging.notificationRules.create",
      "logging.notificationRules.delete",
      "logging.notificationRules.get",
      "logging.notificationRules.list",
      "logging.notificationRules.update",
      "logging.operations.cancel",
      "logging.operations.get",
      "logging.operations.list",
      "logging.privateLogEntries.list",
      "logging.queries.deleteShared",
      "logging.queries.getShared",
      "logging.queries.listShared",
      "logging.queries.share",
      "logging.queries.updateShared",
      "logging.queries.usePrivate",
      "logging.settings.get",
      "logging.settings.update",
      "logging.sinks.create",
      "logging.sinks.delete",
      "logging.sinks.get",
      "logging.sinks.list",
      "logging.sinks.update",
      "logging.sqlAlerts.create",
      "logging.sqlAlerts.update",
      "logging.usage.get",
      "logging.views.access",
      "logging.views.create",
      "logging.views.delete",
      "logging.views.get",
      "logging.views.getIamPolicy",
      "logging.views.list",
      "logging.views.listLogs",
      "logging.views.listResourceKeys",
      "logging.views.listResourceValues",
      "logging.views.setIamPolicy",
      "logging.views.update",
      "memcache.instances.applyParameters",
      "memcache.instances.applySoftwareUpdate",
      "memcache.instances.create",
      "memcache.instances.delete",
      "memcache.instances.get",
      "memcache.instances.list",
      "memcache.instances.rescheduleMaintenance",
      "memcache.instances.update",
      "memcache.instances.updateParameters",
      "memcache.instances.upgrade",
      "memcache.locations.get",
      "memcache.locations.list",
      "memcache.operations.cancel",
      "memcache.operations.delete",
      "memcache.operations.get",
      "memcache.operations.list",
      "monitoring.alertPolicies.create",
      "monitoring.alertPolicies.delete",
      "monitoring.alertPolicies.get",
      "monitoring.alertPolicies.list",
      "monitoring.alertPolicies.update",
      "monitoring.dashboards.create",
      "monitoring.dashboards.delete",
      "monitoring.dashboards.get",
      "monitoring.dashboards.list",
      "monitoring.dashboards.update",
      "monitoring.groups.create",
      "monitoring.groups.delete",
      "monitoring.groups.get",
      "monitoring.groups.list",
      "monitoring.groups.update",
      "monitoring.metricDescriptors.create",
      "monitoring.metricDescriptors.delete",
      "monitoring.metricDescriptors.get",
      "monitoring.metricDescriptors.list",
      "monitoring.metricsScopes.link",
      "monitoring.monitoredResourceDescriptors.get",
      "monitoring.monitoredResourceDescriptors.list",
      "monitoring.notificationChannelDescriptors.get",
      "monitoring.notificationChannelDescriptors.list",
      "monitoring.notificationChannels.create",
      "monitoring.notificationChannels.delete",
      "monitoring.notificationChannels.get",
      "monitoring.notificationChannels.getVerificationCode",
      "monitoring.notificationChannels.list",
      "monitoring.notificationChannels.sendVerificationCode",
      "monitoring.notificationChannels.update",
      "monitoring.notificationChannels.verify",
      "monitoring.services.create",
      "monitoring.services.delete",
      "monitoring.services.get",
      "monitoring.services.list",
      "monitoring.services.update",
      "monitoring.slos.create",
      "monitoring.slos.delete",
      "monitoring.slos.get",
      "monitoring.slos.list",
      "monitoring.slos.update",
      "monitoring.snoozes.create",
      "monitoring.snoozes.get",
      "monitoring.snoozes.list",
      "monitoring.snoozes.update",
      "monitoring.timeSeries.create",
      "monitoring.timeSeries.list",
      "monitoring.uptimeCheckConfigs.create",
      "monitoring.uptimeCheckConfigs.delete",
      "monitoring.uptimeCheckConfigs.get",
      "monitoring.uptimeCheckConfigs.list",
      "monitoring.uptimeCheckConfigs.update",
      "networkconnectivity.groups.acceptSpoke",
      "networkconnectivity.groups.get",
      "networkconnectivity.groups.getIamPolicy",
      "networkconnectivity.groups.list",
      "networkconnectivity.groups.rejectSpoke",
      "networkconnectivity.groups.setIamPolicy",
      "networkconnectivity.groups.use",
      "networkconnectivity.hubRouteTables.get",
      "networkconnectivity.hubRouteTables.getIamPolicy",
      "networkconnectivity.hubRouteTables.list",
      "networkconnectivity.hubRouteTables.setIamPolicy",
      "networkconnectivity.hubRoutes.get",
      "networkconnectivity.hubRoutes.getIamPolicy",
      "networkconnectivity.hubRoutes.list",
      "networkconnectivity.hubRoutes.setIamPolicy",
      "networkconnectivity.hubs.create",
      "networkconnectivity.hubs.delete",
      "networkconnectivity.hubs.get",
      "networkconnectivity.hubs.getIamPolicy",
      "networkconnectivity.hubs.list",
      "networkconnectivity.hubs.listSpokes",
      "networkconnectivity.hubs.queryStatus",
      "networkconnectivity.hubs.setIamPolicy",
      "networkconnectivity.hubs.update",
      "networkconnectivity.internalRanges.create",
      "networkconnectivity.internalRanges.delete",
      "networkconnectivity.internalRanges.get",
      "networkconnectivity.internalRanges.getIamPolicy",
      "networkconnectivity.internalRanges.list",
      "networkconnectivity.internalRanges.setIamPolicy",
      "networkconnectivity.internalRanges.update",
      "networkconnectivity.locations.get",
      "networkconnectivity.locations.list",
      "networkconnectivity.operations.cancel",
      "networkconnectivity.operations.delete",
      "networkconnectivity.operations.get",
      "networkconnectivity.operations.list",
      "networkconnectivity.policyBasedRoutes.create",
      "networkconnectivity.policyBasedRoutes.delete",
      "networkconnectivity.policyBasedRoutes.get",
      "networkconnectivity.policyBasedRoutes.getIamPolicy",
      "networkconnectivity.policyBasedRoutes.list",
      "networkconnectivity.policyBasedRoutes.setIamPolicy",
      "networkconnectivity.regionalEndpoints.create",
      "networkconnectivity.regionalEndpoints.delete",
      "networkconnectivity.regionalEndpoints.get",
      "networkconnectivity.regionalEndpoints.list",
      "networkconnectivity.serviceClasses.create",
      "networkconnectivity.serviceClasses.delete",
      "networkconnectivity.serviceClasses.get",
      "networkconnectivity.serviceClasses.list",
      "networkconnectivity.serviceClasses.update",
      "networkconnectivity.serviceClasses.use",
      "networkconnectivity.serviceConnectionMaps.create",
      "networkconnectivity.serviceConnectionMaps.delete",
      "networkconnectivity.serviceConnectionMaps.get",
      "networkconnectivity.serviceConnectionMaps.list",
      "networkconnectivity.serviceConnectionMaps.update",
      "networkconnectivity.serviceConnectionPolicies.create",
      "networkconnectivity.serviceConnectionPolicies.delete",
      "networkconnectivity.serviceConnectionPolicies.get",
      "networkconnectivity.serviceConnectionPolicies.list",
      "networkconnectivity.serviceConnectionPolicies.update",
      "networkconnectivity.spokes.create",
      "networkconnectivity.spokes.delete",
      "networkconnectivity.spokes.get",
      "networkconnectivity.spokes.getIamPolicy",
      "networkconnectivity.spokes.list",
      "networkconnectivity.spokes.setIamPolicy",
      "networkconnectivity.spokes.update",
      "networkmanagement.connectivitytests.create",
      "networkmanagement.connectivitytests.delete",
      "networkmanagement.connectivitytests.get",
      "networkmanagement.connectivitytests.getIamPolicy",
      "networkmanagement.connectivitytests.list",
      "networkmanagement.connectivitytests.rerun",
      "networkmanagement.connectivitytests.setIamPolicy",
      "networkmanagement.connectivitytests.update",
      "networkmanagement.locations.get",
      "networkmanagement.locations.list",
      "networkmanagement.operations.cancel",
      "networkmanagement.operations.delete",
      "networkmanagement.operations.get",
      "networkmanagement.operations.list",
      "networkmanagement.vpcflowlogsconfigs.create",
      "networkmanagement.vpcflowlogsconfigs.delete",
      "networkmanagement.vpcflowlogsconfigs.get",
      "networkmanagement.vpcflowlogsconfigs.list",
      "networkmanagement.vpcflowlogsconfigs.update",
      "networksecurity.addressGroups.get",
      "networksecurity.addressGroups.list",
      "networksecurity.addressGroups.use",
      "networksecurity.authorizationPolicies.get",
      "networksecurity.authorizationPolicies.list",
      "networksecurity.authorizationPolicies.use",
      "networksecurity.authzPolicies.get",
      "networksecurity.authzPolicies.list",
      "networksecurity.clientTlsPolicies.get",
      "networksecurity.clientTlsPolicies.list",
      "networksecurity.clientTlsPolicies.use",
      "networksecurity.firewallEndpointAssociations.get",
      "networksecurity.firewallEndpointAssociations.list",
      "networksecurity.gatewaySecurityPolicies.get",
      "networksecurity.gatewaySecurityPolicies.list",
      "networksecurity.gatewaySecurityPolicies.use",
      "networksecurity.gatewaySecurityPolicyRules.get",
      "networksecurity.gatewaySecurityPolicyRules.list",
      "networksecurity.gatewaySecurityPolicyRules.use",
      "networksecurity.locations.get",
      "networksecurity.locations.list",
      "networksecurity.operations.get",
      "networksecurity.operations.list",
      "networksecurity.securityProfileGroups.get",
      "networksecurity.securityProfileGroups.list",
      "networksecurity.securityProfileGroups.use",
      "networksecurity.securityProfiles.get",
      "networksecurity.securityProfiles.list",
      "networksecurity.securityProfiles.use",
      "networksecurity.serverTlsPolicies.get",
      "networksecurity.serverTlsPolicies.list",
      "networksecurity.serverTlsPolicies.use",
      "networksecurity.tlsInspectionPolicies.get",
      "networksecurity.tlsInspectionPolicies.list",
      "networksecurity.tlsInspectionPolicies.use",
      "networksecurity.urlLists.get",
      "networksecurity.urlLists.list",
      "networksecurity.urlLists.use",
      "networkservices.authzExtensions.create",
      "networkservices.authzExtensions.delete",
      "networkservices.authzExtensions.get",
      "networkservices.authzExtensions.list",
      "networkservices.authzExtensions.update",
      "networkservices.authzExtensions.use",
      "networkservices.endpointPolicies.create",
      "networkservices.endpointPolicies.delete",
      "networkservices.endpointPolicies.get",
      "networkservices.endpointPolicies.list",
      "networkservices.endpointPolicies.update",
      "networkservices.gateways.create",
      "networkservices.gateways.delete",
      "networkservices.gateways.get",
      "networkservices.gateways.list",
      "networkservices.gateways.update",
      "networkservices.gateways.use",
      "networkservices.grpcRoutes.create",
      "networkservices.grpcRoutes.delete",
      "networkservices.grpcRoutes.get",
      "networkservices.grpcRoutes.list",
      "networkservices.grpcRoutes.update",
      "networkservices.httpFilters.create",
      "networkservices.httpFilters.delete",
      "networkservices.httpFilters.get",
      "networkservices.httpFilters.list",
      "networkservices.httpFilters.update",
      "networkservices.httpRoutes.create",
      "networkservices.httpRoutes.delete",
      "networkservices.httpRoutes.get",
      "networkservices.httpRoutes.list",
      "networkservices.httpRoutes.update",
      "networkservices.httpfilters.create",
      "networkservices.httpfilters.delete",
      "networkservices.httpfilters.get",
      "networkservices.httpfilters.getIamPolicy",
      "networkservices.httpfilters.list",
      "networkservices.httpfilters.setIamPolicy",
      "networkservices.httpfilters.update",
      "networkservices.httpfilters.use",
      "networkservices.lbRouteExtensions.create",
      "networkservices.lbRouteExtensions.delete",
      "networkservices.lbRouteExtensions.get",
      "networkservices.lbRouteExtensions.list",
      "networkservices.lbRouteExtensions.update",
      "networkservices.lbTrafficExtensions.create",
      "networkservices.lbTrafficExtensions.delete",
      "networkservices.lbTrafficExtensions.get",
      "networkservices.lbTrafficExtensions.list",
      "networkservices.lbTrafficExtensions.update",
      "networkservices.locations.get",
      "networkservices.locations.list",
      "networkservices.meshes.create",
      "networkservices.meshes.delete",
      "networkservices.meshes.get",
      "networkservices.meshes.list",
      "networkservices.meshes.update",
      "networkservices.meshes.use",
      "networkservices.operations.cancel",
      "networkservices.operations.delete",
      "networkservices.operations.get",
      "networkservices.operations.list",
      "networkservices.route_views.get",
      "networkservices.route_views.list",
      "networkservices.serviceBindings.create",
      "networkservices.serviceBindings.delete",
      "networkservices.serviceBindings.get",
      "networkservices.serviceBindings.list",
      "networkservices.serviceBindings.update",
      "networkservices.serviceLbPolicies.create",
      "networkservices.serviceLbPolicies.delete",
      "networkservices.serviceLbPolicies.get",
      "networkservices.serviceLbPolicies.list",
      "networkservices.serviceLbPolicies.update",
      "networkservices.tcpRoutes.create",
      "networkservices.tcpRoutes.delete",
      "networkservices.tcpRoutes.get",
      "networkservices.tcpRoutes.list",
      "networkservices.tcpRoutes.update",
      "networkservices.tlsRoutes.create",
      "networkservices.tlsRoutes.delete",
      "networkservices.tlsRoutes.get",
      "networkservices.tlsRoutes.list",
      "networkservices.tlsRoutes.update",
      "oauthconfig.clientpolicy.get",
      "oauthconfig.testusers.get",
      "oauthconfig.testusers.update",
      "oauthconfig.verification.get",
      "oauthconfig.verification.submit",
      "oauthconfig.verification.update",
      "observability.scopes.get",
      "observability.scopes.update",
      "pubsub.schemas.attach",
      "pubsub.schemas.commit",
      "pubsub.schemas.create",
      "pubsub.schemas.delete",
      "pubsub.schemas.get",
      "pubsub.schemas.getIamPolicy",
      "pubsub.schemas.list",
      "pubsub.schemas.listRevisions",
      "pubsub.schemas.rollback",
      "pubsub.schemas.setIamPolicy",
      "pubsub.schemas.validate",
      "pubsub.snapshots.create",
      "pubsub.snapshots.delete",
      "pubsub.snapshots.get",
      "pubsub.snapshots.getIamPolicy",
      "pubsub.snapshots.list",
      "pubsub.snapshots.seek",
      "pubsub.snapshots.setIamPolicy",
      "pubsub.snapshots.update",
      "pubsub.subscriptions.consume",
      "pubsub.subscriptions.create",
      "pubsub.subscriptions.delete",
      "pubsub.subscriptions.get",
      "pubsub.subscriptions.getIamPolicy",
      "pubsub.subscriptions.list",
      "pubsub.subscriptions.setIamPolicy",
      "pubsub.subscriptions.update",
      "pubsub.topics.attachSubscription",
      "pubsub.topics.create",
      "pubsub.topics.delete",
      "pubsub.topics.detachSubscription",
      "pubsub.topics.get",
      "pubsub.topics.getIamPolicy",
      "pubsub.topics.list",
      "pubsub.topics.publish",
      "pubsub.topics.setIamPolicy",
      "pubsub.topics.update",
      "pubsub.topics.updateTag",
      "resourcemanager.hierarchyNodes.createTagBinding",
      "resourcemanager.hierarchyNodes.deleteTagBinding",
      "resourcemanager.hierarchyNodes.listEffectiveTags",
      "resourcemanager.hierarchyNodes.listTagBindings",
      "resourcemanager.projects.createBillingAssignment",
      "resourcemanager.projects.createPolicyBinding",
      "resourcemanager.projects.delete",
      "resourcemanager.projects.deleteBillingAssignment",
      "resourcemanager.projects.deletePolicyBinding",
      "resourcemanager.projects.get",
      "resourcemanager.projects.getIamPolicy",
      "resourcemanager.projects.move",
      "resourcemanager.projects.searchPolicyBindings",
      "resourcemanager.projects.setIamPolicy",
      "resourcemanager.projects.undelete",
      "resourcemanager.projects.update",
      "resourcemanager.projects.updateLiens",
      "resourcemanager.projects.updatePolicyBinding",
      "resourcemanager.tagHolds.create",
      "resourcemanager.tagHolds.delete",
      "resourcemanager.tagHolds.list",
      "resourcemanager.tagKeys.create",
      "resourcemanager.tagKeys.delete",
      "resourcemanager.tagKeys.get",
      "resourcemanager.tagKeys.getIamPolicy",
      "resourcemanager.tagKeys.list",
      "resourcemanager.tagKeys.setIamPolicy",
      "resourcemanager.tagKeys.update",
      "resourcemanager.tagValueBindings.create",
      "resourcemanager.tagValueBindings.delete",
      "resourcemanager.tagValues.create",
      "resourcemanager.tagValues.delete",
      "resourcemanager.tagValues.get",
      "resourcemanager.tagValues.getIamPolicy",
      "resourcemanager.tagValues.list",
      "resourcemanager.tagValues.setIamPolicy",
      "resourcemanager.tagValues.update",
      "run.configurations.get",
      "run.configurations.list",
      "run.executions.cancel",
      "run.executions.delete",
      "run.executions.get",
      "run.executions.list",
      "run.jobs.create",
      "run.jobs.createTagBinding",
      "run.jobs.delete",
      "run.jobs.deleteTagBinding",
      "run.jobs.get",
      "run.jobs.getIamPolicy",
      "run.jobs.list",
      "run.jobs.listEffectiveTags",
      "run.jobs.listTagBindings",
      "run.jobs.run",
      "run.jobs.runWithOverrides",
      "run.jobs.setIamPolicy",
      "run.jobs.update",
      "run.locations.list",
      "run.operations.delete",
      "run.operations.get",
      "run.operations.list",
      "run.revisions.delete",
      "run.revisions.get",
      "run.revisions.list",
      "run.routes.get",
      "run.routes.invoke",
      "run.routes.list",
      "run.services.create",
      "run.services.createTagBinding",
      "run.services.delete",
      "run.services.deleteTagBinding",
      "run.services.get",
      "run.services.getIamPolicy",
      "run.services.list",
      "run.services.listEffectiveTags",
      "run.services.listTagBindings",
      "run.services.setIamPolicy",
      "run.services.update",
      "run.tasks.get",
      "run.tasks.list",
      "runtimeconfig.configs.create",
      "runtimeconfig.configs.delete",
      "runtimeconfig.configs.get",
      "runtimeconfig.configs.getIamPolicy",
      "runtimeconfig.configs.list",
      "runtimeconfig.configs.setIamPolicy",
      "runtimeconfig.configs.update",
      "runtimeconfig.operations.get",
      "runtimeconfig.operations.list",
      "runtimeconfig.variables.create",
      "runtimeconfig.variables.delete",
      "runtimeconfig.variables.get",
      "runtimeconfig.variables.getIamPolicy",
      "runtimeconfig.variables.list",
      "runtimeconfig.variables.setIamPolicy",
      "runtimeconfig.variables.update",
      "runtimeconfig.variables.watch",
      "runtimeconfig.waiters.create",
      "runtimeconfig.waiters.delete",
      "runtimeconfig.waiters.get",
      "runtimeconfig.waiters.getIamPolicy",
      "runtimeconfig.waiters.list",
      "runtimeconfig.waiters.setIamPolicy",
      "runtimeconfig.waiters.update",
      "secretmanager.locations.get",
      "secretmanager.locations.list",
      "secretmanager.secrets.create",
      "secretmanager.secrets.createTagBinding",
      "secretmanager.secrets.delete",
      "secretmanager.secrets.deleteTagBinding",
      "secretmanager.secrets.get",
      "secretmanager.secrets.getIamPolicy",
      "secretmanager.secrets.list",
      "secretmanager.secrets.listEffectiveTags",
      "secretmanager.secrets.listTagBindings",
      "secretmanager.secrets.setIamPolicy",
      "secretmanager.secrets.update",
      "secretmanager.versions.access",
      "secretmanager.versions.add",
      "secretmanager.versions.destroy",
      "secretmanager.versions.disable",
      "secretmanager.versions.enable",
      "secretmanager.versions.get",
      "secretmanager.versions.list",
      "securedlandingzone.overwatches.activate",
      "securedlandingzone.overwatches.create",
      "securedlandingzone.overwatches.delete",
      "securedlandingzone.overwatches.get",
      "securedlandingzone.overwatches.list",
      "securedlandingzone.overwatches.suspend",
      "securedlandingzone.overwatches.update",
      "securitycenter.assets.group",
      "securitycenter.assets.list",
      "securitycenter.assets.listAssetPropertyNames",
      "securitycenter.assets.runDiscovery",
      "securitycenter.assetsecuritymarks.update",
      "securitycenter.bigQueryExports.create",
      "securitycenter.bigQueryExports.delete",
      "securitycenter.bigQueryExports.get",
      "securitycenter.bigQueryExports.list",
      "securitycenter.bigQueryExports.update",
      "securitycenter.billingtier.update",
      "securitycenter.complianceReports.aggregate",
      "securitycenter.compliancesnapshots.list",
      "securitycenter.containerthreatdetectionsettings.calculate",
      "securitycenter.containerthreatdetectionsettings.get",
      "securitycenter.containerthreatdetectionsettings.update",
      "securitycenter.effectivesecurityhealthanalyticscustommodules.get",
      "securitycenter.effectivesecurityhealthanalyticscustommodules.list",
      "securitycenter.eventthreatdetectionsettings.calculate",
      "securitycenter.eventthreatdetectionsettings.get",
      "securitycenter.eventthreatdetectionsettings.update",
      "securitycenter.findingexplanations.get",
      "securitycenter.findingexternalsystems.update",
      "securitycenter.findings.bulkMuteUpdate",
      "securitycenter.findings.group",
      "securitycenter.findings.list",
      "securitycenter.findings.listFindingPropertyNames",
      "securitycenter.findings.setMute",
      "securitycenter.findings.setState",
      "securitycenter.findings.setWorkflowState",
      "securitycenter.findings.update",
      "securitycenter.findingsecuritymarks.update",
      "securitycenter.integratedvulnerabilityscannersettings.calculate",
      "securitycenter.integratedvulnerabilityscannersettings.get",
      "securitycenter.integratedvulnerabilityscannersettings.update",
      "securitycenter.muteconfigs.create",
      "securitycenter.muteconfigs.delete",
      "securitycenter.muteconfigs.get",
      "securitycenter.muteconfigs.list",
      "securitycenter.muteconfigs.update",
      "securitycenter.notificationconfig.create",
      "securitycenter.notificationconfig.delete",
      "securitycenter.notificationconfig.get",
      "securitycenter.notificationconfig.list",
      "securitycenter.notificationconfig.update",
      "securitycenter.rapidvulnerabilitydetectionsettings.calculate",
      "securitycenter.rapidvulnerabilitydetectionsettings.get",
      "securitycenter.rapidvulnerabilitydetectionsettings.update",
      "securitycenter.securitycentersettings.get",
      "securitycenter.securitycentersettings.update",
      "securitycenter.securityhealthanalyticscustommodules.create",
      "securitycenter.securityhealthanalyticscustommodules.delete",
      "securitycenter.securityhealthanalyticscustommodules.get",
      "securitycenter.securityhealthanalyticscustommodules.list",
      "securitycenter.securityhealthanalyticscustommodules.simulate",
      "securitycenter.securityhealthanalyticscustommodules.test",
      "securitycenter.securityhealthanalyticscustommodules.update",
      "securitycenter.securityhealthanalyticssettings.calculate",
      "securitycenter.securityhealthanalyticssettings.get",
      "securitycenter.securityhealthanalyticssettings.update",
      "securitycenter.sources.get",
      "securitycenter.sources.getIamPolicy",
      "securitycenter.sources.list",
      "securitycenter.sources.setIamPolicy",
      "securitycenter.sources.update",
      "securitycenter.userinterfacemetadata.get",
      "securitycenter.virtualmachinethreatdetectionsettings.calculate",
      "securitycenter.virtualmachinethreatdetectionsettings.get",
      "securitycenter.virtualmachinethreatdetectionsettings.update",
      "securitycenter.vulnerabilitysnapshots.list",
      "securitycenter.websecurityscannersettings.calculate",
      "securitycenter.websecurityscannersettings.get",
      "securitycenter.websecurityscannersettings.update",
      "securitycentermanagement.effectiveEventThreatDetectionCustomModules.get",
      "securitycentermanagement.effectiveEventThreatDetectionCustomModules.list",
      "securitycentermanagement.effectiveSecurityHealthAnalyticsCustomModules.get",
      "securitycentermanagement.effectiveSecurityHealthAnalyticsCustomModules.list",
      "securitycentermanagement.eventThreatDetectionCustomModules.create",
      "securitycentermanagement.eventThreatDetectionCustomModules.delete",
      "securitycentermanagement.eventThreatDetectionCustomModules.get",
      "securitycentermanagement.eventThreatDetectionCustomModules.list",
      "securitycentermanagement.eventThreatDetectionCustomModules.update",
      "securitycentermanagement.eventThreatDetectionCustomModules.validate",
      "securitycentermanagement.locations.get",
      "securitycentermanagement.locations.list",
      "securitycentermanagement.securityCenterServices.get",
      "securitycentermanagement.securityCenterServices.list",
      "securitycentermanagement.securityCenterServices.update",
      "securitycentermanagement.securityCommandCenter.activate",
      "securitycentermanagement.securityCommandCenter.checkActivationOperation",
      "securitycentermanagement.securityCommandCenter.checkEligibility",
      "securitycentermanagement.securityCommandCenter.generateServiceAccounts",
      "securitycentermanagement.securityCommandCenter.get",
      "securitycentermanagement.securityCommandCenter.update",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.create",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.delete",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.get",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.list",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.simulate",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.test",
      "securitycentermanagement.securityHealthAnalyticsCustomModules.update",
      "servicemanagement.services.bind",
      "servicemanagement.services.check",
      "servicemanagement.services.create",
      "servicemanagement.services.delete",
      "servicemanagement.services.get",
      "servicemanagement.services.getIamPolicy",
      "servicemanagement.services.list",
      "servicemanagement.services.quota",
      "servicemanagement.services.report",
      "servicemanagement.services.setIamPolicy",
      "servicemanagement.services.update",
      "servicenetworking.operations.cancel",
      "servicenetworking.operations.delete",
      "servicenetworking.operations.get",
      "servicenetworking.operations.list",
      "servicenetworking.services.addDnsRecordSet",
      "servicenetworking.services.addDnsZone",
      "servicenetworking.services.addPeering",
      "servicenetworking.services.addSubnetwork",
      "servicenetworking.services.createPeeredDnsDomain",
      "servicenetworking.services.deleteConnection",
      "servicenetworking.services.deletePeeredDnsDomain",
      "servicenetworking.services.disableVpcServiceControls",
      "servicenetworking.services.enableVpcServiceControls",
      "servicenetworking.services.get",
      "servicenetworking.services.getConsumerConfig",
      "servicenetworking.services.listPeeredDnsDomains",
      "servicenetworking.services.removeDnsRecordSet",
      "servicenetworking.services.removeDnsZone",
      "servicenetworking.services.updateConsumerConfig",
      "servicenetworking.services.updateDnsRecordSet",
      "servicenetworking.services.use",
      "servicesecurityinsights.clusterSecurityInfo.get",
      "servicesecurityinsights.clusterSecurityInfo.list",
      "servicesecurityinsights.policies.get",
      "servicesecurityinsights.projectStates.get",
      "servicesecurityinsights.securityInfo.list",
      "servicesecurityinsights.securityViews.get",
      "servicesecurityinsights.workloadPolicies.list",
      "servicesecurityinsights.workloadSecurityInfo.get",
      "serviceusage.quotas.get",
      "serviceusage.quotas.update",
      "serviceusage.services.get",
      "serviceusage.services.list",
      "serviceusage.services.use",
      "source.repos.create",
      "source.repos.delete",
      "source.repos.get",
      "source.repos.getIamPolicy",
      "source.repos.getProjectConfig",
      "source.repos.list",
      "source.repos.setIamPolicy",
      "source.repos.updateProjectConfig",
      "source.repos.updateRepoConfig",
      "storage.buckets.create",
      "storage.buckets.createTagBinding",
      "storage.buckets.delete",
      "storage.buckets.deleteTagBinding",
      "storage.buckets.enableObjectRetention",
      "storage.buckets.getObjectInsights",
      "storage.buckets.list",
      "storage.buckets.listEffectiveTags",
      "storage.buckets.listTagBindings",
      "storage.folders.create",
      "storage.folders.delete",
      "storage.folders.get",
      "storage.folders.list",
      "storage.folders.rename",
      "storage.hmacKeys.create",
      "storage.hmacKeys.delete",
      "storage.hmacKeys.get",
      "storage.hmacKeys.list",
      "storage.hmacKeys.update",
      "storage.managementHubs.get",
      "storage.managementHubs.update",
      "storage.objects.get",
      "storage.objects.list",
      "vpcaccess.connectors.create",
      "vpcaccess.connectors.delete",
      "vpcaccess.connectors.get",
      "vpcaccess.connectors.list",
      "vpcaccess.connectors.update",
      "vpcaccess.connectors.use",
      "vpcaccess.locations.list",
      "vpcaccess.operations.get",
      "vpcaccess.operations.list",
      "workflows.callbacks.list",
      "workflows.callbacks.send",
      "workflows.executions.cancel",
      "workflows.executions.create",
      "workflows.executions.get",
      "workflows.executions.list",
      "workflows.locations.get",
      "workflows.locations.list",
      "workflows.operations.cancel",
      "workflows.operations.get",
      "workflows.operations.list",
      "workflows.stepEntries.get",
      "workflows.stepEntries.list",
      "workflows.workflows.create",
      "workflows.workflows.delete",
      "workflows.workflows.get",
      "workflows.workflows.list",
      "workflows.workflows.listRevision",
      "workflows.workflows.update"
    ]
  }
}
