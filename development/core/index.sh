#!/bin/bash
# ./core/index.sh

set -e

FILE_DIR="./index.sh"

echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

wait-for-it -t 120 mariadb:3306
wait-for-it -t 120 redis-cache:6379
wait-for-it -t 120 redis-queue:6379

echo "Starting bench setup..."
bench init --skip-redis-config-generation frappe-bench

BENCH_DIR="/workspace/development/frappe-bench"

cd "$BENCH_DIR"

echo "Setting bench configurations"

bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379

echo "Generated common_site_config.json:"
cat "$BENCH_DIR/sites/common_site_config.json"
echo ""

echo "Editing Procfile to remove lines containing the configuration from Redis"
sed -i '/redis/d' ./Procfile

SITE_NAME="development.localhost"

if bench --site "$SITE_NAME" list-apps >/dev/null 2>&1; then
  echo "✅ Site $SITE_NAME já existe, saindo da execução..."
  exit 0
fi

MYSQL_ROOT_USERNAME="root"
MYSQL_ROOT_PASSWORD="root"

echo "Creating new site named $SITE_NAME..."
echo "Using MySQL root username: $MYSQL_ROOT_USERNAME"
echo "Using MySQL root password: ${MYSQL_ROOT_PASSWORD:0:3}********"
bench new-site --mariadb-user-host-login-scope='%' \
  --admin-password=${MYSQL_ROOT_PASSWORD} \
  --db-root-username=${MYSQL_ROOT_USERNAME} \
  --db-root-password=${MYSQL_ROOT_PASSWORD} \
  --install-app erpnext \
  --set-default ${SITE_NAME}

bench --site "$SITE_NAME" set-config developer_mode 1
bench --site "$SITE_NAME" clear-cache

Y=$(date +%Y)
FY_START="$Y-01-01"
FY_END="$Y-12-31"

# Use jq to safely construct the JSON body
# The --arg flag handles escaping of any special characters in the password
KWARGS=$(jq -n \
  --arg currency "BRL" \
  --arg country "Brazil" \
  --arg timezone "America/Sao_Paulo" \
  --arg language "English" \
  --arg full_name "Luan Gabriel" \
  --arg email "lgotcfg@gmail.com" \
  --arg password "$MYSQL_ROOT_PASSWORD" \
  --arg company_name "Growatt" \
  --arg company_abbr "GRT" \
  --arg chart_of_accounts "Brazil - Chart of Accounts" \
  --arg fy_start_date "$FY_START" \
  --arg fy_end_date "$FY_END" \
  --argjson setup_demo 0 \
  '{
    "args": {
      "currency": $currency,
      "country": $country,
      "timezone": $timezone,
      "language": $language,
      "full_name": $full_name,
      "email": $email,
      "password": $password,
      "company_name": $company_name,
      "company_abbr": $company_abbr,
      "chart_of_accounts": $chart_of_accounts,
      "fy_start_date": $fy_start_date,
      "fy_end_date": $fy_end_date,
      "setup_demo": $setup_demo
    }
  }')

echo "KWARGS (senha oculta):"
echo "$KWARGS" | jq '.args.password = "**********"'

echo "Submitting Setup Wizard Data on site ${SITE_NAME}..."
bench --site "${SITE_NAME}" execute frappe.desk.page.setup_wizard.setup_wizard.setup_complete --kwargs "${KWARGS}" || true

echo "✅ Site $SITE_NAME created successfully!"

