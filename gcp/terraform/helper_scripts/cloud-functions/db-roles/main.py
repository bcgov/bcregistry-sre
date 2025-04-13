import logging

import functions_framework
from google.api_core import retry
from google.auth import default
from googleapiclient import discovery
from googleapiclient.errors import HttpError


@functions_framework.http
def execute_role_management(request):
    """HTTP Cloud Function to manage roles using Cloud SQL Admin API."""
    try:
        if request.method != 'POST':
            return {'error': 'Only POST requests are supported'}, 405

        request_json = request.get_json()
        required = ['instance_name', 'database', 'gcs_uri', 'owner']
        if any(param not in request_json for param in required):
            return {'error': f'Missing required parameters: {required}'}, 400

        try:
            project, region, instance = request_json['instance_name'].split(':')
        except ValueError:
            return {'error': 'instance_name must be "project:region:instance"'}, 400

        credentials, _ = default()
        sqladmin = discovery.build('sqladmin', 'v1beta4',
                                credentials=credentials,
                                cache_discovery=False)
        body = {
            "importContext": {
                "fileType": "SQL",
                "uri": request_json['gcs_uri'],
                "database": request_json['database'],
                "importUser": request_json['owner'],
                "bakImportOptions": {
                    "noOwner": True,
                    "noTablespaces": True
                }
            }
        }

        # Custom retry for operationInProgress errors
        def should_retry(exc):
            if isinstance(exc, HttpError):
                return exc.resp.status == 409 and 'operationInProgress' in str(exc)
            return False

        custom_retry = retry.Retry(
            predicate=should_retry,
            initial=1,  # 1 second initial wait
            maximum=60,  # 60 seconds maximum wait
            multiplier=2,  # Exponential backoff
            deadline=300  # 5 minutes total timeout
        )

        response = custom_retry(
            sqladmin.instances().import_(
                project=project,
                instance=instance,
                body=body
            ).execute
        )()

        return {
            'status': 'success',
            'operationId': response['name'],
            'gcs_uri': request_json['gcs_uri'],
            'import_user_used': request_json['owner'],
            'method': 'users_api_approach'
        }, 200

    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {'error': str(e)}, 500