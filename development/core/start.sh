#!/bin/bash
# ./core/start.sh

set -e

FILE_DIR="./start.sh"
echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

BENCH_DIR="/workspace/development/frappe-bench"
cd "$BENCH_DIR"

echo "Starting bench with honcho..."

honcho start \
  socketio \
  watch \
  schedule \
  worker