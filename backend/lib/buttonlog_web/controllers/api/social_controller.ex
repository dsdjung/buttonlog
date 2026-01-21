defmodule ButtonLogWeb.API.SocialController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Social

  def friends(conn, _params) do
    user = conn.assigns.current_user
    friends = Social.get_user_friends(user.id)

    conn
    |> json(%{
      success: true,
      data: Enum.map(friends, fn friend ->
        %{
          id: friend.id,
          username: friend.username,
          display_name: friend.display_name,
          avatar: friend.avatar,
          friendship_status: friend.friendship_status
        }
      end)
    })
  end

  def send_friend_request(conn, %{"friend_id" => friend_id}) do
    user = conn.assigns.current_user

    case Social.send_friend_request(user.id, friend_id) do
      {:ok, friendship} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            id: friendship.id,
            status: friendship.status,
            friend_id: friendship.friend_id
          }
        })

      {:error, :already_friends} ->
        conn
        |> put_status(:conflict)
        |> json(%{
          success: false,
          error: %{
            code: "ALREADY_FRIENDS",
            message: "Friend request already exists"
          }
        })

      {:error, :user_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "USER_NOT_FOUND",
            message: "User not found"
          }
        })
    end
  end

  def accept_friend_request(conn, %{"id" => friendship_id}) do
    user = conn.assigns.current_user

    case Social.accept_friend_request(friendship_id, user.id) do
      {:ok, friendship} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: friendship.id,
            status: friendship.status
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "FRIENDSHIP_NOT_FOUND",
            message: "Friend request not found"
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "UNAUTHORIZED",
            message: "Not authorized to accept this request"
          }
        })
    end
  end

  def remove_friend(conn, %{"id" => friendship_id}) do
    user = conn.assigns.current_user

    case Social.remove_friend(friendship_id, user.id) do
      {:ok, _} ->
        conn
        |> json(%{
          success: true,
          data: %{message: "Friend removed successfully"}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "FRIENDSHIP_NOT_FOUND",
            message: "Friendship not found"
          }
        })
    end
  end

  def get_permissions(conn, %{"friend_id" => friend_id}) do
    user = conn.assigns.current_user

    case Social.get_friend_permissions(user.id, friend_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "PERMISSIONS_NOT_FOUND",
            message: "Permissions not found"
          }
        })

      permissions ->
        conn
        |> json(%{
          success: true,
          data: %{
            can_view_history: permissions.can_view_history,
            can_receive_notifications: permissions.can_receive_notifications,
            can_view_buttons: permissions.can_view_buttons
          }
        })
    end
  end

  def update_permissions(conn, %{"friend_id" => friend_id, "permissions" => permission_params}) do
    user = conn.assigns.current_user

    case Social.update_friend_permissions(user.id, friend_id, permission_params) do
      {:ok, permissions} ->
        conn
        |> json(%{
          success: true,
          data: %{
            can_view_history: permissions.can_view_history,
            can_receive_notifications: permissions.can_receive_notifications,
            can_view_buttons: permissions.can_view_buttons
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid permission data",
            details: format_changeset_errors(changeset)
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


