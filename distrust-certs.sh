#!/bin/bash
# Temporary mitigation for CVE-2026-113470 (eMudhra intermediate CA key compromise).
# Distrusts the roots that chain to the compromised intermediates, matching what
# Mozilla NSS 3.131.1 and Debian ca-certificates did. Java's cacerts is generated
# from the system trust store, so update-ca-trust covers it too.
# Remove this script once Amazon Linux ships a ca-certificates update that drops these roots.
set -e

BLOCKLIST_DIR=/etc/pki/ca-trust/source/blocklist
ROOTS=(
    "emSign ECC Root CA - G3"
    "Comodo AAA Services root"
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
