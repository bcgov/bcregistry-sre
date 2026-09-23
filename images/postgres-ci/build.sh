#!/bin/bash
docker build --no-cache -t postgres18-postgis-anon .
docker tag postgres18-postgis-anon ghcr.io/bcgov/postgres18-postgis-anon:latest
docker push ghcr.io/bcgov/postgres18-postgis-anon:latest
