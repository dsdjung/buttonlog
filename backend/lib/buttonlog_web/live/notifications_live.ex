defmodule ButtonLogWeb.NotificationsLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Notifications

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = ButtonLog.Accounts.get_user!(user_id)

      # Get user's notifications
      notifications = Notifications.get_user_notifications(user_id, 100)

      # Get unread count
      unread_count = length(Notifications.get_unread_notifications(user_id))

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:notifications, notifications)
       |> assign(:unread_count, unread_count)
       |> assign(:page_title, "Notifications")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to view notifications")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("mark_read", %{"id" => notification_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Notifications.mark_notification_read(notification_id, user_id) do
      {:ok, _updated_notification} ->
        # Refresh notifications and unread count
        notifications = Notifications.get_user_notifications(user_id, 100)
        unread_count = length(Notifications.get_unread_notifications(user_id))

        {:noreply,
         socket
         |> put_flash(:info, "Notification marked as read")
         |> assign(:notifications, notifications)
         |> assign(:unread_count, unread_count)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to mark notification as read")}
    end
  end

  @impl true
  def handle_event("mark_all_read", _params, socket) do
    user_id = socket.assigns.current_user.id

    case Notifications.mark_all_notifications_read(user_id) do
      {:ok, count} ->
        # Refresh notifications and unread count
        notifications = Notifications.get_user_notifications(user_id, 100)

        {:noreply,
         socket
         |> put_flash(:info, "Marked #{count} notifications as read")
         |> assign(:notifications, notifications)
         |> assign(:unread_count, 0)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # Helper function for safe datetime formatting
  defp safe_to_iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp safe_to_iso8601(%NaiveDateTime{} = naive_datetime) do
    DateTime.from_naive!(naive_datetime, "Etc/UTC") |> DateTime.to_iso8601()
  end
  defp safe_to_iso8601(nil), do: ""
end
