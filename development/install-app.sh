#!/bin/bash
# install-app.sh
set -e

echo "Running install-app.sh..."
trap 'echo "Finished install-app.sh"' EXIT

DEV_DIR="/workspace/development"
BENCH_DIR="$DEV_DIR/frappe-bench"
APPS_DIR="$BENCH_DIR/apps"
SITE_APPS_FILE="$BENCH_DIR/sites/apps.txt"

SITE_NAME="$1"; shift
APP_NAME="$1"; shift
REPO_URL="$1";

if [ -z "$SITE_NAME" ]; then
  echo "Site name not provided. Exiting."
  exit 1
fi

if [ -z "$APP_NAME" ]; then
  echo "App name not provided. Exiting."
  exit 1
fi

install_app() {
  local app_name=$1
  local repo_url=$2
  cd "$BENCH_DIR" || exit 1
  if [ ! -d "$APPS_DIR/$app_name" ]; then
    echo "🔄 Getting app $app_name..."
    if [ -z "$repo_url" ]; then
      bench get-app "$app_name"
    else
      bench get-app "$app_name" "$repo_url"
    fi
  else
    echo "✅ App $app_name already exists, skipping get-app."
    echo "✅ Building app $app_name..."
    bench build --app "$app_name"
  fi

  echo "✅ Installing app $app_name on site $SITE_NAME..."
  bench --site "$SITE_NAME" install-app "$app_name"
}

echo "Installing app $APP_NAME from $REPO_URL on site $SITE_NAME..."

install_app "$APP_NAME" "$REPO_URL"

echo "Clearing website cache for site $SITE_NAME..."
bench --site "$SITE_NAME" clear-cache
bench --site "$SITE_NAME" clear-website-cache

echo "Running migrations for site $SITE_NAME..."
bench --site "$SITE_NAME" migrate