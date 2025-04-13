import logging
import os
import re
import tempfile
import time

import functions_framework
from google.api_core import retry
from google.auth import default
from google.cloud import storage
from googleapiclient import discovery
from googleapiclient.errors import HttpError


@functions_framework.http
def grant_db_role(request):
    """HTTP Cloud Function to grant existing database roles to users in Cloud SQL."""
    try:
        if request.method != 'POST':
            return {'error': 'Only POST requests are supported'}, 405

        request_json = request.get_json()
        required = ['instance_name', 'database', 'user', 'role', 'gcs_uri']
        if any(param not in request_json for param in required):
            return {'error': f'Missing required parameters: {required}'}, 400

        try:
            project, region, instance = request_json['instance_name'].split(':')
        except ValueError:
            return {'error': 'instance_name must be "project:region:instance"'}, 400

        user = request_json['user']
        role = request_json['role']
        
        if not re.match(r'^[a-zA-Z0-9_]+$', role):
            return {'error': 'Role name contains invalid characters (only letters, numbers and underscores allowed)'}, 400

        # Only quote role if it contains special characters or is mixed case
        role_identifier = f'"{role}"' if any(c in role for c in ' -') or role != role.lower() else role

        # Create compact SQL content
        sql_content = f"GRANT {role_identifier} TO \"{user}\";"

        # Create temporary SQL file
        with tempfile.NamedTemporaryFile(suffix='.sql', delete=False) as temp_file:
            temp_file.write(sql_content.encode('utf-8'))
            temp_file_path = temp_file.name

        try:
            # Upload to GCS
            gcs_uri = request_json['gcs_uri']
            if not gcs_uri.startswith('gs://'):
                return {'error': 'gcs_uri must start with gs://'}, 400

            bucket_name = gcs_uri[5:].split('/')[0]
            blob_name = os.path.join(*gcs_uri[5:].split('/')[1:], f"grant_role_{role}_{user.replace('@', '_at_')}.sql")

            storage_client = storage.Client()
            bucket = storage_client.bucket(bucket_name)
            blob = bucket.blob(blob_name)
            blob.upload_from_filename(temp_file_path)
            logging.info(f"File uploaded to gs://{bucket_name}/{blob_name}")

            # Get credentials for SQL Admin API
            credentials, _ = default()
            sqladmin = discovery.build('sqladmin', 'v1',
                               credentials=credentials,
                               cache_discovery=False)

            import_body = {
                'importContext': {
                    'uri': f"gs://{bucket_name}/{blob_name}",
                    'database': request_json['database'],
                    'fileType': 'SQL'
                }
            }

            # Custom retry for operationInProgress errors
            def should_retry(exc):
                if isinstance(exc, HttpError):
                    return exc.resp.status == 409 and 'operationInProgress' in str(exc)
                return False

            custom_retry = retry.Retry(
                predicate=should_retry,
                initial=1,
                maximum=60,
                multiplier=2,
                deadline=300
            )

            try:
                # Start import operation
                response = custom_retry(
                    sqladmin.instances().import_(
                        project=project,
                        instance=instance,
                        body=import_body
                    ).execute
                )()
                operation_name = response['name']
                logging.info(f"Started import operation: {operation_name}")
                # Wait a few seconds to ensure Cloud SQL has accessed the file
                time.sleep(10)
            except HttpError as e:
                if 'role' in str(e).lower() and 'does not exist' in str(e).lower():
                    return {'error': f'Role {role} does not exist in the database'}, 400
                raise

            # Delete the file after successful import initiation
            file_deleted = False
            try:
                blob.delete()
                file_deleted = True
                logging.info(f"Deleted file gs://{bucket_name}/{blob_name}")
            except Exception as delete_error:
                logging.warning(f"Failed to delete file {blob_name}: {str(delete_error)}")

            return {
                'status': 'success',
                'operationId': response['name'],
                'database': request_json['database'],
                'user': user,
                'role_granted': role,
                'sql_executed': sql_content.strip(),
                'gcs_file_deleted': file_deleted,
                'original_gcs_uri': f"gs://{bucket_name}/{blob_name}"
            }, 200

        finally:
            # Clean up temporary file
            try:
                os.unlink(temp_file_path)
            except Exception as temp_file_error:
                logging.warning(f"Failed to delete temporary file {temp_file_path}: {str(temp_file_error)}")

    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {'error': str(e)}, 500