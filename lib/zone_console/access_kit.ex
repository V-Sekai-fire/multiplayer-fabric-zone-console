defmodule ZoneConsole.AccessKit do
  @moduledoc """
  Platform accessibility tree inspection for testing.

  Dispatches to platform-specific implementations via the native accessibility
  APIs: NSAccessibility (macOS), AT-SPI2 (Linux), UI Automation (Windows).

  Each implementation returns `{:ok, %{nodes: [%{label: ..., accessible: ...}]}}`.
  The stub below returns an empty node list until native implementations are wired.
  """

  @spec get_tree(:macos | :linux | :windows) :: {:ok, map()} | {:error, term()}
  def get_tree(platform) do
    case platform do
      :macos   -> get_tree_impl(:macos)
      :linux   -> get_tree_impl(:linux)
      :windows -> get_tree_impl(:windows)
      other    -> {:error, {:unsupported_platform, other}}
    end
  end

  # Platform implementations call native accessibility APIs via Port or NIF.
  # Stubbed with empty node lists until each platform is wired.
  defp get_tree_impl(_platform), do: {:ok, %{nodes: []}}
end
