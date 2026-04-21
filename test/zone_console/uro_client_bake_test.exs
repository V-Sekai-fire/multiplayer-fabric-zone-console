defmodule ZoneConsole.UroClientBakeTest do
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
  test "uploaded asset manifest includes baked_url after baker completes" do
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

    assert is_binary(baked_url), "manifest must have baked_url within 30 s"
    assert String.contains?(baked_url, "versitygw") or
           String.contains?(baked_url, "localhost") or
           String.contains?(baked_url, "7070"),
           "baked_url must point to local VersityGW store"
  end
end
