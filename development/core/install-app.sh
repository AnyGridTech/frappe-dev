set -e

echo "Running install_apps.sh..."
trap 'echo "Finished install_apps.sh"' EXIT

APPS_DIR="/home/frappe/frappe-bench/apps"
SITE_APPS_FILE="/home/frappe/frappe-bench/sites/apps.txt"

SITE_NAME="$1"; shift
APP_NAME="$1"; shift
REPO_URL="$1"; shift

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

  if [ ! -d "$APPS_DIR/$app_name" ]; then
    echo "🔄 Getting app $app_name..."
    if [ -z "$repo_url" ]; then
      bench get-app "$app_name"
    else
      bench get-app "$app_name" "$repo_url"
    fi
  else
    echo "✅ App $app_name already exists, skipping get-app."
  fi

  if grep -q "^$app_name$" "$SITE_APPS_FILE"; then
    echo "✅ App $app_name already listed in sites/apps.txt, skipping installation."
  else
    echo "✅ Installing app $app_name on site $SITE_NAME..."
    bench --site "$SITE_NAME" install-app "$app_name"
  fi

  echo "✅ Building app $app_name..."
  bench build --app "$app_name"
}

install_app "$APP_NAME" "$REPO_URL"