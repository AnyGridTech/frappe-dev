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
read -rp "Do you want to install ERPNext? (y/n): " INSTALL_ERPNEXT

# Check if frappe-bench folder exists

DEV_DIR="/workspace/development"

BENCH_DIR="$DEV_DIR/frappe-bench"

if [ ! -d "$BENCH_DIR" ]; then
  echo "Starting bench setup..."
  bench init --skip-redis-config-generation frappe-bench
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

echo "Starting setup wizard for site $SITE_NAME..."
Y=$(date +%Y)
FY_START="$Y-01-01"
FY_END="$Y-12-31"

KWARGS=$(cat <<EOF
{
  "args": {
    "currency": "BRL",
    "country": "Brazil",
    "timezone": "America/Sao_Paulo",
    "language": "English",
    "full_name": "Developer",
    "email": "dev@dev.com",
    "password": "$MYSQL_ROOT_PASSWORD",
    "company_name": "AnyGrid Tech",
    "company_abbr": "AGT",
    "chart_of_accounts": "Brazil - Chart of Accounts",
    "fy_start_date": "$FY_START",
    "fy_end_date": "$FY_END",
    "setup_demo": 0
  }
}
EOF
)

echo "KWARGS:"
echo "$KWARGS"

echo "Submitting Setup Wizard Data on site ${SITE_NAME}..."
bench --site "${SITE_NAME}" execute frappe.desk.page.setup_wizard.setup_wizard.setup_complete --kwargs "${KWARGS}" || true

echo "✅ Setup wizard completed successfully!"


if [ "$INSTALL_ERPNEXT" == "y" ] || [ "$INSTALL_ERPNEXT" == "Y" ]; then
  cd "$DEV_DIR"
  echo "Installing ERPNext..."
  install-app.sh "$SITE_NAME" erpnext
  echo "✅ ERPNext installation completed."
fi

echo "✅ Build process completed successfully!"