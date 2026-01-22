defmodule ButtonLogWeb.Plugs.AdminPlug do
  @moduledoc """
  Plug to verify that the current user is an admin.
  Must be used after AuthPlug or BrowserAuthPlug.
  Handles both API (JSON) and browser (HTML) responses.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %{is_admin: true} ->
        conn

      %{is_admin: false} ->
        handle_forbidden(conn)

      nil ->
        handle_unauthorized(conn)
    end
  end

  defp handle_forbidden(conn) do
    if is_api_request?(conn) do
      conn
      |> put_status(:forbidden)
      |> json(%{
        success: false,
        error: %{
          code: "FORBIDDEN",
          message: "Admin access required"
        }
      })
      |> halt()
    else
      conn
      |> put_flash(:error, "Admin access required")
      |> redirect(to: "/")
      |> halt()
    end
  end

  defp handle_unauthorized(conn) do
    if is_api_request?(conn) do
      conn
      |> put_status(:unauthorized)
      |> json(%{
        success: false,
        error: %{
          code: "UNAUTHORIZED",
          message: "Authentication required"
        }
      })
      |> halt()
    else
      conn
      |> put_flash(:error, "Please log in to access this page.")
      |> redirect(to: "/auth/login")
      |> halt()
    end
  end

  defp is_api_request?(conn) do
    # Check if this is an API request by looking at the path or accept header
    String.starts_with?(conn.request_path, "/api") ||
      Enum.any?(get_req_header(conn, "accept"), &String.contains?(&1, "application/json"))
  end
end
