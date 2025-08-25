defmodule ButtonLogWeb.ButtonChannel do
  use ButtonLogWeb, :channel

  def join("button:" <> button_id, _params, socket) do
    if authorized?(socket.assigns.user_id, button_id) do
      {:ok, assign(socket, :button_id, button_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("click", _params, socket) do
    user_id = socket.assigns.user_id
    button_id = socket.assigns.button_id

    case ButtonLog.Buttons.click_button(button_id, user_id) do
      {:ok, click} ->
        # Broadcast to all users subscribed to this button
        broadcast!(socket, "button_clicked", %{
          user_id: user_id,
          button_id: button_id,
          clicked_at: click.clicked_at,
          device: click.device,
          platform: click.platform
        })

        # Also broadcast to user's friends if they have permission
        broadcast_to_friends(user_id, button_id, click)

        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  def handle_in("start_timer", _params, socket) do
    user_id = socket.assigns.user_id
    button_id = socket.assigns.button_id

    # Start a timer for timed buttons
    case ButtonLog.Buttons.start_timer(button_id, user_id) do
      {:ok, timer} ->
        broadcast!(socket, "timer_started", %{
          user_id: user_id,
          button_id: button_id,
          started_at: timer.started_at
        })
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  def handle_in("stop_timer", _params, socket) do
    user_id = socket.assigns.user_id
    button_id = socket.assigns.button_id

    case ButtonLog.Buttons.stop_timer(button_id, user_id) do
      {:ok, duration} ->
        broadcast!(socket, "timer_stopped", %{
          user_id: user_id,
          button_id: button_id,
          duration: duration
        })
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  defp authorized?(_user_id, _button_id) do
    # TODO: Implement proper authorization
    # For now, allow all authenticated users
    true
  end

  defp broadcast_to_friends(_user_id, _button_id, _click) do
    # TODO: Implement friend notification broadcasting
    # This would check friend permissions and send notifications
    :ok
  end
end
