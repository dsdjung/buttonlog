defmodule ButtonLogWeb.Plugs.ClientVersionPlug do
  @moduledoc """
  Extracts client version information from request headers.

  Mobile apps should send:
  - X-App-Version: The app version (e.g., "1.2.0")
  - X-Platform: The platform name ("ios" or "android")
  - X-Device-Id: Optional unique device identifier

  This plug extracts these headers and makes them available in conn.assigns
  for logging, analytics, and version-based feature gating.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    app_version = get_header(conn, "x-app-version")
    platform = get_header(conn, "x-platform")
    device_id = get_header(conn, "x-device-id")

    conn
    |> assign(:client_version, app_version)
    |> assign(:client_platform, platform)
    |> assign(:client_device_id, device_id)
  end

  defp get_header(conn, header) do
    case get_req_header(conn, header) do
      [value | _] -> value
      [] -> nil
    end
  end
end
