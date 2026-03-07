#!/bin/sh
set -e

# 1. Import Root Credentials
if [ -f "/home/node/.n8n-files/workflows/n8n_exports/all_credentials.json" ]; then
  echo "Importing root credentials..."
  n8n import:credentials --input=/home/node/.n8n-files/workflows/n8n_exports/all_credentials.json
fi

# 2. Import Root Workflows
if [ -f "/home/node/.n8n-files/workflows/n8n_exports/all_workflows.json" ]; then
  echo "Importing all root workflows..."
  n8n import:workflow --input=/home/node/.n8n-files/workflows/n8n_exports/all_workflows.json
fi

# 3. Import Cake Manager Credentials (Sub-module)
if [ -f "/home/node/.n8n-files/cake-workflows/n8n_exports/all_credentials.json" ]; then
  echo "Importing Cake Manager credentials..."
  n8n import:credentials --input=/home/node/.n8n-files/cake-workflows/n8n_exports/all_credentials.json
fi

# 4. Import Cake Manager Workflows (Sub-module)
if [ -f "/home/node/.n8n-files/cake-workflows/n8n_exports/all_workflows.json" ]; then
  echo "Importing Cake Manager workflows..."
  n8n import:workflow --input=/home/node/.n8n-files/cake-workflows/n8n_exports/all_workflows.json
fi

# 5. Activate all workflows
echo "Activating workflows individually..."
n8n list:workflow | awk -F'|' '
{
  gsub(/^[ \t]+|[ \t]+$/, "", $1);
  gsub(/^[ \t]+|[ \t]+$/, "", $2);
  if ($1 != "" && $1 != "ID") {
    system("echo \"Attempting to publish: " $2 " (ID: " $1 ")\"");
    system("n8n publish:workflow --id=\"" $1 "\"");
  }
}'

exec n8n
