defmodule ZoneConsole.ZoneLifecycleTest do
  use ExUnit.Case, async: false

  defp authed_client do
    ZoneConsole.UroClient.new(System.fetch_env!("URO_BASE_URL"))
    |> then(fn c ->
      {:ok, a} =
        ZoneConsole.UroClient.login(
          c,
          System.fetch_env!("URO_EMAIL"),
          System.fetch_env!("URO_PASSWORD")
        )

      a
    end)
  end

  @tag :prod
  test "GET /shards returns at least one running shard" do
    {:ok, shards} = ZoneConsole.UroClient.list_shards(authed_client())
    assert length(shards) >= 1
  end

  @tag :prod
  test "each shard entry has address, port, and cert_hash" do
    {:ok, shards} = ZoneConsole.UroClient.list_shards(authed_client())

    Enum.each(shards, fn shard ->
      assert is_binary(shard["address"] || shard[:address]),
             "shard must have address"

      assert is_integer(shard["port"] || shard[:port]),
             "shard must have integer port"

      assert is_binary(shard["cert_hash"] || shard[:cert_hash]),
             "shard must have cert_hash"
    end)
  end
end
