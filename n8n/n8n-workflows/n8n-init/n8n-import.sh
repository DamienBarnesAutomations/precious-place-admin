#!/bin/sh
set -e

HASH_DIR="/home/node/.n8n/hashes"
mkdir -p "$HASH_DIR"

WORKFLOWS_CHANGED=0

check_and_import_workflows() {
  FILE="$1"
  HASH_KEY="$2"
  HASH_FILE="$HASH_DIR/$HASH_KEY"

  if [ ! -f "$FILE" ]; then
    echo "No file found at $FILE, skipping."
    return
  fi

  CURRENT_HASH=$(md5sum "$FILE" | awk '{print $1}')
  STORED_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "none")

  if [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
    echo "$HASH_KEY unchanged, skipping."
  else
    echo "$HASH_KEY changed, importing..."
    n8n import:workflow --input="$FILE"
    echo "$CURRENT_HASH" > "$HASH_FILE"
    WORKFLOWS_CHANGED=1
    echo "$HASH_KEY import complete."
  fi
}

# Credentials — always import, they're fast
echo "Importing credentials..."
[ -f "/home/node/.n8n-files/workflows/n8n_exports/all_credentials.json" ] && \
  n8n import:credentials --input=/home/node/.n8n-files/workflows/n8n_exports/all_credentials.json

[ -f "/home/node/.n8n-files/cake-workflows/n8n_exports/all_credentials.json" ] && \
  n8n import:credentials --input=/home/node/.n8n-files/cake-workflows/n8n_exports/all_credentials.json

# Workflows — only import if changed
check_and_import_workflows \
  "/home/node/.n8n-files/workflows/n8n_exports/all_workflows.json" \
  "root_workflows"

check_and_import_workflows \
  "/home/node/.n8n-files/cake-workflows/n8n_exports/all_workflows.json" \
  "cake_workflows"

# Activate once if anything changed
if [ "$WORKFLOWS_CHANGED" = "1" ]; then
  echo "Activating workflows..."
  n8n list:workflow | awk -F'|' '
  {
    gsub(/^[ \t]+|[ \t]+$/, "", $1);
    gsub(/^[ \t]+|[ \t]+$/, "", $2);
    if ($1 != "" && $1 != "ID") {
      system("echo \"Activating: " $2 " (ID: " $1 ")\"");
      system("n8n publish:workflow --id=\"" $1 "\"");
    }
  }'
  echo "Activation complete."
fi

exec n8n