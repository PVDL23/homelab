#!/bin/bash
# Unseal Vault.
# Run after each Vault restart (e.g. after Proxmox reboot).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export VAULT_ADDR="https://vault.homelab.lan:8200"
export VAULT_SKIP_VERIFY=true

if { vault status 2>/dev/null || true; } | grep -q "Sealed.*false"; then
  echo "Vault is already unsealed."
  vault status
  exit 0
fi

echo "Unsealing Vault at $VAULT_ADDR"
echo ""

for token in $(
    cat $SCRIPT_DIR/../vault-init.json | \
    jq -r '.unseal_keys_b64[0:3] | join(" ")'
  ) ; do
    vault operator unseal $token
  done

echo ""
if { vault status 2>/dev/null || true; } | grep -q "Sealed.*false"; then
  echo "Vault unsealed successfully."
else
  echo "ERROR: Vault is still sealed. Check the keys and try again." >&2
  exit 1
fi