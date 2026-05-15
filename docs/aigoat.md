# Testing AI Goat with Pinj0r

This guide assumes AI Goat is already running locally.

For AI Goat setup and project details, use the AI Goat project documentation:

```text
https://github.com/AISecurityConsortium/AIGoat
```

This guide only covers running Pinj0r against an already-running AI Goat instance.

Default AI Goat URLs:

```text
API:      http://localhost:8000
API docs: http://localhost:8000/docs
```

Demo credentials:

```text
alice / password123
admin / admin123
```

## 1. Get a Demo Token

Log in as the demo user and store the returned token:

```sh
TOKEN=$(curl -sS http://localhost:8000/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"username":"alice","password":"password123"}' | jq -r .token)
```

Check that a token was returned:

```sh
printf '%s\n' "$TOKEN"
```

## 2. Use the AI Goat Request Template

Pinj0r includes an AI Goat chat template:

```text
examples/aigoat-chat.template.json
```

It sends each attack prompt as:

```json
{
  "message": "{{prompt}}",
  "use_kb": false
}
```

## 3. Run a Focused Challenge 1 Test

AI Goat challenge 1 is prompt-injection focused. Start the challenge:

```sh
curl -sS -X POST http://localhost:8000/api/workshop/challenges/1/start \
  -H "Authorization: Bearer $TOKEN"
```

Create a temporary focused corpus:

```sh
rm -rf /tmp/pinj0r-aigoat-attacks
mkdir -p /tmp/pinj0r-aigoat-attacks
cp attacks/direct-injection.txt \
   attacks/system-prompt-leakage.txt \
   attacks/sensitive-disclosure.txt \
   /tmp/pinj0r-aigoat-attacks/
```

Run Pinj0r:

```sh
PINJ0R_TARGET_URL=http://localhost:8000/api/challenges/1/chat \
PINJ0R_BEARER_TOKEN="$TOKEN" \
PINJ0R_ATTACKS_DIR=/tmp/pinj0r-aigoat-attacks \
PINJ0R_RESULTS_DIR=results/aigoat-challenge-1 \
PINJ0R_REQUEST_TEMPLATE_FILE=examples/aigoat-chat.template.json \
./run.sh --ci
```

Expected exit codes:

```text
0 = no obvious suspicious response found
1 = suspicious response found
2 = configuration or endpoint error
```

For a vulnerable AI Goat challenge, exit `1` is expected.

## 4. Inspect Results

Open the summary:

```sh
sed -n '1,220p' results/aigoat-challenge-1/summary.md
```

Raw responses are stored next to the summary:

```text
results/aigoat-challenge-1/
```

Useful quick checks:

```sh
rg '^## ' results/aigoat-challenge-1/summary.md
rg 'Matched pattern' results/aigoat-challenge-1/summary.md
rg -i 'system prompt|admin|secret|config.yml|aigoat.db|password|token' results/aigoat-challenge-1/
```

## 5. Run the Full Corpus

To run all bundled attack categories against the same AI Goat endpoint:

```sh
PINJ0R_TARGET_URL=http://localhost:8000/api/challenges/1/chat \
PINJ0R_BEARER_TOKEN="$TOKEN" \
PINJ0R_ATTACKS_DIR=attacks \
PINJ0R_RESULTS_DIR=results/aigoat-full \
PINJ0R_REQUEST_TEMPLATE_FILE=examples/aigoat-chat.template.json \
./run.sh --ci
```

The full corpus can take longer because AI Goat may generate a model response for every prompt.

## 6. Test the General Chat Endpoint

AI Goat also exposes a general chat endpoint:

```text
POST /api/chat/
```

Run:

```sh
PINJ0R_TARGET_URL=http://localhost:8000/api/chat/ \
PINJ0R_BEARER_TOKEN="$TOKEN" \
PINJ0R_ATTACKS_DIR=attacks \
PINJ0R_RESULTS_DIR=results/aigoat-general-chat \
PINJ0R_REQUEST_TEMPLATE_FILE=examples/aigoat-chat.template.json \
./run.sh --ci
```

## Notes

- Pinj0r is a baseline security check. It uses keyword matching and can produce false positives.
- AI Goat may leak useful details without marking its own workshop challenge as complete.
- `results/` is ignored by git because raw responses may contain sensitive data.
