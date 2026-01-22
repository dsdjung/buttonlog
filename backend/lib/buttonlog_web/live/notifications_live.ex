defmodule ButtonLogWeb.NotificationsLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Notifications

  @page_size 20

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = ButtonLog.Accounts.get_user!(user_id)

      # Get initial page of notifications
      {notifications, has_more} = Notifications.get_user_notifications_paginated(user_id, @page_size, 0)

      # Get unread count efficiently
      unread_count = Notifications.count_unread_notifications(user_id)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:notifications, notifications)
       |> assign(:unread_count, unread_count)
       |> assign(:has_more, has_more)
       |> assign(:loading_more, false)
       |> assign(:page_title, "Notifications")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to view notifications")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    user_id = socket.assigns.current_user.id
    current_count = length(socket.assigns.notifications)

    {more_notifications, has_more} = Notifications.get_user_notifications_paginated(user_id, @page_size, current_count)

    {:noreply,
     socket
     |> assign(:notifications, socket.assigns.notifications ++ more_notifications)
     |> assign(:has_more, has_more)
     |> assign(:loading_more, false)}
  end

  @impl true
  def handle_event("mark_read", %{"id" => notification_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Notifications.mark_notification_read(notification_id, user_id) do
      {:ok, updated_notification} ->
        # Update the notification in the list without reloading all
        notifications = Enum.map(socket.assigns.notifications, fn n ->
          if n.id == updated_notification.id, do: updated_notification, else: n
        end)

        unread_count = max(0, socket.assigns.unread_count - 1)

        {:noreply,
         socket
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
        # Update all notifications in the list to be read
        notifications = Enum.map(socket.assigns.notifications, fn n ->
          %{n | read: true}
        end)

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
