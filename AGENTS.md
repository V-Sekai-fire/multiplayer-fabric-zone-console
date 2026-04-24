# AGENTS.md — multiplayer-fabric-zone-console

Guidance for AI coding agents working in this submodule.

## What this is

Operator CLI for the multiplayer-fabric zone stack. Built as an escript
(`mix escript.build` → `./zone_console`). Supports login, asset upload,
bake-status polling, zone join, entity instancing, and entity listing.
Uses `wtransport` (Rust NIF) for WebTransport zone connections and
`aria_storage` for chunk retrieval.

See the PoC runbook in the root `AGENTS.md` (cycles 9–10) for the
full end-to-end flow.

## Build and test

```sh
mix escript.build      # produces ./zone_console binary
mix test               # ExUnit + PropCheck
mix format --check-formatted
```

## Required env vars (integration tests)

```sh
URO_BASE_URL=https://uro.example.com
URO_EMAIL=user@example.com
URO_PASSWORD=secret
ZONE_CERT_HASH_B64=<base64-encoded-cert-hash>
```

## Key files

| Path | Purpose |
|------|---------|
| `mix.exs` | Deps: ex_ratatui, req, jason, wtransport (GitHub), aria_storage (GitHub) |
| `lib/zone_console/cli.ex` | Escript main module (`ZoneConsole.CLI`) |
| `lib/zone_console/uro_client.ex` | Login, upload, manifest HTTP calls |
| `lib/zone_console/zone_client.ex` | Zone join and entity commands via WebTransport |
| `lib/zone_console/console_connection_handler.ex` | WebTransport session lifecycle |
| `lib/zone_console/keychain.ex` | Credential storage |

## Conventions

- All public functions return `{:ok, value}` or `{:error, reason}`.
- Every new `.ex` / `.exs` file needs SPDX headers:
  ```elixir
  # SPDX-License-Identifier: MIT
  # Copyright (c) 2026 K. S. Ernest (iFire) Lee
  ```
- Commit message style: sentence case, no `type(scope):` prefix.
  Example: `Add bake-status command with 2-second polling loop`
