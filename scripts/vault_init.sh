#!/bin/bash
# Initialize Vault for the first time and save keys/token to vault-init.json.
# Run this once after 'terraform apply' creates the Vault VM.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUTPUT_FILE="vault-init.json"
export VAULT_ADDR="https://vault.homelab.lan:8200"
# export VAULT_SKIP_VERIFY=true

echo "Waiting for Vault to be reachable..."
until curl -sfk "$VAULT_ADDR/v1/sys/seal-status" > /dev/null 2>&1; do
  echo "  still waiting..."
  sleep 5
done

echo "Initializing Vault..."
vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > "$OUTPUT_FILE"
chmod 0600 "$OUTPUT_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CRITICAL: Save these credentials immediately!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Root Token:"
jq -r '.root_token' "$OUTPUT_FILE"
echo ""
echo "Unseal Keys (need any 3 of 5 to unseal):"
jq -r '.unseal_keys_b64[]' "$OUTPUT_FILE" | nl -ba
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo "  1. Import vault-init.json into Bitwarden"
echo "  2. Delete the file: rm vault-init.json"
echo '  3. Export: export VAULT_TOKEN=$(jq -r .root_token vault-init.json)'
echo "  4. Run: ./scripts/unseal-vault.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
