#!/bin/bash
# start.sh

set -e

FILE_DIR="start.sh"
echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

BENCH_DIR="/workspace/development/frappe-bench"
cd "$BENCH_DIR"

echo "Starting bench with honcho..."

echo "The first access may take a while as it needs to compile assets."
echo "So, please be patient."

SITE_NAME="$1";
USER_EMAIL="$2";
USER_PASSWORD="$3";

# If site_name is provided, then
if [ -n "$SITE_NAME" ]; then
  echo "Access using: http://$SITE_NAME:8000"
fi

if [ -n "$USER_EMAIL" ] && [ -n "$USER_PASSWORD" ]; then
  echo "Recommended login credentials."
  echo "-> Email: $USER_EMAIL"
  echo "-> Password: $USER_PASSWORD"
else 
  echo "Please, login as administrator to enable all features."
  echo "-> Email: administrator"
  echo "-> Password: admin"
fi

honcho start \
  socketio \
  watch \
  schedule \
  worker \
  web