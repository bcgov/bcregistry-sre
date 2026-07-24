FROM python:3.13-slim

WORKDIR /app

# Install system dependencies needed for compiling psycopg2 (if using non-binary, but we use psycopg2-binary so it should be fine, but let's keep it minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
