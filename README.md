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
- one prompt per line in `attacks.txt`

Default request body:

```json
{
  "message": "prompt text"
}
```

---

## Files

```text
pinj/
  README.md
  AGENTS.md
  PLAN.md
  attacks.txt
  config.example.env
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
```

Load it:

```sh
. ./.env
```

Run:

```sh
./run.sh
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
  response_001.json
  response_002.json
  response_003.json
  summary.md
```

---

## Exit Codes

```text
0 = no obvious suspicious response found
1 = suspicious response found
2 = configuration or runtime error
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
attacks.txt
```

The initial corpus includes basic checks for:

- instruction override
- system prompt extraction
- hidden config leakage
- tool misuse
- excessive output
