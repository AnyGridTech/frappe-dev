#!/bin/bash
# run_tsc.sh
# This script finds all tsconfig.json files and runs 'tsc --watch' on them.

set -e

FILE_DIR="run_tsc.sh"
echo "Running $FILE_DIR"

# Define the bench directory
BENCH_DIR="/workspace/development/frappe-bench"
cd "$BENCH_DIR"

# Array to store all tsc process IDs
TSC_PIDS=()

# Cleanup function to kill all tsc processes when this script exits
cleanup() {
  echo "Shutting down all tsc watchers..."
  for pid in "${TSC_PIDS[@]}"; do
    # Send SIGTERM (kill) to the process
    kill "$pid" 2>/dev/null || true
  done
  echo "Finished $FILE_DIR"
}
# Trap the EXIT signal (e.g., from Ctrl+C or being killed by start.sh)
trap cleanup EXIT

echo "Starting TypeScript compilers in watch mode..."

TSC_DIRS=()

echo "Scanning for tsconfig.json files..."

# Find all tsconfig.json files in app directories
# Looks in: app_name/public/tsconfig.json and app_name/*/doctype/*/tsconfig.json
while IFS= read -r tsconfig_path; do
  tsc_dir=$(dirname "$tsconfig_path")
  echo "Found tsconfig.json at: $tsc_dir"
  TSC_DIRS+=("$tsc_dir")
done < <(find "$BENCH_DIR/apps" -type f -name "tsconfig.json" \
  \( -path "*/*/public/tsconfig.json" -o -path "*/*/doctype/*/tsconfig.json" \) 2>/dev/null)

echo "------------------------------------"
echo "Total tsconfig.json files found: ${#TSC_DIRS[@]}"
echo "------------------------------------"

# Start all tsc --watch processes in the background
for TSC_DIR in "${TSC_DIRS[@]}"; do
  echo "> $TSC_DIR"
  echo "Starting tsc --watch"
  
  # Run tsc in a subshell to avoid changing the main script's directory
  (cd "$TSC_DIR" && npx tsc --watch) &
  
  sleep 2 # Give tsc a moment to start up
  TSC_PIDS+=($!) # Store its Process ID
done

echo "All tsc watchers are running in the background."
echo "This script will wait until it is terminated..."

# 'wait' causes the script to pause here and wait for all background
# jobs (the tsc watchers) to finish. Since they are watch processes,
# this script will run indefinitely until it receives an EXIT signal.
wait
