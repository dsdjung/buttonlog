defmodule ButtonLogWeb.FriendLive.Show do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Social
  alias ButtonLog.Buttons

  @impl true
  def mount(%{"id" => friend_id}, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = ButtonLog.Accounts.get_user!(user_id)
      friend = ButtonLog.Accounts.get_user!(friend_id)

      # Check if they are actually friends
      case Social.are_friends?(user_id, friend_id) do
        true ->
          # Get friendship details for removal
          friendship = Social.get_friendship_between_users(user_id, friend_id)

          # Get shared activity (buttons, notifications, etc.)
          shared_buttons = Social.get_shared_buttons(user_id, friend_id)
          shared_notifications = Social.get_shared_notifications(user_id, friend_id)

          # Get buttons I created for this friend
          gift_buttons = Buttons.list_gift_buttons_for_friend(user_id, friend_id)

          # Get friend activity (requires can_view_history permission)
          {friend_activity, can_view_history} =
            case Social.get_friend_activity(user_id, friend_id, 20) do
              {:error, :permission_denied} -> {[], false}
              {activities, _next_cursor, _has_more} -> {activities, true}
            end

          # Get permissions I've set for this friend (what they can see of my stuff)
          my_permissions = Social.get_friend_permissions(user_id, friend_id) || %{
            can_view_history: true,
            can_receive_alerts: true,
            can_view_buttons: true
          }

          {:ok,
           socket
           |> assign(:current_user, current_user)
           |> assign(:friend, friend)
           |> assign(:friendship, friendship)
           |> assign(:shared_buttons, shared_buttons)
           |> assign(:shared_notifications, shared_notifications)
           |> assign(:gift_buttons, gift_buttons)
           |> assign(:friend_activity, friend_activity)
           |> assign(:can_view_history, can_view_history)
           |> assign(:show_gift_button_form, false)
           |> assign(:gift_button_name, "")
           |> assign(:gift_button_type, "one-time")
           |> assign(:gift_button_icon, "star")
           |> assign(:gift_button_color, "#00BFA5")
           |> assign(:gift_button_message, "")
           |> assign(:gift_button_choices, ["", ""])
           |> assign(:my_permissions, my_permissions)
           |> assign(:show_permissions_form, false)
           |> assign(:page_title, "#{friend.display_name}'s Profile")}

        false ->
          {:ok,
           socket
           |> put_flash(:error, "You can only view profiles of your friends")
           |> redirect(to: ~p"/friends")}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to view friend profiles")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("remove_friend", _params, socket) do
    user_id = socket.assigns.current_user.id
    _friend_id = socket.assigns.friend.id

    case Social.remove_friend(socket.assigns.friendship.id, user_id) do
      {:ok, :deleted} ->
        {:noreply,
         socket
         |> put_flash(:info, "Friend removed successfully")
         |> redirect(to: ~p"/friends")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to remove friend: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("show_gift_button_form", _params, socket) do
    {:noreply, socket |> assign(:show_gift_button_form, true)}
  end

  @impl true
  def handle_event("hide_gift_button_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_gift_button_form, false)
     |> assign(:gift_button_name, "")
     |> assign(:gift_button_type, "one-time")
     |> assign(:gift_button_icon, "star")
     |> assign(:gift_button_color, "#00BFA5")
     |> assign(:gift_button_message, "")
     |> assign(:gift_button_choices, ["", ""])}
  end

  @impl true
  def handle_event("select_button_type", %{"type" => type}, socket) do
    # Reset choices when switching away from one-time type
    socket = if type != "one-time" do
      socket |> assign(:gift_button_choices, ["", ""])
    else
      socket
    end
    {:noreply, socket |> assign(:gift_button_type, type)}
  end

  @impl true
  def handle_event("update_gift_choice", %{"index" => index_str, "value" => value}, socket) do
    index = String.to_integer(index_str)
    choices = socket.assigns.gift_button_choices || ["", ""]
    updated_choices = List.replace_at(choices, index, value || "")
    {:noreply, socket |> assign(:gift_button_choices, updated_choices)}
  end

  @impl true
  def handle_event("add_gift_choice", _params, socket) do
    choices = socket.assigns.gift_button_choices || ["", ""]
    {:noreply, socket |> assign(:gift_button_choices, choices ++ [""])}
  end

  @impl true
  def handle_event("remove_gift_choice", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    choices = socket.assigns.gift_button_choices || ["", ""]
    updated_choices = List.delete_at(choices, index)
    {:noreply, socket |> assign(:gift_button_choices, updated_choices)}
  end

  @impl true
  def handle_event("update_gift_button_field", params, socket) do
    field = params["field"]
    value = params["value"]

    case field do
      "name" -> {:noreply, socket |> assign(:gift_button_name, value || "")}
      "type" -> {:noreply, socket |> assign(:gift_button_type, value || "instant")}
      "icon" -> {:noreply, socket |> assign(:gift_button_icon, value || "star")}
      "color" -> {:noreply, socket |> assign(:gift_button_color, value || "#00BFA5")}
      "message" -> {:noreply, socket |> assign(:gift_button_message, value || "")}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_gift_button", _params, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = socket.assigns.friend.id

    # Get choices from socket assigns (now managed by LiveView, not Alpine.js)
    raw_choices = socket.assigns.gift_button_choices || ["", ""]

    # Filter out empty choices and only include if we have at least 2
    choices = raw_choices
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))

    # Only include choices for one-time buttons with at least 2 valid choices
    choices_for_button = if socket.assigns.gift_button_type == "one-time" && length(choices) >= 2 do
      choices
    else
      nil
    end

    button_attrs = %{
      "name" => socket.assigns.gift_button_name,
      "type" => socket.assigns.gift_button_type,
      "icon" => socket.assigns.gift_button_icon,
      "color" => socket.assigns.gift_button_color,
      "choices" => choices_for_button
    }

    message = case socket.assigns.gift_button_message do
      "" -> nil
      msg -> msg
    end

    case Buttons.create_button_for_friend(button_attrs, friend_id, user_id, message) do
      {:ok, button} ->
        # Reload the gift buttons list
        gift_buttons = Buttons.list_gift_buttons_for_friend(user_id, friend_id)

        {:noreply,
         socket
         |> put_flash(:info, "Button '#{button.name}' created for #{socket.assigns.friend.display_name}!")
         |> assign(:gift_buttons, gift_buttons)
         |> assign(:show_gift_button_form, false)
         |> assign(:gift_button_name, "")
         |> assign(:gift_button_type, "one-time")
         |> assign(:gift_button_icon, "star")
         |> assign(:gift_button_color, "#00BFA5")
         |> assign(:gift_button_message, "")
         |> assign(:gift_button_choices, ["", ""])}

      {:error, :not_friends} ->
        {:noreply, socket |> put_flash(:error, "You can only create buttons for friends")}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {msg, _opts}} -> "#{field} #{msg}" end)
        {:noreply, socket |> put_flash(:error, "Failed to create button: #{Enum.join(errors, ", ")}")}
    end
  end

  @impl true
  def handle_event("show_permissions_form", _params, socket) do
    {:noreply, socket |> assign(:show_permissions_form, true)}
  end

  @impl true
  def handle_event("hide_permissions_form", _params, socket) do
    {:noreply, socket |> assign(:show_permissions_form, false)}
  end

  @impl true
  def handle_event("toggle_permission", %{"permission" => permission}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = socket.assigns.friend.id

    # Get current permission value
    current_permissions = socket.assigns.my_permissions
    current_value = get_permission_value(current_permissions, permission)
    new_value = !current_value

    # Prepare the attrs map with the toggled permission
    attrs = %{permission => new_value}

    case Social.update_friend_permissions(user_id, friend_id, attrs) do
      {:ok, updated_permissions} ->
        {:noreply,
         socket
         |> assign(:my_permissions, updated_permissions)
         |> put_flash(:info, "Permission updated")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to update permission")}
    end
  end

  # Public helper function for templates
  def get_permission_value(permissions, "can_view_history") do
    case permissions do
      %{can_view_history: value} -> value
      %ButtonLog.Social.FriendPermission{can_view_history: value} -> value
      _ -> true
    end
  end

  def get_permission_value(permissions, "can_receive_alerts") do
    case permissions do
      %{can_receive_alerts: value} -> value
      %ButtonLog.Social.FriendPermission{can_receive_alerts: value} -> value
      _ -> true
    end
  end

  def get_permission_value(permissions, "can_view_buttons") do
    case permissions do
      %{can_view_buttons: value} -> value
      %ButtonLog.Social.FriendPermission{can_view_buttons: value} -> value
      _ -> true
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
