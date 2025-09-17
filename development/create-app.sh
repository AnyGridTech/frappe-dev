#!/bin/bash

# create-app.sh
set -e

FILE_DIR="create-app"

echo "Running create-app.sh..."
trap 'echo "Finished create-app.sh"' EXIT

DEV_DIR="/workspace/development"
BENCH_DIR="$DEV_DIR/frappe-bench"

echo "📁 Changing to bench directory: $BENCH_DIR"

cd "$BENCH_DIR" || exit 1

APP_NAME="$1";
if [ -z "$APP_NAME" ]; then
  echo "❌ App name not provided. Exiting."
  exit 1
fi

if [ -d "$BENCH_DIR/apps/$APP_NAME" ]; then
  echo "❌ App $APP_NAME already exists. Exiting."
  exit 1
fi

SITE_NAME="$2";
if [ -z "$SITE_NAME" ]; then
  echo "❌ Site name not provided. Exiting."
  exit 1
fi

echo "📦 Creating app: $APP_NAME for site: $SITE_NAME"

bench new-app "$APP_NAME"

echo "✅ App $APP_NAME created."

echo "📦 Installing app $APP_NAME on site $SITE_NAME..."

bench --site "$SITE_NAME" install-app "$APP_NAME"

echo "🧹 Clearing website cache for site $SITE_NAME..."
bench --site "$SITE_NAME" clear-cache
bench --site "$SITE_NAME" clear-website-cache

