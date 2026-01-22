defmodule ButtonLogWeb.NotificationsLive do
  @moduledoc """
  LiveView for viewing user alerts (formerly notifications).
  This page shows in-app friend alerts for button clicks, etc.
  """

  use ButtonLogWeb, :live_view
  alias ButtonLog.Alerts

  @page_size 20

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = ButtonLog.Accounts.get_user!(user_id)

      # Get initial page of alerts
      {alerts, has_more} = Alerts.get_user_alerts_paginated(user_id, @page_size, 0)

      # Get unread count efficiently
      unread_count = Alerts.count_unread_alerts(user_id)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:alerts, alerts)
       |> assign(:unread_count, unread_count)
       |> assign(:has_more, has_more)
       |> assign(:loading_more, false)
       |> assign(:page_title, "Alerts")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to view alerts")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    user_id = socket.assigns.current_user.id
    current_count = length(socket.assigns.alerts)

    {more_alerts, has_more} = Alerts.get_user_alerts_paginated(user_id, @page_size, current_count)

    {:noreply,
     socket
     |> assign(:alerts, socket.assigns.alerts ++ more_alerts)
     |> assign(:has_more, has_more)
     |> assign(:loading_more, false)}
  end

  @impl true
  def handle_event("mark_read", %{"id" => alert_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Alerts.mark_alert_read(alert_id, user_id) do
      {:ok, updated_alert} ->
        # Update the alert in the list without reloading all
        alerts = Enum.map(socket.assigns.alerts, fn a ->
          if a.id == updated_alert.id, do: updated_alert, else: a
        end)

        unread_count = max(0, socket.assigns.unread_count - 1)

        {:noreply,
         socket
         |> assign(:alerts, alerts)
         |> assign(:unread_count, unread_count)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to mark alert as read")}
    end
  end

  @impl true
  def handle_event("mark_all_read", _params, socket) do
    user_id = socket.assigns.current_user.id

    case Alerts.mark_all_alerts_read(user_id) do
      {:ok, count} ->
        # Update all alerts in the list to be read
        alerts = Enum.map(socket.assigns.alerts, fn a ->
          %{a | read: true}
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Marked #{count} alerts as read")
         |> assign(:alerts, alerts)
         |> assign(:unread_count, 0)}
    end
  end

  @impl true
  def handle_event("click_alert", %{"id" => alert_id}, socket) do
    user_id = socket.assigns.current_user.id

    # Find the alert
    alert = Enum.find(socket.assigns.alerts, fn a -> a.id == alert_id end)

    if alert do
      # Mark as read if not already
      unless alert.read do
        Alerts.mark_alert_read(alert_id, user_id)
      end

      # Navigate based on alert type
      path = get_alert_path(alert)

      {:noreply, push_navigate(socket, to: path)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # Helper to determine navigation path based on alert type
  defp get_alert_path(alert) do
    case alert.alert_type do
      "button_click" ->
        if alert.button_id, do: ~p"/buttons/#{alert.button_id}", else: ~p"/buttons"

      "button_created" ->
        if alert.button_id, do: ~p"/buttons/#{alert.button_id}", else: ~p"/buttons"

      "gift_button_received" ->
        if alert.button_id, do: ~p"/buttons/#{alert.button_id}", else: ~p"/buttons"

      "gift_button_clicked" ->
        # Navigate to friend page when clicking on a "gift clicked" alert
        # Use friend_id from metadata, or fall back to sender_id (the friend who clicked)
        friend_id = get_in(alert.metadata, ["friend_id"]) ||
                    alert.metadata[:friend_id] ||
                    alert.sender_id
        if friend_id, do: ~p"/friends/#{friend_id}", else: ~p"/friends"

      "gift_button_deleted" ->
        ~p"/buttons"

      "gift_button_sent" ->
        # Navigate to friend page when clicking on a "gift sent" alert
        friend_id = get_in(alert.metadata, ["friend_id"]) || alert.metadata[:friend_id]
        if friend_id, do: ~p"/friends/#{friend_id}", else: ~p"/friends"

      "one_time_button_completed" ->
        if alert.button_id, do: ~p"/buttons/#{alert.button_id}", else: ~p"/buttons"

      "friend_request" ->
        ~p"/friends"

      "support_ticket_reply" ->
        ticket_id = get_in(alert.metadata, ["ticket_id"]) || alert.metadata[:ticket_id]
        if ticket_id, do: ~p"/support/#{ticket_id}", else: ~p"/support"

      "support_ticket_status_update" ->
        ticket_id = get_in(alert.metadata, ["ticket_id"]) || alert.metadata[:ticket_id]
        if ticket_id, do: ~p"/support/#{ticket_id}", else: ~p"/support"

      _ ->
        ~p"/notifications"
    end
  end

  # Helper function for safe datetime formatting
  defp safe_to_iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp safe_to_iso8601(%NaiveDateTime{} = naive_datetime) do
    DateTime.from_naive!(naive_datetime, "Etc/UTC") |> DateTime.to_iso8601()
  end
  defp safe_to_iso8601(nil), do: ""
end
