defmodule ButtonLogWeb.API.PasswordController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Accounts

  def change_password(conn, %{"current_password" => current_password, "new_password" => new_password, "confirm_password" => confirm_password}) do
    user = conn.assigns.current_user

    cond do
      new_password != confirm_password ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "PASSWORD_MISMATCH",
            message: "New password and confirmation do not match"
          }
        })

      String.length(new_password) < 8 ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "PASSWORD_TOO_SHORT",
            message: "Password must be at least 8 characters"
          }
        })

      !verify_current_password(user, current_password) ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          success: false,
          error: %{
            code: "INVALID_CURRENT_PASSWORD",
            message: "Current password is incorrect"
          }
        })

      true ->
        case Accounts.change_user_password(user, new_password) do
          {:ok, _updated_user} ->
            conn
            |> json(%{
              success: true,
              data: %{
                message: "Password changed successfully"
              }
            })

          {:error, _changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              success: false,
              error: %{
                code: "PASSWORD_CHANGE_FAILED",
                message: "Failed to change password"
              }
            })
        end
    end
  end

  def change_password(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: %{
        code: "MISSING_PARAMETERS",
        message: "current_password, new_password, and confirm_password are required"
      }
    })
  end

  defp verify_current_password(user, password) do
    case user.password_hash do
      nil -> false
      hash -> Bcrypt.verify_pass(password, hash)
    end
  end
end
