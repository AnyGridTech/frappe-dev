#!/bin/bash
# build.sh

set -e

FILE_DIR="build.sh"

echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

# Set development directory
DEV_DIR="/workspace/development"

# Load apps configuration
CONFIG_FILE="$DEV_DIR/apps.config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Config file not found: $CONFIG_FILE"
  echo "Creating default config file..."
  # Will be created if it doesn't exist
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "⚠️  jq is not installed. Installing jq..."
  sudo apt-get update && sudo apt-get install -y jq
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 BUILD CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if wants to start build process
read -rp "Do you want to start the build process? (y/n): " START_BUILD

if [ "$START_BUILD" != "y" ] && [ "$START_BUILD" != "Y" ]; then
  echo "Exiting execution as per user request."
  exit 0
fi

# Ask if wants to use Frappe-bench v15
read -rp "Use Frappe-bench v15 (Recommended)? (y/n): " USE_BENCH_V15

# Ask about each app and store answers in memory
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 APP SELECTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Declare associative array to store app installation choices
declare -A APP_CHOICES

if [ -f "$CONFIG_FILE" ]; then
  # Read each app and ask user - redirect stdin from terminal
  while IFS= read -r app; do
    app_name=$(echo "$app" | jq -r '.name')
    prompt=$(echo "$app" | jq -r '.prompt')
    
    read -rp "$prompt (y/n): " INSTALL_APP </dev/tty
    
    # Store the choice in memory
    if [ "$INSTALL_APP" == "y" ] || [ "$INSTALL_APP" == "Y" ]; then
      APP_CHOICES["$app_name"]="true"
      echo "✅ $app_name will be installed"
    else
      APP_CHOICES["$app_name"]="false"
      echo "⏭️  $app_name will be skipped"
    fi
  done < <(jq -r '.apps[] | @json' "$CONFIG_FILE")
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 STARTING BUILD PROCESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Update config file with v15 setting and app choices
if [ -f "$CONFIG_FILE" ]; then
  echo "📝 Updating configuration file..."
  jq ".settings.use_bench_v15 = $([ "$USE_BENCH_V15" == "y" ] || [ "$USE_BENCH_V15" == "Y" ] && echo "true" || echo "false")" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  
  # Update each app's enabled status based on stored choices
  for app_name in "${!APP_CHOICES[@]}"; do
    jq "(.apps[] | select(.name == \"$app_name\") | .enabled) = ${APP_CHOICES[$app_name]}" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  done
  echo "✅ Configuration updated"
fi

echo ""

# Check if frappe-bench folder exists

BENCH_DIR="$DEV_DIR/frappe-bench"

if [ ! -d "$BENCH_DIR" ]; then
  echo "Starting bench setup..."
  CMD_BENCH_SETUP="bench init --skip-redis-config-generation frappe-bench"
  if [ "$USE_BENCH_V15" == "y" ] || [ "$USE_BENCH_V15" == "Y" ]; then
    echo "Using Frappe-bench v15"
    CMD_BENCH_SETUP+=" --frappe-branch version-15"
  fi
  eval "$CMD_BENCH_SETUP"
  echo "✅ Bench setup completed."
else
  echo "✅ Bench folder already exists, skipping bench init."
fi

cd "$BENCH_DIR"

echo "Setting bench configurations"

# Check if common_site_config.json already has the configurations
common_site_config_path="$BENCH_DIR/sites/common_site_config.json"
db_cfg='"db_host": "mariadb"'
redis_cache_cfg='"redis_cache": "redis://redis-cache:6379"'
redis_queue_cfg='"redis_queue": "redis://redis-queue:6379"'
redis_socketio_cfg='"redis_socketio": "redis://redis-queue:6379"'

cfg_present=$(grep -q "$db_cfg" "$common_site_config_path" && \
  grep -q "$redis_cache_cfg" "$common_site_config_path" && \
  grep -q "$redis_queue_cfg" "$common_site_config_path" && \
  grep -q "$redis_socketio_cfg" "$common_site_config_path" && \
  echo "true" || echo "false")

