defmodule ZoneConsole.ZoneHandlerTest do
  use ExUnit.Case, async: false

  @tag :prod
  test "CMD_INSTANCE_ASSET reaches authority zone and entity appears in list" do
    url      = System.fetch_env!("ZONE_SERVER_URL")
    pin      = System.fetch_env!("ZONE_CERT_PIN")
    asset_id = String.to_integer(System.fetch_env!("TEST_ASSET_ID"))

    {:ok, zc} = ZoneConsole.ZoneClient.start_link(url, pin, 1, self())
    ZoneConsole.ZoneClient.send_instance(zc, asset_id, 0.0, 1.0, 0.0)

    assert_receive {:zone_entities, entities}, 2_000

    found = Enum.any?(Map.values(entities), fn e ->
      abs(e.cy - 1.0) < 0.5
    end)
    assert found, "entity near y=1.0 must appear in zone entity list"

    ZoneConsole.ZoneClient.stop(zc)
  end
end
