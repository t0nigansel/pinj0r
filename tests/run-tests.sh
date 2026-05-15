#!/usr/bin/env sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

if sh -n run.sh; then
  pass "run.sh syntax"
else
  fail "run.sh syntax"
fi

if PINJ0R_TARGET_URL="" PINJ0R_BEARER_TOKEN="" ./run.sh >/tmp/pinj0r-test.out 2>/tmp/pinj0r-test.err; then
  fail "missing target should fail"
else
  code=$?
  [ "$code" -eq 2 ] || fail "missing target exits $code, expected 2"
  pass "missing target exits 2"
fi

if PINJ0R_TARGET_URL="http://example.test" PINJ0R_BEARER_TOKEN="x" PINJ0R_JSON_FIELD="bad field" ./run.sh >/tmp/pinj0r-test.out 2>/tmp/pinj0r-test.err; then
  fail "invalid JSON field should fail"
else
  code=$?
  [ "$code" -eq 2 ] || fail "invalid JSON field exits $code, expected 2"
  pass "invalid JSON field exits 2"
fi

template=$(mktemp)
printf '{"message":"no marker"}\n' > "$template"

if PINJ0R_TARGET_URL="http://example.test" PINJ0R_BEARER_TOKEN="x" PINJ0R_REQUEST_TEMPLATE_FILE="$template" ./run.sh >/tmp/pinj0r-test.out 2>/tmp/pinj0r-test.err; then
  rm -f "$template"
  fail "template without marker should fail"
else
  code=$?
  rm -f "$template"
  [ "$code" -eq 2 ] || fail "template without marker exits $code, expected 2"
  pass "template without marker exits 2"
fi

rm -f /tmp/pinj0r-test.out /tmp/pinj0r-test.err
