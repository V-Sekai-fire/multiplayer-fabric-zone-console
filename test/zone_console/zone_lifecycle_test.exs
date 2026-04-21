defmodule ZoneConsole.ZoneLifecycleTest do
  use ExUnit.Case, async: false

  defp authed_client do
    ZoneConsole.UroClient.new(System.fetch_env!("URO_BASE_URL"))
    |> then(fn c ->
      {:ok, a} = ZoneConsole.UroClient.login(c,
        System.fetch_env!("URO_EMAIL"),
        System.fetch_env!("URO_PASSWORD"))
      a
    end)
  end

  @tag :prod
  test "GET /zones returns at least one running zone" do
    {:ok, zones} = ZoneConsole.UroClient.list_zones(authed_client())
    assert length(zones) >= 1
  end

  @tag :prod
  test "each zone entry has address, port, and cert_hash" do
    {:ok, zones} = ZoneConsole.UroClient.list_zones(authed_client())

    Enum.each(zones, fn zone ->
      assert is_binary(zone["address"] || zone[:address]),
             "zone must have address"
      assert is_integer(zone["port"] || zone[:port]),
             "zone must have integer port"
      assert is_binary(zone["cert_hash"] || zone[:cert_hash]),
             "zone must have cert_hash"
    end)
  end
end
