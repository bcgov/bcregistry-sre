mpf_projects = {
  "mpf" = {
    project_id = "google-mpf-547144339658"
    env = "mpf"
    iam_bindings = [
      {
        role    = "projects/google-mpf-547144339658/roles/monitoring_reader"
        members = ["andriy.bolyachevets@gov.bc.ca"]
      }
    ]
    custom_roles = {
      monitoring_reader = {
        title = "Monitoring Reader"
        description = "Read-only access to monitoring and logging"
        permissions = [
          "resourcemanager.projects.get",
          "serviceusage.services.get",
          "serviceusage.services.list",
          "monitoring.dashboards.get",
          "monitoring.dashboards.list",
          "monitoring.timeSeries.list",
          "monitoring.metricDescriptors.get",
          "monitoring.metricDescriptors.list",
          "monitoring.monitoredResourceDescriptors.get",
          "monitoring.monitoredResourceDescriptors.list",
          "monitoring.alertPolicies.get",
          "monitoring.alertPolicies.list",
          "monitoring.notificationChannels.get",
          "monitoring.notificationChannels.list",
          "monitoring.groups.get",
          "monitoring.groups.list",
          "monitoring.uptimeCheckConfigs.get",
          "monitoring.uptimeCheckConfigs.list",
          "logging.logs.list",
          "logging.logEntries.list",
          "logging.views.get",
          "logging.views.list",
          "logging.logMetrics.get",
          "logging.logMetrics.list",
          "logging.exclusions.get",
          "logging.exclusions.list"
        ]
      }
    }
  }
}
