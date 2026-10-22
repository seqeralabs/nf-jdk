#!/bin/bash
# Temporary mitigation for CVE-2026-113470 (eMudhra intermediate CA key compromise).
# Distrusts the root that the compromised TLS intermediates chain to, matching
# Debian ca-certificates 20250419+deb13u1. Java's cacerts is generated from the
# system trust store, so update-ca-trust covers it too.
# Remove this script once Amazon Linux ships a ca-certificates update that drops this root.
set -e

BLOCKLIST_DIR=/etc/pki/ca-trust/source/blocklist
ROOTS=(
    "emSign ECC Root CA - G3"
)

for label in "${ROOTS[@]}"; do
    echo "=== Distrusting: $label ==="
    file="$BLOCKLIST_DIR/$(echo "$label" | tr ' ' '_').pem"
    trust extract --format=pem-bundle --filter="pkcs11:object=${label// /%20}" "$file" 2>/dev/null || true
    if [ ! -s "$file" ]; then
        echo "Not present in the trust store, skipping"
        rm -f "$file"
    fi
done

update-ca-trust extract

echo "=== Verify roots are no longer trusted ==="
for label in "${ROOTS[@]}"; do
    if trust list --filter=ca-anchors | grep -qF "label: $label"; then
        echo "ERROR: $label is still a trusted anchor"
        exit 1
    fi
done

echo "=== Certificate distrust completed ==="
