mpf_projects = {
  "mpf" = {
    project_id = "google-mpf-547144339658"
    env        = "mpf"
    iam_bindings = [
      {
        role = "projects/google-mpf-547144339658/roles/monitoring_reader"
        members = [
          "andriy.bolyachevets@gov.bc.ca",
          "reema.sagpariya@gov.bc.ca",
          "gunasegaran.nagarajan@gov.bc.ca",
          "kial.jinnah@gov.bc.ca",
          "megan.a.wong@gov.bc.ca",
          "mark.ruffolo@gov.bc.ca",
          "mihai.dinu@gov.bc.ca",
          "vikas.singh@gov.bc.ca",
          "melissa.stanton@gov.bc.ca",
        ]
      }
    ]
    custom_roles = {
      monitoring_reader = {
        title       = "Monitoring Reader"
        description = "Read-only access to monitoring and logging"
        permissions = [
          "cloudnotifications.activities.list",
          "resourcemanager.projects.get",
          "serviceusage.services.get",
          "serviceusage.services.list",
          "monitoring.dashboards.get",
          "monitoring.dashboards.list",
          "monitoring.alerts.get",
          "monitoring.alerts.list",
          "monitoring.incidents.get",
          "monitoring.incidents.list",
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
          "monitoring.services.get",
          "monitoring.services.list",
          "monitoring.slos.get",
          "monitoring.slos.list",
          "monitoring.snoozes.get",
          "monitoring.snoozes.list",
          "monitoring.uptimeCheckConfigs.get",
          "monitoring.uptimeCheckConfigs.list",
          "monitoring.notificationChannelDescriptors.get",
          "monitoring.notificationChannelDescriptors.list",
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
