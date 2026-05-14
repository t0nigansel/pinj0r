# AGENTS.md

Guidance for AI coding agents working on `pinj`.

## Project

`pinj` is a small Unix-style CLI tool for running prompt-injection baseline security checks against LLM or agent HTTP endpoints.

The first version is intentionally simple:

- Shell-based
- Reads attack prompts from a text file
- Sends each prompt to a target endpoint
- Uses bearer-token authentication
- Stores raw responses
- Creates a simple Markdown summary
- Flags obvious suspicious responses with keyword matching

## Design Principles

- Keep it small.
- Prefer readable code over clever code.
- Do not build a framework too early.
- Every test should be understandable by a QA/security engineer.
- False positives are acceptable for baseline security checks.
- False confidence is not acceptable.

## Language Choices

Preferred:

- POSIX shell for simple probes
- Rust for future serious CLI versions
- Java only for enterprise QA integrations

Avoid:

- Python by default
- large dependency trees
- complex config formats in v1

## Security Notes

`pinj` must not include real secrets in examples.

Use environment variables for tokens:

```sh
export PINJ_BEARER_TOKEN="..."
```

Never commit real test results from private systems.

## Scope v1

In scope:

- HTTP POST endpoint
- JSON request body
- bearer-token auth
- newline-separated prompt corpus
- raw response capture
- naive suspicious keyword detection

Out of scope:

- advanced scoring
- model-as-judge evaluation
- browser automation
- multi-step agents
- tool-call tracing
- full OWASP coverage

## Coding Style

Shell scripts should use:

```sh
#!/usr/bin/env sh
set -eu
```

Avoid Bash-only features unless the file explicitly uses Bash.

All generated output should go into `results/`.

## CLI Direction

Current:

```sh
./run.sh
```

Possible future:

```sh
pinj run
pinj run --target https://example.com/chat
pinj init
pinj report
```
