#!/bin/bash
set -e

echo "=== Installing jemalloc ==="
yum install -y jemalloc

echo "=== DEBUG: Checking jemalloc installation ==="
rpm -ql jemalloc

echo "=== Architecture info ==="
uname -m

echo "=== jemalloc library info ==="
find /usr -name "*jemalloc*" -type f 2>/dev/null || echo "find command completed with non-zero exit"

echo "=== Verify jemalloc library ==="
ls -la /usr/lib64/libjemalloc.so* 2>/dev/null || ls -la /usr/lib/*/libjemalloc.so* 2>/dev/null || echo "jemalloc library location may differ"

echo "=== jemalloc installation completed ==="