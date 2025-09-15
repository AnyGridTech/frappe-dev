#!/bin/bash
# setup-wizard.sh

set -e

FILE_DIR="setup-wizard.sh"
echo "Running $FILE_DIR"
trap 'echo "Finished $FILE_DIR"' EXIT

DEV_DIR="/workspace/development"
BENCH_DIR="$DEV_DIR/frappe-bench"
cd "$BENCH_DIR"

SITE_NAME="$1"; shift
USER_EMAIL="$1";
USER_PASSWORD="$2";

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
    "email": "$USER_EMAIL",
    "password": "$USER_PASSWORD",
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
bench --site "${SITE_NAME}" execute frappe.desk.page.setup_wizard.setup_wizard.setup_complete --kwargs "${KWARGS}"

echo "✅ Setup wizard completed successfully!"