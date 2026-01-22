defmodule ButtonLogWeb.Plugs.BrowserAuthPlug do
  @moduledoc """
  Plug for browser-based authentication using session.
  Redirects to login page if not authenticated.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias ButtonLog.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      case Accounts.get_user(user_id) do
        nil ->
          conn
          |> clear_session()
          |> put_flash(:error, "Session expired. Please log in again.")
          |> redirect(to: "/auth/login")
          |> halt()

        user ->
          assign(conn, :current_user, user)
      end
    else
      conn
      |> put_flash(:error, "Please log in to access this page.")
      |> redirect(to: "/auth/login")
      |> halt()
    end
  end
end
