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

          # Get friend activity (requires can_view_history permission)
          {friend_activity, can_view_history} =
            case Social.get_friend_activity(user_id, friend_id, 20) do
              {:error, :permission_denied} -> {[], false}
              {activities, _next_cursor, _has_more} -> {activities, true}
            end

          {:ok,
           socket
           |> assign(:current_user, current_user)
           |> assign(:friend, friend)
           |> assign(:friendship, friendship)
           |> assign(:shared_buttons, shared_buttons)
           |> assign(:shared_notifications, shared_notifications)
           |> assign(:friend_activity, friend_activity)
           |> assign(:can_view_history, can_view_history)
           |> assign(:show_gift_button_form, false)
           |> assign(:gift_button_name, "")
           |> assign(:gift_button_type, "instant")
           |> assign(:gift_button_icon, "star")
           |> assign(:gift_button_color, "#007AFF")
           |> assign(:gift_button_message, "")
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
     |> assign(:gift_button_type, "instant")
     |> assign(:gift_button_icon, "star")
     |> assign(:gift_button_color, "#007AFF")
     |> assign(:gift_button_message, "")}
  end

  @impl true
  def handle_event("update_gift_button_field", %{"field" => field, "value" => value}, socket) do
    field_atom = String.to_existing_atom("gift_button_#{field}")
    {:noreply, socket |> assign(field_atom, value)}
  end

  @impl true
  def handle_event("create_gift_button", _params, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = socket.assigns.friend.id

    button_attrs = %{
      "name" => socket.assigns.gift_button_name,
      "type" => socket.assigns.gift_button_type,
      "icon" => socket.assigns.gift_button_icon,
      "color" => socket.assigns.gift_button_color
    }

    message = case socket.assigns.gift_button_message do
      "" -> nil
      msg -> msg
    end

    case Buttons.create_button_for_friend(button_attrs, friend_id, user_id, message) do
      {:ok, button} ->
        {:noreply,
         socket
         |> put_flash(:info, "Button '#{button.name}' created for #{socket.assigns.friend.display_name}!")
         |> assign(:show_gift_button_form, false)
         |> assign(:gift_button_name, "")
         |> assign(:gift_button_type, "instant")
         |> assign(:gift_button_icon, "star")
         |> assign(:gift_button_color, "#007AFF")
         |> assign(:gift_button_message, "")}

      {:error, :not_friends} ->
        {:noreply, socket |> put_flash(:error, "You can only create buttons for friends")}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {msg, _opts}} -> "#{field} #{msg}" end)
        {:noreply, socket |> put_flash(:error, "Failed to create button: #{Enum.join(errors, ", ")}")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
