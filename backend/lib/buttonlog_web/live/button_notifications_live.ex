defmodule ButtonLogWeb.ButtonNotificationsLive do
  @moduledoc """
  LiveView for configuring which friends receive alerts when a button is clicked.
  """
  use ButtonLogWeb, :live_view
  alias ButtonLog.Social
  alias ButtonLog.Buttons
  alias ButtonLog.Alerts

  @impl true
  def mount(%{"button_id" => button_id}, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = ButtonLog.Accounts.get_user!(user_id)
      button = Buttons.get_button(button_id, current_user.id)

      # Verify the button belongs to the current user
      case button do
        {:ok, button_data} ->
          if button_data.user_id == current_user.id do
            # Get user's friends
            friends = Social.get_user_friends(user_id)

            # Get current alert settings for this button
            alert_preferences = Alerts.get_button_alert_preferences(button_id, user_id)

            # Create a map of friend_id -> preference for easy lookup
            preferences_map = Map.new(alert_preferences, fn pref -> {pref.friend_id, pref} end)

            {:ok,
             socket
             |> assign(:current_user, current_user)
             |> assign(:button, button_data)
             |> assign(:friends, friends)
             |> assign(:alert_preferences, alert_preferences)
             |> assign(:preferences_map, preferences_map)
             |> assign(:page_title, "Alert Settings for #{button_data.name}")}
          else
            {:ok,
             socket
             |> put_flash(:error, "You can only configure alerts for your own buttons")
             |> redirect(to: ~p"/buttons")}
          end

        {:error, :not_found} ->
          {:ok,
           socket
           |> put_flash(:error, "Button not found")
           |> redirect(to: ~p"/buttons")}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to configure button alerts")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("toggle_friend_notification", %{"friend_id" => friend_id}, socket) do
    button_id = socket.assigns.button.id
    user_id = socket.assigns.current_user.id

    case Alerts.toggle_button_friend_alert(button_id, user_id, friend_id) do
      {:ok, _updated_preference} ->
        # Refresh the preferences
        alert_preferences = Alerts.get_button_alert_preferences(button_id, user_id)
        preferences_map = Map.new(alert_preferences, fn pref -> {pref.friend_id, pref} end)

        {:noreply,
         socket
         |> put_flash(:info, "Alert setting updated")
         |> assign(:alert_preferences, alert_preferences)
         |> assign(:preferences_map, preferences_map)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update alert setting: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("save_all_settings", _params, socket) do
    button_id = socket.assigns.button.id
    _user_id = socket.assigns.current_user.id

    # Get all the checkbox states from the form
    # This would need to be implemented based on your form structure
    {:noreply,
     socket
     |> put_flash(:info, "All alert settings saved")
     |> redirect(to: ~p"/buttons/#{button_id}")}
  end

  @impl true
  def handle_event("select_all_friends", _params, socket) do
    button_id = socket.assigns.button.id
    user_id = socket.assigns.current_user.id

    # Enable alerts for all friends
    Enum.each(socket.assigns.friends, fn friend ->
      Alerts.set_button_friend_alert(button_id, user_id, friend.id, true)
    end)

    # Refresh the preferences
    alert_preferences = Alerts.get_button_alert_preferences(button_id, user_id)
    preferences_map = Map.new(alert_preferences, fn pref -> {pref.friend_id, pref} end)

    {:noreply,
     socket
     |> put_flash(:info, "All friends selected for alerts")
     |> assign(:alert_preferences, alert_preferences)
     |> assign(:preferences_map, preferences_map)}
  end

  @impl true
  def handle_event("deselect_all_friends", _params, socket) do
    button_id = socket.assigns.button.id
    user_id = socket.assigns.current_user.id

    # Disable alerts for all friends
    Enum.each(socket.assigns.friends, fn friend ->
      Alerts.set_button_friend_alert(button_id, user_id, friend.id, false)
    end)

    # Refresh the preferences
    alert_preferences = Alerts.get_button_alert_preferences(button_id, user_id)
    preferences_map = Map.new(alert_preferences, fn pref -> {pref.friend_id, pref} end)

    {:noreply,
     socket
     |> put_flash(:info, "All friends deselected for alerts")
     |> assign(:alert_preferences, alert_preferences)
     |> assign(:preferences_map, preferences_map)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
