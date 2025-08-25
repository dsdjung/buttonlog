defmodule ButtonLogWeb.FriendsLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Social
  alias ButtonLog.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      user = ButtonLog.Accounts.get_user!(user_id)

      # Get user's friends and pending requests
      friends = Social.get_user_friends(user_id)
      pending_requests = Social.get_pending_friend_requests(user_id)
      sent_requests = Social.get_sent_friend_requests(user_id)

      {:ok,
       socket
       |> assign(:current_user, user)
       |> assign(:friends, friends)
       |> assign(:pending_requests, pending_requests)
       |> assign(:sent_requests, sent_requests)
       |> assign(:search_query, "")
       |> assign(:search_results, [])
       |> assign(:page_title, "Friends")}
    else
      {:ok,
       socket
       |> assign(:current_user, nil)
       |> assign(:friends, [])
       |> assign(:pending_requests, [])
       |> assign(:sent_requests, [])
       |> assign(:search_query, "")
       |> assign(:search_results, [])
       |> assign(:page_title, "Friends")}
    end
  end

  @impl true
  def handle_event("search_users", %{"query" => query}, socket) do
    if String.length(query) >= 3 do
      results = Accounts.search_users(query, socket.assigns.current_user.id)
      {:noreply, socket |> assign(:search_results, results) |> assign(:search_query, query)}
    else
      {:noreply, socket |> assign(:search_results, []) |> assign(:search_query, query)}
    end
  end

  @impl true
  def handle_event("send_friend_request", %{"user_id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id

    IO.puts "=== FRIEND REQUEST EVENT DEBUG ==="
    IO.puts "user_id from socket: #{user_id}"
    IO.puts "friend_id from params: #{friend_id}"
    IO.puts "current_user: #{inspect(socket.assigns.current_user)}"

    case Social.send_friend_request(user_id, friend_id) do
      {:ok, _friendship} ->
        IO.puts "Friend request successful"
        # Refresh sent requests
        sent_requests = Social.get_sent_friend_requests(user_id)
        {:noreply,
         socket
         |> put_flash(:info, "Friend request sent!")
         |> assign(:sent_requests, sent_requests)
         |> assign(:search_results, [])}

      {:error, :already_friends} ->
        IO.puts "Already friends error"
        {:noreply, socket |> put_flash(:error, "You are already friends with this user")}

      {:error, :user_not_found} ->
        IO.puts "User not found error"
        {:noreply, socket |> put_flash(:error, "User not found")}

      {:error, reason} ->
        IO.puts "Other error: #{inspect(reason)}"
        {:noreply, socket |> put_flash(:error, "Failed to send friend request: #{inspect(reason)}")}
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
end
