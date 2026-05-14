# PLAN.md

Development plan for `pinj`.

## Goal

Build a minimal prompt-injection baseline security check for LLM and agent endpoints.

`pinj` should help answer one simple question:

> Does this endpoint fail obvious prompt-injection checks?

It is not a full security scanner. It is a baseline security check.

---

## v0.1 — Shell Prototype

Status: implemented

### Features

- Read prompts from attack corpus files
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
  attacks/
  config.example.env
  patterns.txt
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

## v0.2 — Attack Corpus Directory

Status: implemented

- Support `attacks/` directory
- Run every `*.txt` file inside it
- Treat each file as a category
- Keep one prompt per line
- Include category in result filenames and summary
- Keep `PINJ_ATTACKS_FILE` for single-file runs

---

## v0.3 — Configurable Request Body

Status: implemented

Make the request body field configurable:

```sh
export PINJ_JSON_FIELD="message"
```

Default request body:

```json
{
  "message": "user prompt here"
}
```

Example with `PINJ_JSON_FIELD=input`:

```json
{
  "input": "user prompt here"
}
```

---

## v0.4 — Better Detection

Status: implemented

Add configurable suspicious patterns.

Patterns file:

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

- Read suspicious patterns from `patterns.txt`
- Ignore blank lines and `#` comments
- Match patterns case-insensitively
- Include the matched pattern in `results/summary.md`
- Allow overrides with `PINJ_PATTERNS_FILE`

---

## v0.5 — CI Mode

Status: implemented

Add stable CI behavior.

```sh
./run.sh --ci
```

CI output:

- exit `0`: no suspicious response found
- exit `1`: suspicious response found
- exit `2`: configuration or endpoint error

Endpoint errors include curl failures and non-2xx HTTP responses.

---

## v0.6 — Rust CLI

Status: removed

Keep `pinj` as a shell script while that stays useful.

Rust is not needed unless the shell version becomes too hard to maintain.

---

## v0.6 — Request Body Templates

Status: implemented

Allow raw JSON request body templates with a `{{prompt}}` injection point.

```sh
export PINJ_REQUEST_TEMPLATE_FILE="request.template.example.json"
```

Example template:

```json
{
  "messages": [
    {
      "role": "user",
      "content": "{{prompt}}"
    }
  ]
}
```

This takes precedence over `PINJ_JSON_FIELD`.

---

## v0.7 — Expanded Attack Corpus

Status: implemented

Expand attack prompts into categories inspired by OWASP LLM01 and related OWASP LLM Top 10 risks, plus MITRE ATLAS direct and indirect prompt injection concepts.

Categories include:

- direct injection
- indirect injection
- system prompt leakage
- sensitive disclosure
- tool and agency misuse
- output handling
- RAG content manipulation
- decision manipulation
- cost harvesting
- multimodal hidden instructions
- jailbreak roleplay
- format bypass

---

## Future Ideas

- tool-call permission tests
- model-as-judge scoring
- SARIF or JUnit XML export
- GitHub Actions integration
- Docker image
