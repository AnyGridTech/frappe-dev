#!/bin/bash
# build.sh

set -e

FILE_DIR="build.sh"

echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

# Ask if wants to start build process
read -rp "Do you want to start the build process? (y/n): " START_BUILD

if [ "$START_BUILD" != "y" ] && [ "$START_BUILD" != "Y" ]; then
  echo "Exiting execution as per user request."
  exit 0
fi

# Ask if wants to install erpnext
read -rp "Use Frappe-bench v15? (y/n): " USE_BENCH_V15
read -rp "Do you want to install ERPNext? (y/n): " INSTALL_ERPNEXT
read -rp "Do you want to install Payments? (y/n): " INSTALL_PAYMENTS
read -rp "Do you want to install Learning Management System (LMS)? (y/n): " INSTALL_ELEARNING
read -rp "Do you want to install Frappe Comment AGT? (y/n): " INSTALL_COMMENT_AGT
read -rp "Do you want to start the environment after the build? (y/n): " START_ENV

# Check if frappe-bench folder exists

DEV_DIR="/workspace/development"

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

if bench --site "$SITE_NAME" list-apps >/dev/null 2>&1; then
  echo "✅ Site $SITE_NAME already exists. Exiting execution..."
  exit 0
fi

DB_ROOT_PASSWORD="123" # DO NOT CHANGE
DB_ROOT_USERNAME="root" # DO NOT CHANGE
ADMIN_PASSWORD="admin" # DO NOT CHANGE

echo "Creating new site named $SITE_NAME..."
echo "Using DB root username: $DB_ROOT_USERNAME"
echo "Using DB root password: $DB_ROOT_PASSWORD"
echo "Using Admin password: $ADMIN_PASSWORD"

echo "Creating site $SITE_NAME..."

bench new-site --mariadb-user-host-login-scope='%' \
  --admin-password=${ADMIN_PASSWORD} \
  --db-root-username=${DB_ROOT_USERNAME} \
  --db-root-password=${DB_ROOT_PASSWORD} \
  --set-default ${SITE_NAME}

echo "✅ Site $SITE_NAME created successfully!"

echo "Setting developer mode for site $SITE_NAME..."
bench --site "$SITE_NAME" set-config developer_mode 1
echo "✅ Developer mode set."

echo "Clearing cache for site $SITE_NAME..."
bench --site "$SITE_NAME" clear-cache
echo "✅ Cache cleared."

cd "$DEV_DIR"

if [ "$INSTALL_ERPNEXT" == "y" ] || [ "$INSTALL_ERPNEXT" == "Y" ]; then
  echo "Installing ERPNext..."
  CMD_ERP_SETUP="bash install-app.sh \"$SITE_NAME\" erpnext https://github.com/frappe/erpnext"
  if [ "$USE_BENCH_V15" == "y" ] || [ "$USE_BENCH_V15" == "Y" ]; then
    echo "Using v15"
    CMD_ERP_SETUP+=" version-15"
  fi
  eval "$CMD_ERP_SETUP"
  echo "✅ ERPNext installation completed."
fi

if [ "$INSTALL_PAYMENTS" == "y" ] || [ "$INSTALL_PAYMENTS" == "Y" ]; then
  echo "Installing Payments..."
  CMD_PAYMENTS_SETUP="bash install-app.sh \"$SITE_NAME\" payments https://github.com/frappe/payments"
  if [ "$USE_BENCH_V15" == "y" ] || [ "$USE_BENCH_V15" == "Y" ]; then
    echo "Using v15"
    CMD_PAYMENTS_SETUP+=" version-15"
  fi
  eval "$CMD_PAYMENTS_SETUP"
  echo "✅ Payments installation completed."
fi

if [ "$INSTALL_ELEARNING" == "y" ] || [ "$INSTALL_ELEARNING" == "Y" ]; then
  echo "Installing Learning Management System (LMS)..."
  bash install-app.sh "$SITE_NAME" lms https://github.com/frappe/lms
  echo "✅ LMS installation completed."
fi

if [ "$INSTALL_COMMENT_AGT" == "y" ] || [ "$INSTALL_COMMENT_AGT" == "Y" ]; then
  echo "Installing Frappe Comment AGT..."
  bash install-app.sh "$SITE_NAME" frappe_comment_agt https://github.com/AnyGridTech/frappe-comment-agt
  echo "✅ Frappe Comment AGT installation completed."
fi

echo "✅ Build process completed successfully!"

USER_EMAIL="dev@dev.com"
USER_PASSWORD="dev"

bash setup-wizard.sh "$SITE_NAME" "$USER_EMAIL" "$USER_PASSWORD"

echo "To start the environment you must:"
echo "1. cd $DEV_DIR"
echo "2. bash start.sh"

if [ "$START_ENV" == "y" ] || [ "$START_ENV" == "Y" ]; then
  echo "Starting the environment automatically now..."
  bash start.sh "$SITE_NAME" "$USER_EMAIL" "$USER_PASSWORD"
fi