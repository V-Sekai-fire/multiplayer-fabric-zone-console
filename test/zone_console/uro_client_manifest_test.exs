defmodule ZoneConsole.UroClientManifestTest do
  use ExUnit.Case, async: false

  setup do
    client =
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

    scene_path = System.fetch_env!("TEST_SCENE_PATH")
    {:ok, id} = ZoneConsole.UroClient.upload_asset(client, scene_path, Path.basename(scene_path))

    {:ok, %{client: client, id: id}}
  end

  @tag :prod
  test "get_manifest returns store_url and non-empty chunk list", %{client: c, id: id} do
    {:ok, manifest} = ZoneConsole.UroClient.get_manifest(c, id)

    store_url = manifest["store_url"] || manifest[:store_url]
    chunks = manifest["chunks"] || manifest[:chunks]

    assert is_binary(store_url), "manifest must have store_url"
    assert is_list(chunks), "manifest must have chunks list"
    assert length(chunks) > 0, "chunks must not be empty"
  end

  @tag :prod
  test "each chunk has id and 64-char sha512_256 hex", %{client: c, id: id} do
    {:ok, manifest} = ZoneConsole.UroClient.get_manifest(c, id)
    chunks = manifest["chunks"] || manifest[:chunks]

    Enum.each(chunks, fn chunk ->
      chunk_id = chunk["id"] || chunk[:id]
      sha = chunk["sha512_256"] || chunk[:sha512_256]
      assert is_binary(chunk_id), "chunk id must be binary"
      assert is_binary(sha), "chunk sha512_256 must be binary"
      assert byte_size(sha) == 64, "SHA-512/256 hex must be 64 chars"
    end)
  end
end
