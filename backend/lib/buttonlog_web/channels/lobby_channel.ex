defmodule ButtonLogWeb.LobbyChannel do
  use ButtonLogWeb, :channel

  def join("lobby", _params, socket) do
    # Anyone can join the lobby
    {:ok, socket}
  end

  def handle_in("announce", %{"message" => message}, socket) do
    user_id = socket.assigns.user_id

    # Broadcast announcement to all users in lobby
    broadcast!(socket, "announcement", %{
      user_id: user_id,
      message: message,
      timestamp: DateTime.utc_now()
    })

    {:reply, :ok, socket}
  end

    def handle_in("join_room", %{"room" => room}, socket) do
    user_id = socket.assigns.user_id

    # Join the specific room
    case join_room(room, user_id) do
      {:ok, _} ->
        {:reply, {:ok, %{room: room}}, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  defp join_room(room, user_id) do
    # TODO: Implement room joining logic
    if room && room != "" do
      {:ok, %{room: room, user_id: user_id}}
    else
      {:error, :invalid_room}
    end
  end
end
