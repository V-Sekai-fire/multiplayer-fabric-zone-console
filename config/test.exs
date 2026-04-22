# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

import Config

# AriaStorage.Repo starts as part of aria_storage's supervision tree.
# Give it an in-memory database so tests don't need a writable filesystem.
config :aria_storage, AriaStorage.Repo,
  database: ":memory:",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1
