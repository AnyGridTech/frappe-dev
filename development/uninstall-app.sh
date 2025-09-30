#!/bin/bash
# uninstall-app.sh
set -e

FILE_DIR="uninstall-app.sh"
echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

DEV_DIR="/workspace/development"
BENCH_DIR="$DEV_DIR/frappe-bench"
APPS_TXT="$BENCH_DIR/sites/apps.txt"

SITE_NAME="$1"
APP_NAME="$2"


echo "Uninstalling the app: $APP_NAME"

cd "$BENCH_DIR"

# Check if app is installed on the site
if ! grep -q "^${APP_NAME}\$" "$APPS_TXT"; then
    echo "App $APP_NAME is not installed on site $SITE_NAME"
    exit 1
fi

echo "Removing app $APP_NAME from site $SITE_NAME"
bench --site "$SITE_NAME" uninstall-app "$APP_NAME"

echo "Removing app $APP_NAME from installed apps list"
bench --site "$SITE_NAME" remove-from-installed-apps "$APP_NAME"

sed -i "/^${APP_NAME}\$/d" "$APPS_TXT"

echo "Migrating site: $SITE_NAME"
bench --site "$SITE_NAME" migrate

bench --site "$SITE_NAME" clear-cache
bench --site "$SITE_NAME" clear-website-cache

echo "App $APP_NAME uninstalled from site $SITE_NAME"

