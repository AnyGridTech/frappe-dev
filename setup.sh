#!/bin/sh
set -e

echo "Setting up project for dev .sh files with LF line endings"
echo "Setting Git hooks path to .github/hooks"
git config core.hooksPath .github/hooks
echo "Git hooks path set to: $(git config core.hooksPath)"
echo "Ensuring .sh files use LF line endings"
find . -type f -name "*.sh" -exec sed -i 's/\r$//' {} +
echo "LF line endings enforced for .sh files"
echo "Setup complete."