#!/bin/sh
set -eu

app_directory=${1:?App directory is required}
if [ -f "$app_directory/.frontend-shared-source.tar" ]; then
  tar -xf "$app_directory/.frontend-shared-source.tar" -C "$(dirname "$app_directory")"
fi
