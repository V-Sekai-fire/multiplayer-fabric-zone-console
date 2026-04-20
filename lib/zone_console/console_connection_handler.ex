defmodule ZoneConsole.ConsoleConnectionHandler do
  use Wtransport.ConnectionHandler

  @impl Wtransport.ConnectionHandler
  def handle_session(_session) do
    uro = Application.fetch_env!(:zone_console, :uro_client)
    {:continue, %{uro: uro, zone_client: nil}}
  end
end
