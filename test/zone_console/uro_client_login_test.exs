defmodule ZoneConsole.UroClientLoginTest do
  @moduledoc """
  Cycle 1 RED: UroClient.login/3 authenticates against prod uro.

  Requires env vars:
    URO_BASE_URL  — https://uro.chibifire.com
    URO_EMAIL     — operator email
    URO_PASSWORD  — operator password

  Run with:
    mix test --only prod test/zone_console/uro_client_login_test.exs
  """

  use ExUnit.Case, async: false

  @tag :prod
  test "login returns bearer token from prod uro" do
    base_url = System.fetch_env!("URO_BASE_URL")
    email = System.fetch_env!("URO_EMAIL")
    password = System.fetch_env!("URO_PASSWORD")

    client = ZoneConsole.UroClient.new(base_url)
    {:ok, authed} = ZoneConsole.UroClient.login(client, email, password)

    assert is_binary(authed.access_token)
    assert byte_size(authed.access_token) > 0
    assert is_map(authed.user)
  end

  @tag :prod
  test "login with wrong password returns error tuple, not raise" do
    base_url = System.fetch_env!("URO_BASE_URL")

    client = ZoneConsole.UroClient.new(base_url)
    result = ZoneConsole.UroClient.login(client, "nobody@example.com", "wrong")

    assert match?({:error, _}, result),
           "bad credentials must return {:error, _} not raise"
  end
end
