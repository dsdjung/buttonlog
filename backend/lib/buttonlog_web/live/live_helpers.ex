defmodule ButtonLogWeb.LiveHelpers do
  @moduledoc """
  Helper functions for LiveView authentication and common operations.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias ButtonLog.Accounts

  @doc """
  Safely gets the current user from session, redirecting to login if not found.

  Returns {:ok, user, socket} if user found, or {:redirect, socket} if not.

  ## Example

      case get_current_user(session, socket) do
        {:ok, user, socket} ->
          {:ok, assign(socket, :current_user, user)}
        {:redirect, socket} ->
          {:ok, socket}
      end
  """
  def get_current_user(session, socket, opts \\ []) do
    user_id = session["user_id"]
    redirect_path = Keyword.get(opts, :redirect_to, "/auth/login")
    error_message = Keyword.get(opts, :error_message, "Please log in to continue")

    case user_id && Accounts.get_user(user_id) do
      nil ->
        {:redirect,
         socket
         |> put_flash(:error, error_message)
         |> redirect(to: redirect_path)}

      user ->
        {:ok, user, socket}
    end
  end

  @doc """
  Requires authentication for a LiveView mount.
  If user not found, redirects to login.

  ## Example

      def mount(_params, session, socket) do
        with {:ok, user, socket} <- require_authenticated_user(session, socket) do
          {:ok, assign(socket, :current_user, user)}
        end
      end
  """
  def require_authenticated_user(session, socket, opts \\ []) do
    case get_current_user(session, socket, opts) do
      {:ok, user, socket} -> {:ok, user, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end
end