if [ "$cfg_present" == "false" ]; then 
  echo "Adding configurations to common_site_config.json..."
  bench set-config -g db_host mariadb
  bench set-config -g redis_cache redis://redis-cache:6379
  bench set-config -g redis_queue redis://redis-queue:6379
  bench set-config -g redis_socketio redis://redis-queue:6379
  echo "✅ Configurations added to common_site_config.json."
  echo "Generated common_site_config.json:"
  cat "$common_site_config_path"
  echo ""
else
  echo "✅ common_site_config.json already has the required configurations. Skipping bench set-config."
fi

echo "Editing Procfile to remove lines containing the configuration from Redis"
sed -i '/redis/d' ./Procfile

SITE_NAME="dev.localhost"
DB_ROOT_PASSWORD="123" # DO NOT CHANGE
DB_ROOT_USERNAME="root" # DO NOT CHANGE
ADMIN_PASSWORD="admin" # DO NOT CHANGE

SITE_EXISTS=false

# Check if site already exists
if bench --site "$SITE_NAME" list-apps >/dev/null 2>&1; then
  echo "✅ Site $SITE_NAME already exists. Skipping site creation..."
  SITE_EXISTS=true
else
  echo "Creating new site named $SITE_NAME..."
  echo "Using DB root username: $DB_ROOT_USERNAME"
  echo "Using DB root password: $DB_ROOT_PASSWORD"
  echo "Using Admin password: $ADMIN_PASSWORD"

  echo "Creating site $SITE_NAME..."

  # Try to create site, if it fails due to existing database, offer to drop it
  if ! bench new-site --mariadb-user-host-login-scope='%' \
    --admin-password=${ADMIN_PASSWORD} \
    --db-root-username=${DB_ROOT_USERNAME} \
    --db-root-password=${DB_ROOT_PASSWORD} \
    --set-default ${SITE_NAME} 2>&1; then
    
    echo ""
    echo "⚠️  Failed to create site. This usually means a database from a previous build exists."
    read -rp "Do you want to drop the existing database and try again? (y/n): " DROP_DB
    
    if [ "$DROP_DB" == "y" ] || [ "$DROP_DB" == "Y" ]; then
      echo "Dropping existing databases for site $SITE_NAME..."
      bench drop-site "$SITE_NAME" --force --no-backup --db-root-username=${DB_ROOT_USERNAME} --db-root-password=${DB_ROOT_PASSWORD} 2>/dev/null || true
      
      echo "Recreating site $SITE_NAME..."
      bench new-site --mariadb-user-host-login-scope='%' \
        --admin-password=${ADMIN_PASSWORD} \
        --db-root-username=${DB_ROOT_USERNAME} \
        --db-root-password=${DB_ROOT_PASSWORD} \
        --set-default ${SITE_NAME}
    else
      echo "Exiting without creating site."
      exit 1
    fi
  fi

  echo "✅ Site $SITE_NAME created successfully!"

  echo "Setting developer mode for site $SITE_NAME..."
  bench --site "$SITE_NAME" set-config developer_mode 1
  echo "✅ Developer mode set."

  echo "Clearing cache for site $SITE_NAME..."
  bench --site "$SITE_NAME" clear-cache
  echo "✅ Cache cleared."
fi


cd "$DEV_DIR"

# Install apps from configuration
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 INSTALLING APPS FROM CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

bash install-apps-from-config.sh "$SITE_NAME" "$USE_BENCH_V15"

echo "✅ Build process completed successfully!"

# Only run setup wizard if site was just created
if [ "$SITE_EXISTS" == "false" ]; then
  USER_EMAIL="administrator"
  bash setup-wizard.sh "$SITE_NAME" "$USER_EMAIL" "$ADMIN_PASSWORD"
fi

echo "To start the environment on VSCode (Recommended):"
echo "1. Open Debug panel (Ctrl+Shift+D)"
echo "2. Select 'Honcho + Web debug' configuration"
echo "3. Click the green play button (Start Debugging) or press F5"
echo ""