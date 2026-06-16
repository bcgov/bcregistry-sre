import os
import subprocess

# Auto-detect active Docker context endpoint if not explicitly set
if "DOCKER_HOST" not in os.environ:
    try:
        docker_host = subprocess.check_output(
            ["docker", "context", "inspect", "--format", "{{.Endpoints.docker.Host}}"],
            text=True,
            stderr=subprocess.DEVNULL
        ).strip()
        if docker_host:
            os.environ["DOCKER_HOST"] = docker_host
    except Exception:
        # Fallback to typical macOS Docker Desktop path
        home_socket = os.path.expanduser("~/.docker/run/docker.sock")
        if os.path.exists(home_socket):
            os.environ["DOCKER_HOST"] = f"unix://{home_socket}"

os.environ.setdefault("DB_URL", "postgresql+psycopg2://dummy:dummy@localhost:5432/dummy")

import pytest
from testcontainers.postgres import PostgresContainer
from app import app as flask_app, SessionLocal, engine as default_engine
from sqlalchemy import create_engine

@pytest.fixture(scope="session")
def postgres_container():
    """Spins up a throwaway Postgres container for the test session."""
    with PostgresContainer("postgres:15-alpine") as postgres:
        yield postgres

@pytest.fixture(scope="session", autouse=True)
def setup_test_database(postgres_container):
    """
    Dynamically swaps out the Flask app's engine 
    to target the throwaway testcontainer.
    """
    test_db_url = postgres_container.get_connection_url()
    
    # Reconfigure the global engine & session factory used by app.py
    global default_engine, SessionLocal
    test_engine = create_engine(test_db_url)
    
    import app
    app.engine = test_engine
    app.SessionLocal.configure(bind=test_engine)
    
    # Execute structural setups if needed (e.g., Base.metadata.create_all(test_engine))
    yield
    
    test_engine.dispose()

@pytest.fixture()
def client():
    """Provides a native Flask test client."""
    with flask_app.test_client() as client:
        yield client

def test_health_endpoint_against_container(client):
    """Verifies that the Flask app integrates perfectly with a raw Postgres connection."""
    response = client.get("/health")
    assert response.status_code == 200
    
    data = response.get_json()
    assert data["status"] == "healthy"
    # Vanilla Postgres test containers default to user 'test'
    assert data["db_user"] == "test"
