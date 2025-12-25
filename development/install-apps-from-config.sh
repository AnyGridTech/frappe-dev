#!/bin/bash
# install-apps-from-config.sh
# Recursively installs apps from apps.config.json

set -e

echo "Running install-apps-from-config.sh..."
trap 'echo "Finished install-apps-from-config.sh"' EXIT

DEV_DIR="/workspace/development"
BENCH_DIR="$DEV_DIR/frappe-bench"
APPS_DIR="$BENCH_DIR/apps"
CONFIG_FILE="$DEV_DIR/apps.config.json"

SITE_NAME="$1"
USE_BENCH_V15="${2:-false}"

if [ -z "$SITE_NAME" ]; then
  echo "❌ Site name not provided. Exiting."
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found: $CONFIG_FILE"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "⚠️  jq is not installed. Installing jq..."
  apt-get update && apt-get install -y jq
fi

echo "📋 Reading apps configuration from $CONFIG_FILE..."
echo ""

# Function to install a single app
install_single_app() {
  local app_name=$1
  local repo_url=$2
  local branch=$3
  local description=$4

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Installing: $app_name"
  echo "📝 Description: $description"
  echo "🌐 Repository: ${repo_url:-<default>}"
  echo "🌿 Branch: ${branch:-<default>}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cd "$BENCH_DIR" || exit 1

  # Check if app already exists
  if [ ! -d "$APPS_DIR/$app_name" ]; then
    echo "🔄 Getting app $app_name..."

    if [ -z "$repo_url" ] || [ "$repo_url" == "null" ]; then
      bench get-app "$app_name"
    elif [ -z "$branch" ] || [ "$branch" == "null" ]; then
      bench get-app "$app_name" "$repo_url"
    else
      bench get-app "$app_name" "$repo_url" --branch "$branch"
    fi
  else
    echo "✅ App $app_name already exists, skipping get-app."
    echo "🔨 Building app $app_name..."
    bench build --app "$app_name"
  fi

  echo "✅ Installing app $app_name on site $SITE_NAME..."
  bench --site "$SITE_NAME" install-app "$app_name"

  # Check if auto clear cache is enabled
  local auto_clear_cache=$(jq -r '.settings.auto_clear_cache // true' "$CONFIG_FILE")
  if [ "$auto_clear_cache" == "true" ]; then
    echo "🧹 Clearing cache for site $SITE_NAME..."
    bench --site "$SITE_NAME" clear-cache
    bench --site "$SITE_NAME" clear-website-cache
  fi

  # Check if auto migrate is enabled
  local auto_migrate=$(jq -r '.settings.auto_migrate // true' "$CONFIG_FILE")
  if [ "$auto_migrate" == "true" ]; then
    echo "🔄 Running migrations for site $SITE_NAME..."
    bench --site "$SITE_NAME" migrate
  fi

  echo "✅ App $app_name installed successfully!"
  echo ""
}

# Get total number of apps
total_apps=$(jq '[.apps[] | select(.enabled == true)] | length' "$CONFIG_FILE")

if [ "$total_apps" -eq 0 ]; then
  echo "ℹ️  No apps enabled in configuration. Skipping app installation."
  exit 0
fi

echo "📊 Found $total_apps app(s) enabled for installation"
echo ""

# Counter for tracking progress
current=0

# Read and sort apps by order, then recursively install each enabled app
jq -r '[.apps[] | select(.enabled == true)] | sort_by(.order)[] | @json' "$CONFIG_FILE" | \
  while IFS= read -r app; do
    current=$((current + 1))
    
    app_name=$(echo "$app" | jq -r '.name')
    description=$(echo "$app" | jq -r '.description // .name')
    repo_url=$(echo "$app" | jq -r '.repo_url // "null"')
    
    # Determine branch based on version
    if [ "$USE_BENCH_V15" == "true" ] || [ "$USE_BENCH_V15" == "y" ] || [ "$USE_BENCH_V15" == "Y" ]; then
      branch=$(echo "$app" | jq -r '.branch_v15 // .branch // "null"')
    else
      branch=$(echo "$app" | jq -r '.branch // "null"')
    fi

    echo "[$current/$total_apps] Processing $app_name..."
    install_single_app "$app_name" "$repo_url" "$branch" "$description"
  done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 All apps installed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
