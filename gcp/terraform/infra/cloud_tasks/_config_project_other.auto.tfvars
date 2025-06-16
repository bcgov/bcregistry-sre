prod_projects = {
  "bcr-businesses-sandbox" = {
    project_id = "a083gt-sandbox"
    env = "sandbox"
    instances = [
        {
          instance = "namex-emailer-pending-send-queue-sandbox"
          max_dispatches_per_second = 5
          max_concurrent_dispatches = 100
          max_attempts = 3
          max_retry_duration = "60s"
          min_backoff = "5s"
          max_backoff = "5s"
          max_doublings = 0
          sampling_ratio = 1.0
        }
    ]
  }
}
  