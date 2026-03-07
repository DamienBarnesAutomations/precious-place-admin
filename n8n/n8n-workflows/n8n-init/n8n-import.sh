#!/bin/sh
set -e

if [ "$CURRENT_ENV" = "dev" ]; then
  echo "Dev environment detected, skipping init..."
  exec n8n
fi

HASH_DIR="/home/node/.n8n/hashes"
mkdir -p "$HASH_DIR"

check_and_import_workflow() {
  FILE="$1"
  HASH_KEY="$2"
  HASH_FILE="$HASH_DIR/$HASH_KEY"

  CURRENT_HASH=$(md5sum "$FILE" | awk '{print $1}')
  STORED_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "none")

  if [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
    echo "  Unchanged: $HASH_KEY"
  else
    echo "  Importing: $HASH_KEY"
    n8n import:workflow --input="$FILE"
    
    WF_ID=$(grep -m1 '"id"' "$FILE" | awk -F'"' '{print $4}')
    echo "  Activating: $HASH_KEY (ID: $WF_ID)"
    n8n publish:workflow --id="$WF_ID"
    
    echo "$CURRENT_HASH" > "$HASH_FILE"
  fi
}

import_workflows_from_dir() {
  DIR="$1"

  if [ ! -d "$DIR" ]; then
    echo "No directory found at $DIR, skipping."
    return
  fi

  COUNT=0
  for FILE in "$DIR"/*.json; do
    [ -f "$FILE" ] || continue
    HASH_KEY=$(basename "$FILE" .json)
    check_and_import_workflow "$FILE" "$HASH_KEY"
    COUNT=$((COUNT + 1))
  done

  if [ "$COUNT" = "0" ]; then
    echo "No workflow files found in $DIR"
  fi
}

# ---- Credentials — always import, they're fast ----
echo "Importing credentials..."
[ -f "/home/node/.n8n-files/workflows/n8n_exports/all_credentials.json" ] && \
  n8n import:credentials --input=/home/node/.n8n-files/workflows/n8n_exports/all_credentials.json

[ -f "/home/node/.n8n-files/cake-workflows/n8n_exports/all_credentials.json" ] && \
  n8n import:credentials --input=/home/node/.n8n-files/cake-workflows/n8n_exports/all_credentials.json

# ---- Workflows — import individual files from workflows/ subdir ----
echo "Checking root workflows..."
import_workflows_from_dir "/home/node/.n8n-files/workflows/n8n_exports/workflows"

echo "Checking cake workflows..."
import_workflows_from_dir "/home/node/.n8n-files/cake-workflows/n8n_exports/workflows"

# ---- Activate once if anything changed ----

exec n8n