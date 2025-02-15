#!/bin/bash
set -e

# Import utilities
source ./scripts/utils.sh

# Common variables
INITIALIZED_FLAG="/shared/initialized.txt"
BEDROCK_JWT_PATH="/shared/jwt.txt"
GETH_DATA_DIR="$BEDROCK_DATADIR"
TORRENTS_DIR="/torrents/$NETWORK_NAME"
BEDROCK_TAR_PATH="/downloads/bedrock.tar"
BEDROCK_TMP_PATH="/bedrock-tmp"

# Exit early if the node is already initialized
if [[ -f "$INITIALIZED_FLAG" ]]; then
  echo "Bedrock node already initialized."
  exit 0
fi

echo "Initializing Bedrock node..."
echo "Fetching snapshot download link..."

# Determine the snapshot URL based on NODE_TYPE and NETWORK_NAME
declare -A SNAPSHOT_BASE_URL=(
  ["ink-sepolia"]="https://storage.googleapis.com/raas-op-geth-snapshots-d2a56/datadir-archive"
  ["ink-mainnet"]="https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive"
)

if [[ "$NODE_TYPE" == "archive" && -n "${SNAPSHOT_BASE_URL[$NETWORK_NAME]}" ]]; then
  SNAPSHOT_FILENAME=$(curl -s "${SNAPSHOT_BASE_URL[$NETWORK_NAME]}/latest")
  BEDROCK_TAR_DOWNLOAD="${SNAPSHOT_BASE_URL[$NETWORK_NAME]}/$SNAPSHOT_FILENAME"
  echo "Using snapshot file: $SNAPSHOT_FILENAME"
fi

# Proceed only if a valid snapshot URL was determined
if [[ -n "$BEDROCK_TAR_DOWNLOAD" ]]; then
  case "$BEDROCK_TAR_DOWNLOAD" in
    *.zst) BEDROCK_TAR_PATH+=".zst" ;;
    *.lz4) BEDROCK_TAR_PATH+=".lz4" ;;
  esac

  echo "Downloading Bedrock snapshot..."
  download "$BEDROCK_TAR_DOWNLOAD" "$BEDROCK_TAR_PATH"

  echo "Extracting Bedrock snapshot..."
  case "$BEDROCK_TAR_PATH" in
    *.zst) extractzst "$BEDROCK_TAR_PATH" "$GETH_DATA_DIR" ;;
    *.lz4) extractlz4 "$BEDROCK_TAR_PATH" "$GETH_DATA_DIR" ;;
    *) extract "$BEDROCK_TAR_PATH" "$GETH_DATA_DIR" ;;
  esac

  # Cleanup to save disk space
  rm -f "$BEDROCK_TAR_PATH"
fi

# Generate JWT
echo "Creating JWT..."
mkdir -p "$(dirname "$BEDROCK_JWT_PATH")"
openssl rand -hex 32 > "$BEDROCK_JWT_PATH"

# Mark initialization as complete
echo "Initialization complete."
touch "$INITIALIZED_FLAG"
