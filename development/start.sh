#!/bin/bash
# start.sh
# This script starts the main honcho services and runs the tsc watcher script.

set -e

FILE_DIR="start.sh"
echo "Running $FILE_DIR"

BENCH_DIR="/workspace/development/frappe-bench"
cd "$BENCH_DIR"

echo "Starting bench with honcho..."

echo "The first access may take a while as it needs to compile assets."
echo "So, please be patient."

SITE_NAME="$1";
USER_EMAIL="$2";
USER_PASSWORD="$3";

# Print site and login information
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

# Start the tsc runner script in the background
# Assumes run_tsc.sh is in the same directory ($BENCH_DIR) and is executable
# echo "Starting tsc watchers in the background..."
# ./run_tsc.sh &
# TSC_RUNNER_PID=$! # Get the PID of the run_tsc.sh script

# Trap to ensure that when this script exits (e.g., Ctrl+C),
# it also kills the background tsc runner script.
cleanup() {
  echo "Shutting down honcho and tsc runner..."
  # Send SIGTERM to the run_tsc.sh script
  kill "$TSC_RUNNER_PID" 2>/dev/null || true
  echo "Finished $FILE_DIR"
}
trap cleanup EXIT

# Start honcho in the foreground
# This will be the main process of this script
echo "Starting honcho..."
honcho start \
  socketio \
  watch \
  schedule \
  worker \
  web