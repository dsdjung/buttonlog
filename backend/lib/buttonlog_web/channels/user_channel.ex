defmodule ButtonLogWeb.UserChannel do
  use ButtonLogWeb, :channel

  def join("user:" <> user_id, _params, socket) do
    if authorized?(socket.assigns.user_id, user_id) do
      {:ok, assign(socket, :target_user_id, user_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("update_status", %{"status" => status}, socket) do
    user_id = socket.assigns.user_id

    case ButtonLog.Accounts.update_user_status(user_id, status) do
      {:ok, _user} ->
        broadcast!(socket, "status_updated", %{
          user_id: user_id,
          status: status,
          updated_at: DateTime.utc_now()
        })
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  def handle_in("send_notification", %{"recipient_id" => recipient_id, "message" => message}, socket) do
    sender_id = socket.assigns.user_id

    case ButtonLog.Notifications.create_notification(recipient_id, sender_id, "message", message) do
      {:ok, notification} ->
        # Broadcast to the recipient
        ButtonLogWeb.Endpoint.broadcast!(
          "user:#{recipient_id}",
          "notification_received",
          %{
            id: notification.id,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            sender_id: sender_id,
            created_at: notification.inserted_at
          }
        )

        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  defp authorized?(current_user_id, target_user_id) do
    # Users can only join their own channel or their friends' channels
    current_user_id == target_user_id || ButtonLog.Social.are_friends?(current_user_id, target_user_id)
  end
end

