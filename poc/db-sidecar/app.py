import os
from flask import Flask, jsonify
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

app = Flask(__name__)

# Core principle: The environment dictates how we connect.
# Production: postgresql+psycopg2://<sa_name>@127.0.0.1:5432/<db>
# Test/Local: postgresql+psycopg2://<user>:<pass>@<host>:<port>/<db>
DATABASE_URL = os.getenv("DB_URL")

if not DATABASE_URL:
    raise ValueError("DB_URL environment variable must be set!")

engine = create_engine(DATABASE_URL, pool_size=5, max_overflow=10)
SessionLocal = sessionmaker(bind=engine)

@app.route("/health")
def health():
    try:
        with SessionLocal() as session:
            # Quick check to ensure the connection works
            result = session.execute(text("SELECT current_user, now();")).fetchone()
            return jsonify({
                "status": "healthy",
                "db_user": result[0],
                "db_time": str(result[1])
            }), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 8080)))
