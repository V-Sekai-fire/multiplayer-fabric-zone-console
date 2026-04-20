# Contributing

An Elixir CLI console for interacting with a multiplayer-fabric zone.
Manages asset uploads, scene instancing, and live zone inspection over
HTTP (to the Uro backend) and WebTransport datagrams (to the zone
process).  Ships as an escript binary; the WebTransport binding is a
vendored Rust NIF under `native/`.

Built strictly red-green-refactor: every feature is driven by failing
tests, committed when green, then any cleanup is done with the tests
still green.  PropCheck properties cover protocol message encoding and
command dispatch.

## Guiding principles

- **RED first, always.** Write a failing test or property before any
  implementation.  Confirm the failure is for the right reason.
- **Error tuples, not exceptions.** HTTP and WebTransport errors are
  always `{:error, reason}` tuples.  The TUI layer displays the error;
  it never rescues it and retries silently.
- **TUI state is pure.** Ratatui rendering functions take a model and
  return a new model.  Side effects (HTTP calls, datagram sends) run in
  `Task` calls that send messages back to the event loop.
- **Escript portability.** The binary must run without Elixir installed.
  Verify with `mix escript.build` followed by running the output on a
  machine with no Elixir runtime.
- **NIF boundary safety.** The WebTransport Rust NIF must handle all
  error conditions and return `{:error, reason}` atoms; it must never
  panic.  A NIF panic crashes the BEAM VM.
- **Commit every green.** One commit per feature cycle.

## Workflow

```
mix deps.get
mix test                   # ExUnit + PropCheck suite
mix escript.build          # produces ./zone_console binary
./zone_console --help      # smoke test
```

To rebuild the Rust NIF:

```
cd native && cargo build --release && cd ..
mix compile
```

## Design notes

### HTTP vs WebTransport split

Commands that modify persistent state (asset upload, scene config) go
over HTTP to the Uro backend — these need the reliability and auth
middleware of the Phoenix request pipeline.  Real-time zone commands
(teleport, object grab, voice activation) go over WebTransport
datagrams to the zone process directly for low latency.  The console
maintains both connections simultaneously; the command router in
`lib/zone_console/router.ex` decides which transport to use per
command.

### vendored wtransport_elixir

`vendor/wtransport_elixir/` is a pinned copy of the WebTransport
Elixir binding, not a Git submodule.  To update it, copy the new
version over the directory and run `mix compile` to rebuild the NIF.
Do not add it as a Hex dependency — the pinned copy allows local
patches without a published release.

### PropCheck coverage

Protocol message encoding (datagram framing, command serialization)
is covered by PropCheck generators rather than hand-written fixtures.
New protocol commands must add a generator in
`test/support/generators.ex` and a round-trip property in
`test/zone_console/protocol_prop_test.exs`.
