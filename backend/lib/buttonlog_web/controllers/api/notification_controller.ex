defmodule ButtonLogWeb.API.NotificationController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Notifications

  def index(conn, _params) do
    user = conn.assigns.current_user
    notifications = Notifications.get_user_notifications(user.id)

    conn
    |> json(%{
      success: true,
      data: Enum.map(notifications, fn notification ->
        %{
          id: notification.id,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          is_read: notification.is_read,
          data: notification.data,
          sender: if(notification.sender, do: %{
            id: notification.sender.id,
            username: notification.sender.username,
            display_name: notification.sender.display_name
          }, else: nil),
          inserted_at: notification.inserted_at
        }
      end)
    })
  end

  def mark_read(conn, %{"id" => notification_id}) do
    user = conn.assigns.current_user

    case Notifications.mark_notification_read(notification_id, user.id) do
      {:ok, notification} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: notification.id,
            is_read: notification.is_read
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "NOTIFICATION_NOT_FOUND",
            message: "Notification not found"
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "UNAUTHORIZED",
            message: "Not authorized to modify this notification"
          }
        })
    end
  end
end
