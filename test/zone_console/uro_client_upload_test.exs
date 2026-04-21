defmodule ZoneConsole.UroClientUploadTest do
  @moduledoc """
  Cycle 2 RED: UroClient.upload_asset/3 chunks a scene file,
  uploads to VersityGW (local S3), and registers a manifest in uro.

  Requires env vars:
    URO_BASE_URL      — https://hub-700a.chibifire.com
    URO_EMAIL         — operator@chibifire.com
    URO_PASSWORD      — op3rator!2026
    TEST_SCENE_PATH   — path to a .tscn or .glb file
    AWS_S3_BUCKET     — uro-uploads
    AWS_S3_ENDPOINT   — http://localhost:7070
    AWS_ACCESS_KEY_ID — minioadmin
    AWS_SECRET_ACCESS_KEY — minioadmin

  Run with:
    mix test --only prod test/zone_console/uro_client_upload_test.exs
  """

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
  test "upload_asset stores file and returns non-empty id" do
    client = authed_client()
    scene_path = System.fetch_env!("TEST_SCENE_PATH")

    {:ok, id} =
      ZoneConsole.UroClient.upload_asset(client, scene_path, Path.basename(scene_path))

    assert is_binary(id)
    assert byte_size(id) > 0
  end

  @tag :prod
  test "uploaded asset is queryable via GET /storage/:id" do
    client = authed_client()
    scene_path = System.fetch_env!("TEST_SCENE_PATH")

    {:ok, id} =
      ZoneConsole.UroClient.upload_asset(client, scene_path, Path.basename(scene_path))

    result =
      Req.get("#{System.fetch_env!("URO_BASE_URL")}/storage/#{id}",
        headers: [{"authorization", "Bearer #{client.access_token}"}]
      )

    assert match?({:ok, %{status: 200}}, result),
           "GET /storage/#{id} must return 200, got: #{inspect(result)}"
  end
end
