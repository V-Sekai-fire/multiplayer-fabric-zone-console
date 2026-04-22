defmodule ZoneConsole.MultiPlatformTest do
  use ExUnit.Case, async: false
  import Bitwise

  @platform (case :os.type() do
               {:unix, :darwin} -> :macos
               {:unix, :linux} -> :linux
               {:win32, :nt} -> :windows
             end)

  # Accepts both decimal strings and UUID strings.
  defp parse_asset_id(str) do
    clean = String.replace(str, "-", "")

    if String.match?(clean, ~r/^[0-9]+$/) do
      String.to_integer(clean)
    else
      String.to_integer(clean, 16) |> band(0xFFFFFFFFFFFFFFFF)
    end
  end

  @tag :prod
  test "zone_console connects and instances on #{@platform}" do
    url = System.fetch_env!("ZONE_SERVER_URL")
    pin = System.fetch_env!("ZONE_CERT_PIN")
    asset_id = parse_asset_id(System.fetch_env!("TEST_ASSET_ID"))

    {:ok, zc} = ZoneConsole.ZoneClient.start_link(url, pin, 1, self())
    ZoneConsole.ZoneClient.send_instance(zc, asset_id, 0.0, 1.0, 0.0)

    assert_receive {:zone_entities, entities}, 2_000
    found = Enum.any?(Map.values(entities), fn e -> abs(e.cy - 1.0) < 0.5 end)
    assert found, "#{@platform}: entity near y=1.0 must appear"

    ZoneConsole.ZoneClient.stop(zc)
  end

  @tag :prod
  @tag :accesskit
  test "AccessKit tree shows instanced node on #{@platform}" do
    asset_id = System.fetch_env!("TEST_ASSET_ID")

    {:ok, ax_tree} = ZoneConsole.AccessKit.get_tree(@platform)

    node =
      Enum.find(ax_tree[:nodes] || [], fn n ->
        n[:label] == asset_id or n["label"] == asset_id
      end)

    assert node != nil, "#{@platform}: instanced node must appear in AccessKit tree"
    assert node[:accessible] == true or node["accessible"] == true
  end
end
