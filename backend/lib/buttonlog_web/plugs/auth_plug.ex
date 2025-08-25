defmodule ButtonLogWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_auth_token(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()

      token ->
        case verify_token(token) do
          {:ok, user_id} ->
            user = ButtonLog.Accounts.get_user!(user_id)
            assign(conn, :current_user, user)

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token"})
            |> halt()
        end
    end
  end

  defp get_auth_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp verify_token(token) do
    ButtonLog.Auth.Token.verify_token(token)
  end
end
