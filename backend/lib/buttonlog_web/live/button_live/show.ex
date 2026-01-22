defmodule ButtonLogWeb.ButtonLive.Show do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Buttons
  alias ButtonLog.Social

  @impl true
  def mount(%{"id" => button_id}, session, socket) do
    user_id = session["user_id"]

    if user_id do
      case Buttons.get_button(button_id, user_id) do
        {:ok, button} ->
          user = ButtonLog.Accounts.get_user!(user_id)

          # Load button clicks
          {:ok, button_clicks} = Buttons.list_button_clicks(button_id, user_id, 10)

          # Load collaborators and friends for sharing UI
          collaborators = Buttons.list_collaborators(button_id, user_id)
          friends = Social.get_user_friends(user_id)

          {:ok,
           socket
           |> assign(:button, button)
           |> assign(:button_clicks, button_clicks)
           |> assign(:current_user, user)
           |> assign(:page_title, button.name)
           |> assign(:authenticated, true)
           |> assign(:collaborators, collaborators)
           |> assign(:friends, friends)
           |> assign(:show_add_collaborator_modal, false)}

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
        # Send alerts to friends
        ButtonLog.Alerts.send_button_click_alerts(button.id, user.id, %{
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

  # Sharing mode change
  @impl true
  def handle_event("change_sharing_mode", %{"mode" => mode}, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.update_sharing_mode(button.id, user.id, mode) do
      {:ok, updated_button} ->
        {:noreply,
         socket
         |> assign(:button, updated_button)
         |> put_flash(:info, "Sharing mode updated to #{format_sharing_mode(mode)}")}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, "Button not found")}

      {:error, :not_authorized} ->
        {:noreply, socket |> put_flash(:error, "Only the button owner can change sharing settings")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to update sharing mode: #{inspect(reason)}")}
    end
  end

  # Generate share link
  @impl true
  def handle_event("generate_share_link", _, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.generate_share_token(button.id, user.id) do
      {:ok, updated_button} ->
        {:noreply,
         socket
         |> assign(:button, updated_button)
         |> put_flash(:info, "Share link generated!")}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, "Button not found")}

      {:error, :not_authorized} ->
        {:noreply, socket |> put_flash(:error, "Only the button owner can generate share links")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to generate share link: #{inspect(reason)}")}
    end
  end

  # Revoke share link
  @impl true
  def handle_event("revoke_share_link", _, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.revoke_share_token(button.id, user.id) do
      {:ok, updated_button} ->
        {:noreply,
         socket
         |> assign(:button, updated_button)
         |> put_flash(:info, "Share link revoked")}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, "Button not found")}

      {:error, :not_authorized} ->
        {:noreply, socket |> put_flash(:error, "Only the button owner can revoke share links")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to revoke share link: #{inspect(reason)}")}
    end
  end

  # Show add collaborator modal
  @impl true
  def handle_event("show_add_collaborator_modal", _, socket) do
    {:noreply, socket |> assign(:show_add_collaborator_modal, true)}
  end

  # Hide add collaborator modal
  @impl true
  def handle_event("hide_add_collaborator_modal", _, socket) do
    {:noreply, socket |> assign(:show_add_collaborator_modal, false)}
  end

  # Add collaborator
  @impl true
  def handle_event("add_collaborator", %{"user_id" => collaborator_user_id}, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.add_collaborator(button.id, user.id, collaborator_user_id) do
      {:ok, _collaborator} ->
        # Refresh collaborators list
        collaborators = Buttons.list_collaborators(button.id, user.id)
        {:noreply,
         socket
         |> assign(:collaborators, collaborators)
         |> assign(:show_add_collaborator_modal, false)
         |> put_flash(:info, "Collaborator added!")}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, "Button not found")}

      {:error, :not_authorized} ->
        {:noreply, socket |> put_flash(:error, "Only the button owner can add collaborators")}

      {:error, :already_collaborator} ->
        {:noreply, socket |> put_flash(:error, "User is already a collaborator")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to add collaborator: #{inspect(reason)}")}
    end
  end

  # Remove collaborator
  @impl true
  def handle_event("remove_collaborator", %{"user_id" => collaborator_user_id}, socket) do
    button = socket.assigns.button
    user = socket.assigns.current_user

    case Buttons.remove_collaborator(button.id, user.id, collaborator_user_id) do
      {:ok, _} ->
        # Refresh collaborators list
        collaborators = Buttons.list_collaborators(button.id, user.id)
        {:noreply,
         socket
         |> assign(:collaborators, collaborators)
         |> put_flash(:info, "Collaborator removed")}

      {:error, :not_found} ->
        {:noreply, socket |> put_flash(:error, "Button or collaborator not found")}

      {:error, :not_authorized} ->
        {:noreply, socket |> put_flash(:error, "Only the button owner can remove collaborators")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to remove collaborator: #{inspect(reason)}")}
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

  # Format sharing mode for display
  defp format_sharing_mode("private"), do: "Private"
  defp format_sharing_mode("friends"), do: "Friends"
  defp format_sharing_mode("invite_only"), do: "Invite Only"
  defp format_sharing_mode("public"), do: "Public"
  defp format_sharing_mode(_), do: "Unknown"

  # Build share URL from token
  defp build_share_url(share_token) do
    base_url = ButtonLogWeb.Endpoint.url()
    "#{base_url}/buttons/join/#{share_token}"
  end

  # Get available friends who are not already collaborators
  defp available_friends(friends, collaborators) do
    collaborator_ids = Enum.map(collaborators, fn c -> c.user_id end)
    Enum.reject(friends, fn friend -> friend.id in collaborator_ids end)
  end
end
