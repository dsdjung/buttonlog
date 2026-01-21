defmodule ButtonLogWeb.API.AuthController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Accounts
  alias ButtonLog.Auth.Token

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        token = Token.create_token(user.id)
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            user: serialize_user(user),
            token: token
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid registration data",
            details: format_changeset_errors(changeset)
          }
        })
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = Token.create_token(user.id)
        conn
        |> json(%{
          success: true,
          data: %{
            user: serialize_user(user),
            token: token
          }
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          success: false,
          error: %{
            code: "INVALID_CREDENTIALS",
            message: "Invalid email or password"
          }
        })
    end
  end

  def refresh(conn, _params) do
    case get_auth_token(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})

      token ->
        case Token.verify_token(token) do
          {:ok, user_id} ->
            user = Accounts.get_user!(user_id)
            new_token = Token.create_token(user.id)
            conn
            |> json(%{
              success: true,
              data: %{token: new_token}
            })

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token"})
        end
    end
  end

  defp get_auth_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      %{field: field, message: List.first(errors)}
    end)
  end

  defp serialize_user(user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      display_name: user.display_name,
      first_name: nil,
      last_name: nil,
      profile_visibility: user.profile_visibility || "friends",
      activity_visibility: user.activity_visibility || "friends",
      subscription_tier: user.subscription_tier || "free",
      is_active: true,
      email_verified: user.email_verified || false,
      created_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end


