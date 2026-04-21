defmodule ZoneConsole.InstanceCommandTest do
  use ExUnit.Case, async: false

  @tag :prod
  test "instance command reaches zone server and gets entity snapshot" do
    url      = System.fetch_env!("ZONE_SERVER_URL")
    cert_pin = System.fetch_env!("ZONE_CERT_PIN")
    asset_id = System.fetch_env!("TEST_ASSET_ID")

    player_id = :rand.uniform(0x7FFFFFFF)
    {:ok, zc} = ZoneConsole.ZoneClient.start_link(url, cert_pin, player_id, self())

    ZoneConsole.ZoneClient.send_instance(zc,
      String.to_integer(asset_id), 0.0, 1.0, 0.0)

    assert_receive {:zone_entities, entities}, 500
    assert is_map(entities)

    ZoneConsole.ZoneClient.stop(zc)
  end
end
