# pinj

`pinj` is a tiny prompt-injection smoke-test tool for LLM and agent HTTP endpoints.

It sends a small set of hostile prompts to a target endpoint, stores the raw responses, and flags obvious suspicious behavior.

`pinj` is intentionally simple.

It does not prove that an agent is secure.

It helps find endpoints that fail basic checks.

---

## Why?

LLM and agent applications often expose new failure modes:

- prompt injection
- system prompt leakage
- secret leakage
- role override
- tool misuse
- excessive output
- denial-of-wallet behavior

Before trusting an AI endpoint, run basic hostile prompts against it.

Failing these tests is a strong warning sign.

---

## Current Scope

`pinj` v0.1 assumes:

- HTTP POST endpoint
- JSON request body
- bearer-token authentication
- one prompt per line in each `attacks/*.txt` file

Default request body:

```json
{
  "message": "prompt text"
}
```

To use a different prompt field, set:

```sh
export PINJ_JSON_FIELD="input"
```

That sends:

```json
{
  "input": "prompt text"
}
```

---

## Files

```text
pinj/
  README.md
  AGENTS.md
  PLAN.md
  attacks/
  config.example.env
  patterns.txt
  request.template.example.json
  run.sh
  results/
```

---

## Setup

Copy the example config:

```sh
cp config.example.env .env
```

Edit `.env`:

```sh
PINJ_TARGET_URL="https://example.com/chat"
PINJ_BEARER_TOKEN="replace-me"
PINJ_ATTACKS_DIR="attacks"
PINJ_JSON_FIELD="message"
PINJ_PATTERNS_FILE="patterns.txt"
```

Load it:

```sh
. ./.env
```

Run:

```sh
./run.sh
```

For CI:

```sh
./run.sh --ci
```

Testing AI Goat:

```text
docs/aigoat.md
```

---

## Quick Start

```sh
cp config.example.env .env
```

Edit `.env`:

```sh
export PINJ_TARGET_URL="https://example.com/chat"
export PINJ_BEARER_TOKEN="replace-me"
export PINJ_ATTACKS_DIR="attacks"
export PINJ_PATTERNS_FILE="patterns.txt"
```

Then run:

```sh
. ./.env
./run.sh
```

For CI:

```sh
./run.sh --ci
```

---

## Output

Results are written to:

```text
results/
```

Example:

```text
results/
  attacks_001.json
  attacks_002.json
  secrets_001.json
  summary.md
```

## Attack Corpus

Attack prompts live in plain text files under:

```text
attacks/
```

Each `.txt` file is treated as a category. Each non-empty line is sent as one prompt.

Example:

```text
attacks/
  attacks.txt
  secrets.txt
  tools.txt
```

To add or remove tests, edit those files or add another `.txt` file.

For compatibility with a single file, you can also set:

```sh
export PINJ_ATTACKS_FILE="attacks/direct-injection.txt"
```

---

## Request Templates

By default, `pinj` sends:

```json
{
  "message": "prompt text"
}
```

For endpoints that expect a different JSON shape, create a request template file and put `{{prompt}}` where each attack prompt should be injected.

Example:

```json
{
  "messages": [
    {
      "role": "user",
      "content": "{{prompt}}"
    }
  ],
  "temperature": 0
}
```

Then set:

```sh
export PINJ_REQUEST_TEMPLATE_FILE="request.template.json"
```

When `PINJ_REQUEST_TEMPLATE_FILE` is set, it takes precedence over `PINJ_JSON_FIELD`.

`pinj` does not execute raw pasted curl commands. Keep method, URL, bearer token, and content type in the existing environment variables, and use the template file for the request body.

Example templates are available in:

```text
examples/
```

For example:

```sh
export PINJ_REQUEST_TEMPLATE_FILE="examples/openai-chat.template.json"
```

---

## Suspicious Patterns

Suspicious response patterns live in:

```text
patterns.txt
```

Each non-empty line is matched case-insensitively against the raw response. Lines starting with `#` are ignored.

Example:

```text
system prompt
developer message
api key
secret
token
```

To use a different patterns file, set:

```sh
export PINJ_PATTERNS_FILE="my-patterns.txt"
```

---

## Exit Codes

```text
0 = no obvious suspicious response found
1 = suspicious response found
2 = configuration or runtime error
```

In CI mode, endpoint errors such as curl failures or non-2xx HTTP responses exit with `2`.

---

## Tests

Run the shell checks with:

```sh
./tests/run-tests.sh
```

---

## Limitations

`pinj` v0.1 uses naive keyword matching.

It may produce false positives.

It may miss real vulnerabilities.

It is a smoke test, not a full security assessment.

---

## Example Attack Prompts

See:

```text
attacks/
```

The initial corpus includes basic checks for:

- direct and indirect prompt injection
- system prompt leakage
- sensitive data disclosure
- excessive agency and tool misuse
- unsafe output handling
- RAG content manipulation
- decision manipulation
- cost harvesting
- multimodal hidden instructions
- jailbreak roleplay
- format bypass
