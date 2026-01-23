defmodule ButtonLogWeb.API.NotificationController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Notifications
  alias ButtonLog.Alerts

  def index(conn, _params) do
    user = conn.assigns.current_user

    # Get both notifications and alerts, then merge and sort by time
    notifications = Notifications.get_user_notifications(user.id)
    alerts = Alerts.get_user_alerts(user.id)

    # Format notifications
    formatted_notifications = Enum.map(notifications, fn notification ->
      %{
        id: notification.id,
        title: notification.title,
        body: notification.message,
        type: notification.notification_type,
        is_read: notification.read,
        data: notification.metadata,
        sender: if(notification.sender, do: %{
          id: notification.sender.id,
          username: notification.sender.username,
          display_name: notification.sender.display_name
        }, else: nil),
        button: if(notification.button, do: %{
          id: notification.button.id,
          name: notification.button.name
        }, else: nil),
        inserted_at: notification.inserted_at
      }
    end)

    # Format alerts (same structure as notifications for consistency)
    formatted_alerts = Enum.map(alerts, fn alert ->
      %{
        id: alert.id,
        title: alert.title,
        body: alert.message,
        type: alert.alert_type,
        is_read: alert.read,
        data: alert.metadata,
        sender: if(alert.sender, do: %{
          id: alert.sender.id,
          username: alert.sender.username,
          display_name: alert.sender.display_name
        }, else: nil),
        button: if(alert.button, do: %{
          id: alert.button.id,
          name: alert.button.name
        }, else: nil),
        inserted_at: alert.inserted_at
      }
    end)

    # Merge and sort by inserted_at (most recent first)
    all_items = (formatted_notifications ++ formatted_alerts)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> Enum.take(50)

    conn
    |> json(%{
      success: true,
      data: all_items
    })
  end

  def mark_read(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    # Try to mark as notification first, if not found try as alert
    case Notifications.mark_notification_read(id, user.id) do
      {:ok, notification} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: notification.id,
            is_read: notification.read
          }
        })

      {:error, :not_found} ->
        # Try marking as alert instead
        case Alerts.mark_alert_read(id, user.id) do
          {:ok, alert} ->
            conn
            |> json(%{
              success: true,
              data: %{
                id: alert.id,
                is_read: alert.read
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
        end

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
