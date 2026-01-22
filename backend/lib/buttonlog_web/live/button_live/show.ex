defmodule ButtonLogWeb.ButtonLive.Show do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Buttons

  @impl true
  def mount(%{"id" => button_id}, session, socket) do
    user_id = session["user_id"]

    if user_id do
      case Buttons.get_button(button_id, user_id) do
        {:ok, button} ->
          user = ButtonLog.Accounts.get_user!(user_id)

          # Load button clicks
          {:ok, button_clicks} = Buttons.list_button_clicks(button_id, user_id, 10)

          {:ok,
           socket
           |> assign(:button, button)
           |> assign(:button_clicks, button_clicks)
           |> assign(:current_user, user)
           |> assign(:page_title, button.name)
           |> assign(:authenticated, true)}

        {:error, :not_found} ->
          {:ok,
           socket
           |> put_flash(:error, "Button not found")
           |> push_navigate(to: ~p"/buttons")}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to view buttons")
       |> push_navigate(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("timezone-detected", %{"timezone" => timezone}, socket) do
    {:noreply, socket |> assign(:client_timezone, timezone)}
  end

  @impl true
  def handle_event("click", _, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.click_button(button.id, user.id) do
      {:ok, click} ->
        # Send notifications to friends
        ButtonLog.Notifications.send_button_click_notifications(button.id, user.id, %{
          clicked_at: click.clicked_at,
          action: click.action,
          platform: click.platform
        })

        # For one-time buttons, redirect back to buttons list since the button is now archived
        if button.type == "one-time" do
          {:noreply,
           socket
           |> put_flash(:info, "#{button.name} completed and archived")
           |> push_navigate(to: ~p"/buttons")}
        else
          # Refresh button clicks to show the new one
          {:ok, updated_clicks} = Buttons.list_button_clicks(button.id, user.id, 10)
          # Reload button to get updated state
          {:ok, updated_button} = Buttons.get_button(button.id, user.id)

          message = generate_click_message(updated_button, click)
          {:noreply, socket
           |> assign(:button_clicks, updated_clicks)
           |> assign(:button, updated_button)
           |> put_flash(:info, message)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {msg, _opts}} -> "#{field} #{msg}" end)
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{Enum.join(errors, ", ")}")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{reason}")}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.delete_button(button.id, user.id) do
      {:ok, _button} ->
        {:noreply,
         socket
         |> put_flash(:info, "Button deleted successfully!")
         |> push_navigate(to: ~p"/buttons")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete button: #{reason}")}
    end
  end

  # Private helper functions
  defp generate_click_message(%{name: name, type: type}, click) do
    case type do
      "timed" ->
        # For timed buttons, use the action from the click record
        case click.action do
          "start" -> "#{name} started"
          "end" -> "#{name} ended"
          _ -> "#{name} clicked"
        end

      "state" ->
        # For state buttons, show toggled state
        "#{name} activated"

      "instant" ->
        # For instant buttons, use more natural language
        cond do
          String.contains?(String.downcase(name), ["had", "took", "vitamin", "medicine", "pill"]) ->
            name
          String.contains?(String.downcase(name), ["water", "drink", "coffee", "tea"]) ->
            "Had #{String.downcase(name)}"
          String.contains?(String.downcase(name), ["meal", "breakfast", "lunch", "dinner", "snack"]) ->
            "Had #{String.downcase(name)}"
          true ->
            "#{name} completed"
        end

      "one-time" ->
        "#{name} completed and archived"
    end
  end

  defp generate_click_message(_, _), do: "Button clicked!"

  # Helper function to safely convert timestamps to ISO8601
  defp safe_to_iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp safe_to_iso8601(%NaiveDateTime{} = naive_datetime) do
    naive_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
  end
  defp safe_to_iso8601(nil), do: ""

  # Format auto-stop duration in human-readable form
  defp format_auto_stop_duration(nil), do: nil
  defp format_auto_stop_duration(minutes) when minutes < 60, do: "#{minutes} min"
  defp format_auto_stop_duration(60), do: "1 hour"
  defp format_auto_stop_duration(minutes) when rem(minutes, 60) == 0, do: "#{div(minutes, 60)} hours"
  defp format_auto_stop_duration(minutes), do: "#{div(minutes, 60)}h #{rem(minutes, 60)}m"

  # Format remaining time until scheduled stop
  defp format_time_remaining(nil), do: ""
  defp format_time_remaining(%DateTime{} = scheduled_stop_at) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(scheduled_stop_at, now, :second)

    if diff_seconds > 0 do
      minutes = div(diff_seconds, 60)
      cond do
        minutes < 1 -> "< 1 min"
        minutes < 60 -> "#{minutes} min"
        rem(minutes, 60) == 0 -> "#{div(minutes, 60)} hr"
        true -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
      end
    else
      "now"
    end
  end
  defp format_time_remaining(%NaiveDateTime{} = scheduled_stop_at) do
    scheduled_stop_at
    |> DateTime.from_naive!("Etc/UTC")
    |> format_time_remaining()
  end
end
