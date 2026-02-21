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
        first_name: user.first_name,
        last_name: user.last_name,
        avatar: user.avatar,
        timezone: user.timezone,
        language: user.language,
        profile_visibility: user.profile_visibility,
        activity_visibility: user.activity_visibility,
        subscription_tier: user.subscription_tier,
        subscription_expires_at: user.subscription_expires_at
      }
    })
  end

  def update_profile(conn, %{"user" => user_params}) do
    do_update_profile(conn, user_params)
  end

  # Fallback for mobile apps that send params directly without "user" wrapper
  def update_profile(conn, params) do
    do_update_profile(conn, params)
  end

  defp do_update_profile(conn, user_params) do
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, updated_user} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: updated_user.id,
            email: updated_user.email,
            username: updated_user.username,
            display_name: updated_user.display_name,
            first_name: updated_user.first_name,
            last_name: updated_user.last_name,
            avatar: updated_user.avatar,
            timezone: updated_user.timezone,
            language: updated_user.language,
            profile_visibility: updated_user.profile_visibility,
            activity_visibility: updated_user.activity_visibility
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

  def complete_onboarding(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.update_user(user, %{onboarding_completed: true}) do
      {:ok, _updated_user} ->
        conn
        |> json(%{
          success: true,
          data: %{
            onboarding_completed: true
          }
        })

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "UPDATE_FAILED",
            message: "Failed to update onboarding status"
          }
        })
    end
  end

  def notification_preferences(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> json(%{
      success: true,
      data: %{
        push_notifications_enabled: user.push_notifications_enabled,
        email_notifications_enabled: user.email_notifications_enabled,
        button_notifications: user.button_notifications,
        friend_notifications: user.friend_notifications,
        system_notifications: user.system_notifications,
        quiet_hours_enabled: user.quiet_hours_enabled,
        quiet_hours_start: format_time(user.quiet_hours_start),
        quiet_hours_end: format_time(user.quiet_hours_end)
      }
    })
  end

  def update_notification_preferences(conn, params) do
    user = conn.assigns.current_user

    attrs = %{
      push_notifications_enabled: Map.get(params, "push_notifications_enabled"),
      email_notifications_enabled: Map.get(params, "email_notifications_enabled"),
      button_notifications: Map.get(params, "button_notifications"),
      friend_notifications: Map.get(params, "friend_notifications"),
      system_notifications: Map.get(params, "system_notifications"),
      quiet_hours_enabled: Map.get(params, "quiet_hours_enabled"),
      quiet_hours_start: parse_time(Map.get(params, "quiet_hours_start")),
      quiet_hours_end: parse_time(Map.get(params, "quiet_hours_end"))
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    case Accounts.update_notification_preferences(user, attrs) do
      {:ok, updated_user} ->
        conn
        |> json(%{
          success: true,
          data: %{
            push_notifications_enabled: updated_user.push_notifications_enabled,
            email_notifications_enabled: updated_user.email_notifications_enabled,
            button_notifications: updated_user.button_notifications,
            friend_notifications: updated_user.friend_notifications,
            system_notifications: updated_user.system_notifications,
            quiet_hours_enabled: updated_user.quiet_hours_enabled,
            quiet_hours_start: format_time(updated_user.quiet_hours_start),
            quiet_hours_end: format_time(updated_user.quiet_hours_end)
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Failed to update notification preferences",
            details: format_changeset_errors(changeset)
          }
        })
    end
  end

  defp format_time(nil), do: nil
  defp format_time(time), do: Time.to_string(time)

  defp parse_time(nil), do: nil
  defp parse_time(""), do: nil
  defp parse_time(time_str) when is_binary(time_str) do
    case Time.from_iso8601(time_str) do
      {:ok, time} -> time
      _ -> nil
    end
  end
  defp parse_time(_), do: nil

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

  @doc """
  Gets the user's invite link. Creates one if it doesn't exist.
  """
  def invite_link(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.get_or_create_invite_code(user.id) do
      {:ok, code} ->
        # Build the invite URL - use app deep link
        base_url = Application.get_env(:buttonlog, :app_deep_link_base) || "buttonlog://invite"
        invite_url = "#{base_url}/#{code}"

        conn
        |> json(%{
          success: true,
          data: %{
            invite_code: code,
            invite_url: invite_url,
            share_message: "Join me on ButtonLog! #{invite_url}"
          }
        })

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: %{
            code: "INVITE_CODE_ERROR",
            message: "Failed to generate invite code"
          }
        })
    end
  end

  @doc """
  Regenerates the user's invite link, invalidating the previous one.
  """
  def regenerate_invite_link(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.regenerate_invite_code(user.id) do
      {:ok, code} ->
        base_url = Application.get_env(:buttonlog, :app_deep_link_base) || "buttonlog://invite"
        invite_url = "#{base_url}/#{code}"

        conn
        |> json(%{
          success: true,
          data: %{
            invite_code: code,
            invite_url: invite_url,
            share_message: "Join me on ButtonLog! #{invite_url}"
          }
        })

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: %{
            code: "INVITE_CODE_ERROR",
            message: "Failed to regenerate invite code"
          }
        })
    end
  end
end


