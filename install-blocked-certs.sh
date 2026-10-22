#!/bin/bash
# Merge the vendored OpenJDK blocked.certs into the JDK's own list, so the
# image distrusts every certificate blocked upstream while keeping any entry
# a newer Corretto release ships on its own.
set -euo pipefail

SRC="${1:?Usage: $0 <blocked.certs>}"
DST="$JAVA_HOME/lib/security/blocked.certs"

if [ "$(head -1 "$SRC")" != "$(head -1 "$DST")" ]; then
    echo "Digest algorithm mismatch: '$(head -1 "$SRC")' vs '$(head -1 "$DST")'" >&2
    exit 1
fi

MERGED=$(mktemp)
{ head -1 "$DST"; tail -q -n +2 "$DST" "$SRC" | LC_ALL=C sort -u; } > "$MERGED"
cat "$MERGED" > "$DST"
rm -f "$MERGED"

echo "Installed $(($(wc -l < "$DST") - 1)) blocked certificate fingerprints in $DST"
