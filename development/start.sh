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

# função de cleanup
cleanup() {
  echo "Shutting down tsc watchers..."
  for pid in "${TSC_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  echo "Finished $FILE_DIR"
}
trap cleanup EXIT

echo "Starting TypeScript compilers in watch mode..."
# 👉 Loop: inicia tsc --watch em todo app que tiver tsconfig.json em /my_app/public

TSC_DIRS=()

echo "Scanning for tsconfig.json files..."

# Find all tsconfig.json files in app directories
# Look in: app_name/public/tsconfig.json and app_name/*/doctype/*/tsconfig.json
while IFS= read -r tsconfig_path; do
  tsc_dir=$(dirname "$tsconfig_path")
  echo "Found tsconfig.json at: $tsc_dir"
  TSC_DIRS+=("$tsc_dir")
done < <(find "$BENCH_DIR/apps" -type f -name "tsconfig.json" \
  \( -path "*/*/public/tsconfig.json" -o -path "*/*/doctype/*/tsconfig.json" \) 2>/dev/null)

echo "------------------------------------"
echo "Total tsconfig.json files found: ${#TSC_DIRS[@]}"
echo "------------------------------------"

TSC_PIDS=()

for TSC_DIR in "${TSC_DIRS[@]}"; do
  echo "> $TSC_DIR"
  echo "Starting tsc --watch"
  cd "$TSC_DIR"
  npx tsc --watch &
  sleep 2
  TSC_PIDS+=($!)
done

cd "$BENCH_DIR"

# 👉 inicia o honcho
honcho start \
  socketio \
  watch \
  schedule \
  worker \
  web