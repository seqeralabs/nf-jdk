#!/usr/bin/env bash
# Smoke tests for nf-jdk container images
set -euo pipefail

IMAGE="${1:?Usage: $0 <image> [base|jemalloc]}"
VARIANT="${2:-base}"

PASSED=0
FAILED=0

# Extract expected Java major version from image tag (e.g. "nf-jdk:corretto-21-al2023" -> "21")
JAVA_VERSION=$(echo "$IMAGE" | sed -n 's/.*corretto-\([0-9]*\).*/\1/p')

run_test() {
    local description="$1"
    shift
    printf "  %-50s " "$description"
    if output=$(docker run --rm "$IMAGE" "$@" 2>&1); then
        echo "PASS"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "FAIL"
        echo "    Command: docker run --rm $IMAGE $*"
        echo "    Output: $output"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

run_test_bash() {
    local description="$1"
    local script="$2"
    printf "  %-50s " "$description"
    if output=$(docker run --rm "$IMAGE" bash -c "$script" 2>&1); then
        echo "PASS"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "FAIL"
        echo "    Command: docker run --rm $IMAGE bash -c '$script'"
        echo "    Output: $output"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

run_test_bash_output_contains() {
    local description="$1"
    local expected="$2"
    local script="$3"
    printf "  %-50s " "$description"
    output=$(docker run --rm "$IMAGE" bash -c "$script" 2>&1) || true
    if echo "$output" | grep -q "$expected"; then
        echo "PASS"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "FAIL (output missing '$expected')"
        echo "    Command: docker run --rm $IMAGE bash -c '$script'"
        echo "    Output: $output"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "============================================"
echo "Testing image: $IMAGE"
echo "Variant: $VARIANT"
echo "Expected Java version: $JAVA_VERSION"
echo "============================================"

echo ""
echo "--- Java Tests ---"
run_test_bash_output_contains \
    "Java runtime present (Corretto)" \
    "Corretto" \
    "java -version 2>&1"

run_test_bash_output_contains \
    "Java version matches ($JAVA_VERSION)" \
    "\"$JAVA_VERSION\." \
    "java -version 2>&1"

run_test_bash_output_contains \
    "Java compiler present" \
    "javac" \
    "javac -version 2>&1"

run_test_bash \
    "Java compile and run" \
    'echo "public class Hello { public static void main(String[] a) { System.out.println(\"Hello nf-jdk\"); }}" > /tmp/Hello.java && javac /tmp/Hello.java -d /tmp && java -cp /tmp Hello | grep -q "Hello nf-jdk"'

echo ""
echo "--- Required Tools ---"
run_test "tar present" tar --version
run_test "gzip present" gzip --version
run_test_bash "ps present" "ps --version 2>&1; exit 0"
run_test "which present" which java

echo ""
echo "--- Scripts ---"
run_test "wait-for-it.sh executable" test -x /usr/local/bin/wait-for-it.sh

if [ "$VARIANT" = "jemalloc" ]; then
    echo ""
    echo "--- Jemalloc ---"
    run_test_bash_output_contains \
        "LD_PRELOAD set to jemalloc" \
        "libjemalloc.so.2" \
        "printenv LD_PRELOAD"

    run_test \
        "jemalloc library exists" \
        test -f /usr/lib64/libjemalloc.so.2

    run_test_bash_output_contains \
        "JVM loads jemalloc" \
        "jemalloc" \
        "LD_DEBUG=libs java -version 2>&1"
fi

echo ""
echo "============================================"
echo "Results: $PASSED passed, $FAILED failed"
echo "============================================"

exit "$FAILED"
