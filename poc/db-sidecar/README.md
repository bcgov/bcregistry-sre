# Cloud Run Multi-Container Sidecar Demo App

This project implements a high-performance Flask application deployed on Cloud Run with a Go-based Cloud SQL Auth Proxy sidecar container, utilizing psycopg2 and IAM database authentication.

## Project Structure

- [app.py](file:///Users/thor/Developer/thor.dev/db-sidecar/app.py) - The synchronous Flask application using SQLAlchemy 2.0.
- [test_app.py](file:///Users/thor/Developer/thor.dev/db-sidecar/test_app.py) - Integration tests using `pytest` and `testcontainers` to run tests against an ephemeral PostgreSQL Docker container.
- [Dockerfile](file:///Users/thor/Developer/thor.dev/db-sidecar/Dockerfile) - Minimal container specification for packaging the Flask application.
- [service.yaml.template](file:///Users/thor/Developer/thor.dev/db-sidecar/service.yaml.template) - Template for the Cloud Run service configuration (compiled into `service.yaml` at deploy-time).
- [requirements.txt](file:///Users/thor/Developer/thor.dev/db-sidecar/requirements.txt) - Python package dependencies.
- **scripts/** - Automation and setup utility scripts:
  - [scripts/setup_iam.sh](file:///Users/thor/Developer/thor.dev/db-sidecar/scripts/setup_iam.sh) - Creates the `sa-cloud-run-db-user` service account and grants it the necessary Cloud SQL roles.
  - [scripts/setup_db.sql](file:///Users/thor/Developer/thor.dev/db-sidecar/scripts/setup_db.sql) - Database grants/onboarding script for the database instance.
  - [scripts/run_tests.sh](file:///Users/thor/Developer/thor.dev/db-sidecar/scripts/run_tests.sh) - Utility script to detect active Docker context and run integration tests.
  - [scripts/build_and_deploy.sh](file:///Users/thor/Developer/thor.dev/db-sidecar/scripts/build_and_deploy.sh) - Script to build the container using Cloud Build and deploy the dual-container architecture to Cloud Run.

## Prerequisites

1. Install Python 3.12 (managed via `uv` or system installation).
2. Install `uv` Python package manager (if not already installed).
3. Ensure Docker daemon is running locally (needed for integration tests).

## Local Development & Testing

1. Create a virtual environment and install dependencies:
   ```bash
   uv venv --python 3.12
   uv pip install -r requirements.txt
   ```

2. Run the integration tests locally:
   ```bash
   uv run pytest
   ```
   *(Alternatively, you can run `./scripts/run_tests.sh` which wraps the environment socket detection)*

## Cloud Deployment

### 1. Provision IAM & Roles
To set up the service account and permissions on Google Cloud:
```bash
./scripts/setup_iam.sh
```

### 2. Create DB User and Configure Database Grants
To provision the Cloud SQL database user and compile the SQL permissions script:
```bash
./scripts/setup_db.sh
```
Then, connect to your Postgres database and execute the statements inside the dynamically compiled **scripts/setup_db.sql** to grant schema permissions.

### 3. Build & Deploy to Cloud Run
To package your app via Cloud Build and deploy to Cloud Run:
```bash
./scripts/build_and_deploy.sh
```

### 4. Testing the Deployed Service
By default, the Cloud Run service is created private and will return a **403 Forbidden** for unauthenticated requests. Additionally, the only defined route in the Flask application is `/health`.

You can test the deployment using one of two methods:

#### Option A: Authenticated Request (Recommended)
Pass your active GCP credential's identity token in the authorization header:
```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://flask-fast-iam-service-366678529892.northamerica-northeast1.run.app/health
```

#### Option B: Allow Public Access (Unauthenticated)
To expose the service publicly for testing, run the following command:
```bash
gcloud run services add-iam-policy-binding flask-fast-iam-service \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --region="northamerica-northeast1"
```
Once public, you can call the health check endpoint directly:
```bash
curl https://flask-fast-iam-service-366678529892.northamerica-northeast1.run.app/health
```
