# PLAN.md

Development plan for `pinj`.

## Goal

Build a minimal prompt-injection smoke-test tool for LLM and agent endpoints.

`pinj` should help answer one simple question:

> Does this endpoint fail obvious prompt-injection checks?

It is not a full security scanner. It is a smoke test.

---

## v0.1 — Shell Prototype

Status: planned

### Features

- Read prompts from `attacks.txt`
- Send each prompt to `PINJ_TARGET_URL`
- Use bearer token from `PINJ_BEARER_TOKEN`
- Store raw responses in `results/`
- Generate `results/summary.md`
- Flag obvious suspicious responses by keyword
- Return non-zero exit code if suspicious output is detected

### Files

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

### Assumed API Shape

Request:

```json
{
  "message": "user prompt here"
}
```

Response:

Any JSON response.

`pinj` v0.1 stores the full raw response and does not require a fixed response schema.

---

## v0.2 — Configurable Request Body

Make request body configurable.

Possible approaches:

```sh
export PINJ_JSON_FIELD="message"
```

or:

```sh
export PINJ_REQUEST_TEMPLATE='{"message":"{{PROMPT}}"}'
```

Keep this simple.

---

## v0.3 — Better Detection

Add configurable suspicious patterns.

Possible file:

```text
patterns.txt
```

Example patterns:

```text
system prompt
developer message
hidden instruction
api key
bearer
secret
password
token
```

---

## v0.4 — CI Mode

Add stable CI behavior.

```sh
./run.sh --ci
```

CI output:

- exit `0`: no suspicious response found
- exit `1`: suspicious response found
- exit `2`: configuration or endpoint error

---

## v0.5 — Rust CLI

Rewrite core as Rust CLI if the shell version proves useful.

Possible command:

```sh
pinj run \
  --target https://example.com/chat \
  --attacks attacks.txt \
  --out results/
```

Possible crates:

- `clap`
- `reqwest`
- `serde_json`
- `anyhow`

---

## Future Ideas

- OWASP LLM Top 10 prompt corpus
- indirect prompt-injection tests
- secret-leak tests
- denial-of-wallet tests
- tool-call permission tests
- model-as-judge scoring
- SARIF or JUnit XML export
- GitHub Actions integration
- Docker image
