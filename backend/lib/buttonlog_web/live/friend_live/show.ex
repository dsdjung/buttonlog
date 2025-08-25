defmodule ButtonLogWeb.FriendLive.Show do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Social

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

          {:ok,
           socket
           |> assign(:current_user, current_user)
           |> assign(:friend, friend)
           |> assign(:friendship, friendship)
           |> assign(:shared_buttons, shared_buttons)
           |> assign(:shared_notifications, shared_notifications)
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
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
