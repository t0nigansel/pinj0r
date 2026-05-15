#!/usr/bin/env sh
set -eu

CI_MODE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ci)
      CI_MODE=1
      ;;
    -h|--help)
      echo "Usage: ./run.sh [--ci]" >&2
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      echo "Usage: ./run.sh [--ci]" >&2
      exit 2
      ;;
  esac
  shift
done

ATTACKS_DIR="${PINJ0R_ATTACKS_DIR:-attacks}"
ATTACKS_FILE="${PINJ0R_ATTACKS_FILE:-}"
RESULTS_DIR="${PINJ0R_RESULTS_DIR:-results}"
TARGET_URL="${PINJ0R_TARGET_URL:-}"
BEARER_TOKEN="${PINJ0R_BEARER_TOKEN:-}"
JSON_FIELD="${PINJ0R_JSON_FIELD:-message}"
PATTERNS_FILE="${PINJ0R_PATTERNS_FILE:-patterns.txt}"
REQUEST_TEMPLATE_FILE="${PINJ0R_REQUEST_TEMPLATE_FILE:-}"

if [ -z "$TARGET_URL" ]; then
  echo "ERROR: PINJ0R_TARGET_URL is not set" >&2
  exit 2
fi

if [ -z "$BEARER_TOKEN" ]; then
  echo "ERROR: PINJ0R_BEARER_TOKEN is not set" >&2
  exit 2
fi

case "$JSON_FIELD" in
  *[!A-Za-z0-9_-]*|"")
    echo "ERROR: PINJ0R_JSON_FIELD must contain only letters, numbers, underscores, or hyphens" >&2
    exit 2
    ;;
esac

if [ -n "$REQUEST_TEMPLATE_FILE" ]; then
  if [ ! -f "$REQUEST_TEMPLATE_FILE" ]; then
    echo "ERROR: request template file not found: $REQUEST_TEMPLATE_FILE" >&2
    exit 2
  fi

  if ! grep -Fq "{{prompt}}" "$REQUEST_TEMPLATE_FILE"; then
    echo "ERROR: request template must contain {{prompt}}" >&2
    exit 2
  fi
fi

if [ -n "$ATTACKS_FILE" ]; then
  if [ ! -f "$ATTACKS_FILE" ]; then
    echo "ERROR: attacks file not found: $ATTACKS_FILE" >&2
    exit 2
  fi
elif [ ! -d "$ATTACKS_DIR" ]; then
  echo "ERROR: attacks directory not found: $ATTACKS_DIR" >&2
  exit 2
fi

if [ ! -f "$PATTERNS_FILE" ]; then
  echo "ERROR: patterns file not found: $PATTERNS_FILE" >&2
  exit 2
fi

mkdir -p "$RESULTS_DIR"

SUMMARY="$RESULTS_DIR/summary.md"
: > "$SUMMARY"

printf "# Pinj0r summary\n\n" >> "$SUMMARY"
printf 'Target: `%s`\n\n' "$TARGET_URL" >> "$SUMMARY"
if [ -n "$REQUEST_TEMPLATE_FILE" ]; then
  printf 'Request template: `%s`\n\n' "$REQUEST_TEMPLATE_FILE" >> "$SUMMARY"
else
  printf 'JSON field: `%s`\n\n' "$JSON_FIELD" >> "$SUMMARY"
fi
printf 'Patterns: `%s`\n\n' "$PATTERNS_FILE" >> "$SUMMARY"

suspicious=0
total=0
endpoint_error=0

match_pattern() {
  file="$1"

  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in
      ""|\#*) continue ;;
    esac

    if grep -Fqi "$pattern" "$file"; then
      printf '%s\n' "$pattern"
      return 0
    fi
  done < "$PATTERNS_FILE"

  return 1
}

json_escape() {
  printf '%s' "$1" \
    | sed 's/\\/\\\\/g' \
    | sed 's/"/\\"/g'
}

sed_replacement_escape() {
  printf '%s' "$1" \
    | sed 's/[\/&]/\\&/g'
}

build_request_body() {
  escaped_prompt="$1"

  if [ -n "$REQUEST_TEMPLATE_FILE" ]; then
    replacement=$(sed_replacement_escape "$escaped_prompt")
    sed "s/{{prompt}}/$replacement/g" "$REQUEST_TEMPLATE_FILE"
  else
    printf '{"%s":"%s"}' "$JSON_FIELD" "$escaped_prompt"
  fi
}

safe_name() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9_-]/_/g'
}

run_attacks_file() {
  attack_file="$1"
  category=$(basename "$attack_file" .txt)
  category=$(safe_name "$category")
  i=0

  while IFS= read -r prompt || [ -n "$prompt" ]; do
    [ -z "$prompt" ] && continue

    i=$((i + 1))
    total=$((total + 1))
    num=$(printf "%03d" "$i")
    out="$RESULTS_DIR/${category}_${num}.json"

    escaped_prompt=$(json_escape "$prompt")
    request_body=$(build_request_body "$escaped_prompt")

    status="PASS"
    matched_pattern=""
    http_status=""

    if http_status=$(curl -sS -o "$out" -w "%{http_code}" "$TARGET_URL" \
      -H "Authorization: Bearer $BEARER_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$request_body"); then
      if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
        status="ERROR"
        endpoint_error=1
      elif matched_pattern=$(match_pattern "$out"); then
        status="SUSPICIOUS"
        suspicious=1
      fi
    else
      status="ERROR"
      endpoint_error=1
      : > "$out"
    fi

    printf "## %s %s - %s\n\n" "$category" "$num" "$status" >> "$SUMMARY"
    printf '**Source:** `%s`\n\n' "$attack_file" >> "$SUMMARY"
    if [ -n "$http_status" ]; then
      printf '**HTTP status:** `%s`\n\n' "$http_status" >> "$SUMMARY"
    fi
    if [ -n "$matched_pattern" ]; then
      printf '**Matched pattern:** `%s`\n\n' "$matched_pattern" >> "$SUMMARY"
    fi
    printf "**Prompt:**\n\n" >> "$SUMMARY"
    printf '```text\n%s\n```\n\n' "$prompt" >> "$SUMMARY"
    printf '**Raw response:** `%s`\n\n' "$out" >> "$SUMMARY"

    echo "[$status] $category/$num $prompt"
  done < "$attack_file"
}

attack_files=0

if [ -n "$ATTACKS_FILE" ]; then
  attack_files=1
  run_attacks_file "$ATTACKS_FILE"
else
  for attack_file in "$ATTACKS_DIR"/*.txt; do
    [ -f "$attack_file" ] || continue
    attack_files=$((attack_files + 1))
    run_attacks_file "$attack_file"
  done
fi

if [ "$attack_files" -eq 0 ]; then
  echo "ERROR: no .txt attack files found in $ATTACKS_DIR" >&2
  exit 2
fi

if [ "$total" -eq 0 ]; then
  echo "ERROR: no prompts found" >&2
  exit 2
fi

echo
echo "Summary written to $SUMMARY"

if [ "$endpoint_error" -eq 1 ]; then
  if [ "$CI_MODE" -eq 1 ]; then
    echo "CI result: endpoint error"
  fi
  exit 2
fi

if [ "$suspicious" -eq 1 ]; then
  if [ "$CI_MODE" -eq 1 ]; then
    echo "CI result: suspicious response found"
  fi
  exit 1
fi

if [ "$CI_MODE" -eq 1 ]; then
  echo "CI result: no suspicious response found"
fi

exit 0
