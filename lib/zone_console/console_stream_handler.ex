defmodule ZoneConsole.ConsoleStreamHandler do
  use Wtransport.StreamHandler

  alias Wtransport.Stream
  alias ZoneConsole.{UroClient, ZoneClient}

  @impl Wtransport.StreamHandler
  def handle_stream(%Stream{stream_type: :bi}, conn_state) do
    {:continue, Map.put(conn_state, :buf, "")}
  end

  def handle_stream(_, _), do: :close

  @impl Wtransport.StreamHandler
  def handle_data(data, %Stream{stream_type: :bi} = stream, state) do
    buf = state.buf <> data
    {lines, rest} = extract_lines(buf)

    new_state =
      Enum.reduce(lines, state, fn line, acc ->
        {resp, new_zc} = run_cmd(acc.uro, acc.zone_client, String.trim(line))
        Stream.send(stream, resp <> "\n")
        %{acc | zone_client: new_zc}
      end)

    {:continue, %{new_state | buf: rest}}
  end

  defp extract_lines(buf) do
    case String.split(buf, "\n") do
      [single] -> {[], single}
      parts -> {Enum.drop(parts, -1), List.last(parts)}
    end
  end

  defp run_cmd(uro, zone_client, "join" <> rest) do
    idx =
      rest
      |> String.trim()
      |> Integer.parse()
      |> then(fn
        {n, ""} -> n
        _ -> 0
      end)

    with {:ok, shards} when shards != [] <- UroClient.list_shards(uro),
         shard when not is_nil(shard) <- Enum.at(shards, idx),
         {:ok, zones} when zones != [] <- UroClient.list_zones(uro, shard["id"]),
         zone when not is_nil(zone) <- Enum.at(zones, 0) do
      if zone_client, do: ZoneClient.stop(zone_client)
      addr = shard["address"] || "127.0.0.1"
      url = "https://#{addr}:#{zone["port"]}/wt"

      case ZoneClient.start_link(url, zone["cert_hash"], 0, self()) do
        {:ok, pid} -> {"ok: joined #{url}", pid}
        {:error, r} -> {"error: join failed: #{r}", zone_client}
      end
    else
      {:ok, []} -> {"error: no shards registered", zone_client}
      nil -> {"error: index out of range", zone_client}
      {:error, r} -> {"error: #{r}", zone_client}
    end
  end

  defp run_cmd(uro, zone_client, "upload " <> path) do
    path = String.trim(path)

    case UroClient.upload_asset(uro, path, Path.basename(path)) do
      {:ok, id} -> {"ok: uploaded #{Path.basename(path)} as #{id}", zone_client}
      {:error, r} -> {"error: #{r}", zone_client}
    end
  end

  defp run_cmd(_uro, zone_client, "instance " <> args) do
    with [id_s, x_s, y_s, z_s] <- String.split(String.trim(args)),
         {id, ""} <- Integer.parse(id_s),
         {x, ""} <- Float.parse(x_s),
         {y, ""} <- Float.parse(y_s),
         {z, ""} <- Float.parse(z_s) do
      if zone_client do
        ZoneClient.send_instance(zone_client, id, x, y, z)
        {"ok: instance #{id} at (#{x},#{y},#{z})", zone_client}
      else
        {"error: not joined to a zone", zone_client}
      end
    else
      _ -> {"error: usage: instance <id> <x> <y> <z>", zone_client}
    end
  end

  defp run_cmd(_uro, zone_client, unknown) do
    {"error: unknown command: #{unknown}", zone_client}
  end
end
