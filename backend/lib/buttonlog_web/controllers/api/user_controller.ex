defmodule ButtonLogWeb.API.UserController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Accounts

  def profile(conn, _params) do
    user = conn.assigns.current_user
    conn
    |> json(%{
      success: true,
      data: %{
        id: user.id,
        email: user.email,
        username: user.username,
        display_name: user.display_name,
        avatar: user.avatar,
        timezone: user.timezone,
        language: user.language,
        subscription_tier: user.subscription_tier,
        subscription_expires_at: user.subscription_expires_at
      }
    })
  end

  def update_profile(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user(user, user_params) do
      {:ok, updated_user} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: updated_user.id,
            email: updated_user.email,
            username: updated_user.username,
            display_name: updated_user.display_name,
            avatar: updated_user.avatar,
            timezone: updated_user.timezone,
            language: updated_user.language
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid profile data",
            details: format_changeset_errors(changeset)
          }
        })
    end
  end

  def public_profile(conn, %{"id" => user_id}) do
    case Accounts.get_user(user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "USER_NOT_FOUND",
            message: "User not found"
          }
        })

      user ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: user.id,
            username: user.username,
            display_name: user.display_name,
            avatar: user.avatar
          }
        })
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
end


