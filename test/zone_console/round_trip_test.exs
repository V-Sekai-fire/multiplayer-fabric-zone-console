defmodule ZoneConsole.RoundTripTest do
  use ExUnit.Case, async: false

  defp authed_client do
    ZoneConsole.UroClient.new(System.fetch_env!("URO_BASE_URL"))
    |> then(fn c ->
      {:ok, a} = ZoneConsole.UroClient.login(c,
        System.fetch_env!("URO_EMAIL"), System.fetch_env!("URO_PASSWORD"))
      a
    end)
  end

  @tag :prod
  test "full pipeline: login → upload → bake → instance → entity list" do
    client     = authed_client()
    scene_path = System.fetch_env!("TEST_SCENE_PATH")
    {:ok, id}  = ZoneConsole.UroClient.upload_asset(client, scene_path,
      Path.basename(scene_path))

    baked_url =
      Enum.find_value(1..30, fn _ ->
        {:ok, m} = ZoneConsole.UroClient.get_manifest(client, id)
        url = m["baked_url"] || m[:baked_url]
        if url, do: url, else: (Process.sleep(1_000); nil)
      end)

    assert is_binary(baked_url), "baked_url must appear within 30 s"

    url = System.fetch_env!("ZONE_SERVER_URL")
    pin = System.fetch_env!("ZONE_CERT_PIN")
    {:ok, zc} = ZoneConsole.ZoneClient.start_link(url, pin, 1, self())

    ZoneConsole.ZoneClient.send_instance(zc, String.to_integer(id), 0.0, 1.0, 0.0)

    assert_receive {:zone_entities, entities}, 2_000

    found = Enum.any?(Map.values(entities), fn e -> abs(e.cy - 1.0) < 0.5 end)
    assert found, "entity near y=1.0 must appear in zone entity list"

    ZoneConsole.ZoneClient.stop(zc)
  end
end
