defmodule ButtonLogWeb.FriendsLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Social
  alias ButtonLog.Accounts
  alias ButtonLog.Buttons

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      user = ButtonLog.Accounts.get_user!(user_id)

      # Get user's friends and pending requests
      friends = Social.get_user_friends(user_id)
      pending_requests = Social.get_pending_friend_requests(user_id)
      sent_requests = Social.get_sent_friend_requests(user_id)
      created_gift_buttons = Buttons.list_created_gift_buttons(user_id)

      {:ok,
       socket
       |> assign(:current_user, user)
       |> assign(:friends, friends)
       |> assign(:pending_requests, pending_requests)
       |> assign(:sent_requests, sent_requests)
       |> assign(:created_gift_buttons, created_gift_buttons)
       |> assign(:show_gift_buttons, false)
       |> assign(:editing_gift_button, nil)
       |> assign(:invite_email, "")
       |> assign(:page_title, "Friends")}
    else
      {:ok,
       socket
       |> assign(:current_user, nil)
       |> assign(:friends, [])
       |> assign(:pending_requests, [])
       |> assign(:sent_requests, [])
       |> assign(:created_gift_buttons, [])
       |> assign(:show_gift_buttons, false)
       |> assign(:editing_gift_button, nil)
       |> assign(:invite_email, "")
       |> assign(:page_title, "Friends")}
    end
  end

  @impl true
  def handle_event("send_invite", %{"email" => email}, socket) do
    user = socket.assigns.current_user
    email = String.trim(email)

    # Check if inviting self
    if String.downcase(email) == String.downcase(user.email) do
      {:noreply, socket |> put_flash(:error, "You cannot invite yourself")}
    else
      # Check if user exists
      case Accounts.get_user_by_email(email) do
        nil ->
          # User not registered - send invitation email
          case Social.send_friend_invitation(user.id, email) do
            {:ok, :invitation_sent} ->
              {:noreply,
               socket
               |> put_flash(:info, "Invite sent to #{email}")
               |> assign(:invite_email, "")}

            {:error, _} ->
              # Still show success to prevent enumeration
              {:noreply,
               socket
               |> put_flash(:info, "Invite sent to #{email}")
               |> assign(:invite_email, "")}
          end

        friend ->
          # User exists - send friend request
          case Social.send_friend_request(user.id, friend.id) do
            {:ok, _friendship} ->
              sent_requests = Social.get_sent_friend_requests(user.id)
              {:noreply,
               socket
               |> put_flash(:info, "Invite sent to #{email}")
               |> assign(:sent_requests, sent_requests)
               |> assign(:invite_email, "")}

            {:error, _} ->
              # Still show success to prevent enumeration
              {:noreply,
               socket
               |> put_flash(:info, "Invite sent to #{email}")
               |> assign(:invite_email, "")}
          end
      end
    end
  end

  @impl true
  def handle_event("accept_friend_request", %{"friendship_id" => friendship_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.accept_friend_request(friendship_id, user_id) do
      {:ok, _friendship} ->
        # Refresh friends and pending requests
        friends = Social.get_user_friends(user_id)
        pending_requests = Social.get_pending_friend_requests(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Friend request accepted!")
         |> assign(:friends, friends)
         |> assign(:pending_requests, pending_requests)}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "Unauthorized")}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, "Friend request not found")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to accept friend request")}
    end
  end

  @impl true
  def handle_event("decline_friend_request", %{"friendship_id" => friendship_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.decline_friend_request(friendship_id, user_id) do
      {:ok, _} ->
        # Refresh pending requests
        pending_requests = Social.get_pending_friend_requests(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Friend request declined")
         |> assign(:pending_requests, pending_requests)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to decline friend request")}
    end
  end



  @impl true
  def handle_event("cancel_friend_request", %{"friendship_id" => friendship_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.cancel_friend_request(friendship_id, user_id) do
      {:ok, :deleted} ->
        # Refresh sent requests
        sent_requests = Social.get_sent_friend_requests(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Friend request cancelled")
         |> assign(:sent_requests, sent_requests)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to cancel friend request")}
    end
  end

  @impl true
  def handle_event("toggle_gift_buttons", _params, socket) do
    {:noreply, assign(socket, :show_gift_buttons, !socket.assigns.show_gift_buttons)}
  end

  @impl true
  def handle_event("edit_gift_button", %{"button_id" => button_id}, socket) do
    button = Enum.find(socket.assigns.created_gift_buttons, &(&1.id == button_id))
    {:noreply, assign(socket, :editing_gift_button, button)}
  end

  @impl true
  def handle_event("cancel_edit_gift_button", _params, socket) do
    {:noreply, assign(socket, :editing_gift_button, nil)}
  end

  @impl true
  def handle_event("save_gift_button", %{"button" => button_params}, socket) do
    user_id = socket.assigns.current_user.id
    button = socket.assigns.editing_gift_button

    # Filter out empty choices
    button_params = case button_params do
      %{"choices" => choices} when is_list(choices) ->
        filtered_choices = Enum.filter(choices, &(String.trim(&1) != ""))
        Map.put(button_params, "choices", filtered_choices)
      _ ->
        button_params
    end

    case Buttons.update_button(button.id, button_params, user_id) do
      {:ok, _updated_button} ->
        created_gift_buttons = Buttons.list_created_gift_buttons(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Gift button updated!")
         |> assign(:created_gift_buttons, created_gift_buttons)
         |> assign(:editing_gift_button, nil)}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Failed to update gift button")}
    end
  end

  @impl true
  def handle_event("delete_gift_button", %{"button_id" => button_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Buttons.delete_button(button_id, user_id) do
      {:ok, _deleted} ->
        created_gift_buttons = Buttons.list_created_gift_buttons(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Gift button deleted")
         |> assign(:created_gift_buttons, created_gift_buttons)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete gift button")}
    end
  end
end
