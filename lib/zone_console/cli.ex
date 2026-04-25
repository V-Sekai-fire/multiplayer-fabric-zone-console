defmodule ZoneConsole.CLI do
  @moduledoc "Escript entry point — authenticate against Uro then launch the TUI."

  alias ZoneConsole.{Keychain, UroClient}

  @kc_package "org.v-sekai.godot"
  @kc_service "zone_console"
  @kc_account "uro_session"

  def main(args) do
    load_dotenv()

    uro_url =
      Enum.at(args, 0) ||
        System.get_env("URO_URL") ||
        "http://localhost:8888"

    IO.puts("Uro: #{uro_url}")

    {authed, fresh?} =
      with {:cached, {:ok, token}} <-
             {:cached, Keychain.get_password(@kc_package, @kc_service, @kc_account)},
           client = %UroClient{base_url: uro_url, access_token: token},
           {:ok, verified} <- UroClient.current_user(client) do
        IO.puts("(session restored from keychain)")
        {verified, false}
      else
        _ -> {fresh_login(uro_url), true}
      end

    Application.put_env(:zone_console, :uro_client, authed)

    ensure_console_cert(authed, fresh?)

    {:ok, _pid} = ZoneConsole.App.start_link([])
    Process.sleep(:infinity)
  end

  defp fresh_login(uro_url) do
    username =
      System.get_env("URO_USERNAME") ||
        IO.gets("username: ") |> String.trim()

    password =
      System.get_env("URO_PASSWORD") ||
        IO.gets("password: ") |> String.trim()

    case UroClient.login(UroClient.new(uro_url), username, password) do
      {:ok, authed} ->
        Keychain.set_password(@kc_package, @kc_service, @kc_account, authed.access_token)
        authed

      {:error, reason} ->
        IO.puts(:stderr, "Login failed: #{reason}")
        System.halt(1)
    end
  end

  defp ensure_console_cert(authed, fresh?) do
    if fresh? or not File.exists?(cert_file()) do
      valid_days = authed.expires_in |> div(86_400) |> max(1) |> min(14)
      :ok = generate_cert(valid_days)
      hash = local_cert_hash()

      case UroClient.register_cert(authed, hash) do
        :ok -> IO.puts("Console cert registered with uro (#{hash})")
        {:error, r} -> IO.puts("Warning: cert registration failed: #{r}")
      end
    end

    port = System.get_env("CONSOLE_PORT", "4433") |> String.to_integer()

    {:ok, _} =
      Wtransport.Supervisor.start_link(
        host: "0.0.0.0",
        port: port,
        certfile: cert_file(),
        keyfile: key_file(),
        connection_handler: ZoneConsole.ConsoleConnectionHandler,
        stream_handler: ZoneConsole.ConsoleStreamHandler
      )

    IO.puts("Console WebTransport server on port #{port}")
  end

  defp generate_cert(valid_days) do
    File.mkdir_p!(cert_dir())

    case System.cmd(
           "openssl",
           [
             "req",
             "-x509",
             "-newkey",
             "ec",
             "-pkeyopt",
             "ec_paramgen_curve:P-256",
             "-keyout",
             key_file(),
             "-out",
             cert_file(),
             "-days",
             to_string(valid_days),
             "-nodes",
             "-subj",
             "/CN=zone_console"
           ],
           stderr_to_stdout: true
         ) do
      {_, 0} -> :ok
      {out, code} -> {:error, "openssl exited #{code}: #{out}"}
    end
  end

  defp local_cert_hash do
    [{:Certificate, der, _}] = cert_file() |> File.read!() |> :public_key.pem_decode()
    :crypto.hash(:sha256, der) |> Base.encode16(case: :lower)
  end

  defp cert_dir, do: Path.join([System.user_home!(), ".config", "zone_console"])
  defp cert_file, do: Path.join(cert_dir(), "console.crt")
  defp key_file, do: Path.join(cert_dir(), "console.key")

  defp load_dotenv do
    path = Path.join([File.cwd!(), ".env"])

    if File.exists?(path) do
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.each(fn line ->
        case String.split(line, "=", parts: 2) do
          [key, value] -> System.put_env(String.trim(key), String.trim(value))
          _ -> :ok
        end
      end)
    end
  end
end
