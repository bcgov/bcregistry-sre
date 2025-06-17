# Cloud Tasks Module Documentation

## Prerequisites
This document provides specific guidance for implementing and using the Cloud Tasks module. For general Terraform configuration information, please refer to the main [README.md](./README.md).

## Cloud Tasks Module Overview 
The Cloud Tasks module is designed to create and manage Google Cloud Tasks queues and tasks in a standardized way across different environments. It provides a simple, isolated implementation that focuses solely on Cloud Tasks functionality.

### Configuration Files

There are four configuration files that can be modified:

- `_config_project_dev.auto.tfvars` - for dev environment project configurations
- `_config_project_test.auto.tfvars` - for test environment project configurations
- `_config_project_prod.auto.tfvars` - for prod environment project configurations
- `_config_project_other.auto.tfvars` - for sandbox and tools environment project configurations

### Structure of Project Configuration files (`_config_project_*.auto.tfvars`):

All project configuration files define projects using the following structure:

```hcl
dev_projects or test_projects or prod_projects or other_projects = {
   "project-name" = {
      project_id  = ... # Unique ID for the project
      env         = ... # Environment (e.g., dev, test, prod, sandbox, tools)
      instances = [
         {
            instance = "descriptive-name-for-the-queue"
            max_dispatches_per_second = your-input
            max_concurrent_dispatches = your-input
            max_attempts = your-input
            max_retry_duration = your-input
            min_backoff = your-input
            max_backoff = your-input
            max_doublings = your-input
            sampling_ratio = your-input
         }, 
         {
            ... # Definition for another instance in the same project
         }
      ]
   }
   "my-new-project" = {
      ... # Definition for a new project in the same environment
   }
}
```

### Usage Example

To implement Cloud Tasks in your environment, review the diff below which demonstrates the addition of two new task queues for an existing project and a new project:

```diff
dev_projects or test_projects or prod_projects or other_projects = {
   "project-name" = {
      project_id  = ... # Unique ID for the project
      env         = ... # Environment (e.g., dev, test, prod, sandbox, tools)
      instances = [
         {
            instance = "descriptive-name-for-the-queue"
            max_dispatches_per_second = your-input
            max_concurrent_dispatches = your-input
            max_attempts = your-input
            max_retry_duration = your-input
            min_backoff = your-input
            max_backoff = your-input
            max_doublings = your-input
            sampling_ratio = your-input
-         }
+         },
+        # Adds a new single instance of a task queue to a project with an existing queue
+         {
+            instance = "descriptive-name-for-the-queue"
+            max_dispatches_per_second = your-input
+            max_concurrent_dispatches = your-input
+            max_attempts = your-input
+            max_retry_duration = your-input
+            min_backoff = your-input
+            max_backoff = your-input
+            max_doublings = your-input
+            sampling_ratio = your-input
+         }
      ]
   }
+   # Adds a new project with a single instance of a task queue
+   "my-new-project" = {
+      project_id  = ...
+      env         = ... 
+      instances = [
+         {
+            instance = "descriptive-name-for-the-queue"
+            max_dispatches_per_second = your-input
+            max_concurrent_dispatches = your-input
+            max_attempts = your-input
+            max_retry_duration = your-input
+            min_backoff = your-input
+            max_backoff = your-input
+            max_doublings = your-input
+            sampling_ratio = your-input
+         }
+      ]
+   }
}
```

### Configuration Parameters

#### Required Parameters
- `project_id`: The GCP project ID where the Cloud Tasks will be created
- `region`: The GCP region where the Cloud Tasks will be deployed e.g. northamerica-northeast1

#### Optional Parameters
- `queues`: A map of queue configurations
  - `rate_limits`: Queue rate limiting settings
    - `max_dispatches_per_second`: Maximum number of tasks dispatched per second
    - `max_concurrent_dispatches`: Maximum number of concurrent task dispatches
  - `retry_config`: Task retry configuration
    - `max_attempts`: Maximum number of retry attempts
    - `max_retry_duration`: Maximum duration for retries

## Best Practices

1. **Queue Naming**
   - Use descriptive names that indicate the queue's purpose
   - Follow a consistent naming convention across environments
   - Example: `namex-api-queue`, `payment-processing-queue`

2. **Rate Limiting**
   - Set appropriate rate limits based on your application's needs
   - Consider the downstream service's capacity
   - Monitor queue performance and adjust limits as needed

3. **Retry Configuration**
   - Configure retry attempts based on task criticality
   - Set reasonable retry durations to prevent task backlog
   - Consider implementing dead-letter queues for failed tasks

4. **Cost Estimates**
   - Consider worts case cost estimates and common case const estimates.

## Common Use Cases

1. **API Request Processing**
   - Queue API requests for asynchronous processing
   - Handle rate limiting and retries automatically
   - Example: Namex API request processing

2. **Background Jobs**
   - Process long-running tasks asynchronously
   - Manage task distribution and retries
   - Example: Document processing, report generation

## Security & Integration Considerations

1. **Service Account Permissions**
   - Ensure proper IAM roles are assigned
   - Follow principle of least privilege
   - Regularly audit permissions

2. **Queue Access**
   - Restrict queue access to authorized services
   - Use service account authentication
   - Implement proper IAM policies