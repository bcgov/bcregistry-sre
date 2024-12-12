import base64
import json
import logging
import os
import uuid
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from google.cloud import secretmanager, resourcemanager_v3, scheduler_v1
from google.cloud.sql.connector import Connector, IPTypes
from google.iam.v1 import policy_pb2
from google.type import expr_pb2
from googleapiclient.discovery import build
import pg8000
import sqlalchemy
import functions_framework

# Environment variables
instance_connection_name = os.environ['DB_INSTANCE_CONNECTION_NAME']
username = os.environ['DB_USER']
dbname = os.environ['DB_NAME']
project_number = os.environ['PROJECT_NUMBER']
project_id = os.environ['PROJECT_ID']
secret_id = os.environ['SECRET_ID']
secret_name = f"projects/{project_number}/secrets/{secret_id}/versions/latest"

# Fetch the database password from Secret Manager
client = secretmanager.SecretManagerServiceClient()
response = client.access_secret_version(name=secret_name)
password = response.payload.data.decode("UTF-8")

# Lazy initialization of global db connection
db = None

def check_user_in_project(user_email, project_id):
    client = resourcemanager_v3.ProjectsClient()
    project_name = f"projects/{project_id}"

    try:
        policy = client.get_iam_policy(request={"resource": project_name})

        for binding in policy.bindings:
            if f"user:{user_email}" in binding.members:
                return True
        return False
    except Exception as e:
        logging.error(f"Error checking user in project: {e}")
        return False

def create_one_time_scheduler_job(project_id, topic_name, role, email, duration):
    client = scheduler_v1.CloudSchedulerClient()

    parent = f"projects/{project_id}/locations/northamerica-northeast1"

    unique_id = uuid.uuid4().hex
    job_name = f"pam-update-grant-job-{unique_id}"
    full_name = f"projects/{project_id}/locations/northamerica-northeast1/jobs/{job_name}"

    message_data = {
        "status": "expired",
        "grant": role,
        "user": email,
        "job_name": full_name
    }

    data_bytes = json.dumps(message_data).encode("utf-8")

    pubsub_target = scheduler_v1.PubsubTarget(
        topic_name=f"projects/{project_id}/topics/{topic_name}",
        data=data_bytes
    )

    desired_timezone = ZoneInfo("America/Vancouver")
    current_time_utc = datetime.now(timezone.utc)
    expiration_time = (current_time_utc + timedelta(minutes=duration)).astimezone(desired_timezone)

    schedule = f"{expiration_time.minute} {expiration_time.hour} {expiration_time.day} {expiration_time.month} *"
    job = scheduler_v1.Job(
        name=full_name,
        pubsub_target=pubsub_target,
        schedule=schedule,
        time_zone="America/Vancouver",
    )
    created_job = client.create_job(parent=parent, job=job)
    logging.warning(f'Created job: {created_job.name}')
    return full_name

def create_iam_user(project_id, instance_name, iam_user_email):
    service = build("sqladmin", "v1beta4")

    user_body = {
        "name": iam_user_email,
        "type": "CLOUD_IAM_USER"
    }

    request = service.users().insert(
        project=project_id,
        instance=instance_name.split(":")[-1],
        body=user_body
    )
    response = request.execute()

    logging.warning(f"IAM user {iam_user_email} created successfully!")
    return response


def connect_to_instance_with_retries(retries=5, delay=2) -> sqlalchemy.engine.base.Engine:
    for attempt in range(retries):
        try:
            connector = Connector()

            def getconn() -> pg8000.dbapi.Connection:
                return connector.connect(
                    instance_connection_string=instance_connection_name,
                    driver="pg8000",
                    user=username,
                    password=password,
                    db=dbname,
                    ip_type=IPTypes.PUBLIC,
                )

            engine = sqlalchemy.create_engine(
                "postgresql+pg8000://",
                creator=getconn,
                pool_size=5,
                max_overflow=2,
                pool_timeout=30,
                pool_recycle=1800,
            ).execution_options(isolation_level="AUTOCOMMIT")

            logging.warning("Database connection successfully established!")
            return engine

        except Exception as e:
            logging.warning(
                f"Database connection attempt {attempt + 1} failed. Retrying in {delay} seconds... Error: {str(e)}"
            )
            time.sleep(delay)

    raise Exception("Failed to connect to the database after multiple attempts.")


@functions_framework.http
def create_pam_grant_request(request):
    try:
        request_json = request.get_json()

        if not request_json or 'assignee' not in request_json or 'entitlement' not in request_json or 'project' not in request_json:
            return json.dumps({'status': 'error', 'message': 'Missing required fields'}), 400

        assignee = request_json['assignee']
        entitlement = request_json['entitlement']
        project = request_json['project']
        duration = request_json['duration']

        if check_user_in_project(assignee, project):

            client = resourcemanager_v3.ProjectsClient()
            project_name = f"projects/{project}"
            entitlement = f"projects/{project}/roles/{entitlement}"

            desired_timezone = ZoneInfo("America/Vancouver")
            current_time_utc = datetime.now(timezone.utc)
            expiration_time = (current_time_utc + timedelta(minutes=duration)).astimezone(desired_timezone).isoformat("T")

            condition = expr_pb2.Expr(
                title="Temporary Access",
                expression=f"request.time < timestamp('{expiration_time}')"
            )



            policy = client.get_iam_policy(request={"resource": project_name})

            # Upgrade policy version to 3 if necessary
            if policy.version < 3:
                policy.version = 3

            # Check if the user already has the role assigned
            existing_binding = None
            for binding in policy.bindings:
                if binding.role == entitlement and f"user:{assignee}" in binding.members:
                    existing_binding = binding
                    break

            if existing_binding:
                # If the user already has the role, check if it has conditions
                if existing_binding.condition:
                    logging.warning(f"User {assignee} already has the role with a condition. Updating condition.")
                    existing_binding.condition = condition
                else:
                    logging.warning(f"User {assignee} already has the role without a condition. Adding condition.")
                    existing_binding.condition = condition
            else:
                new_binding = policy_pb2.Binding(
                    role=entitlement,
                    members=[f"user:{assignee}"],
                    condition=condition,
                )
                policy.bindings.append(new_binding)

            # Update the policy
            client.set_iam_policy(
                request={
                    "resource": project_name,
                    "policy": policy,
                }
            )

            logging.warning('Role assigned to user')
            create_iam_user(project_number, instance_connection_name, assignee)
            logging.warning('IAM user created')
            create_one_time_scheduler_job(project_id, 'pam-revoke-topic', entitlement, assignee, duration)

            global db
            if not db:
                db = connect_to_instance_with_retries()

            with db.connect() as conn:
                grant_readonly_statement = f"GRANT readonly TO \"{assignee}\";"
                conn.execute(sqlalchemy.text(grant_readonly_statement))

            return json.dumps({'status': 'success', 'message': 'PAM grant request processed successfully'}), 200

    except Exception as e:
        logging.error(f"Error creating PAM grant request: {str(e)}")
        return json.dumps({'status': 'error', 'message': str(e)}), 500
