defmodule ButtonLogWeb.ButtonLive.Index do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Buttons
  alias ButtonLog.Notifications


  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      user = ButtonLog.Accounts.get_user!(user_id)
      buttons = ButtonLog.Buttons.list_user_buttons(user_id)
      friends = ButtonLog.Social.get_user_friends(user_id)

      if connected?(socket) do
        Phoenix.PubSub.subscribe(ButtonLog.PubSub, "buttons")
      end

      {:ok,
       socket
       |> assign(:all_buttons, buttons)
       |> assign(:buttons, buttons)
       |> assign(:current_user, user)
       |> assign(:friends, friends)
       |> assign(:show_create_form, false)
       |> assign(:button_changeset, nil)
       |> assign(:page_title, "ButtonLog")
       |> assign(:authenticated, true)
       |> assign(:search_query, "")
       |> assign(:filter_type, "all")}
    else
      {:ok,
       socket
       |> assign(:all_buttons, [])
       |> assign(:buttons, [])
       |> assign(:current_user, nil)
       |> assign(:friends, [])
       |> assign(:show_create_form, false)
       |> assign(:button_changeset, nil)
       |> assign(:page_title, "ButtonLog")
       |> assign(:authenticated, false)
       |> assign(:search_query, "")
       |> assign(:filter_type, "all")}
    end
  end

  @impl true
  def handle_params(%{"id" => _id}, _, socket) do
    {:noreply, socket |> assign(:page_title, "Edit Button")}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket |> assign(:page_title, "ButtonLog")}
  end

  @impl true
  def handle_event("show_create_form", _, socket) do
    {:noreply, socket |> assign(:show_create_form, true)}
  end

  @impl true
  def handle_event("hide_create_form", _, socket) do
    {:noreply, socket |> assign(:show_create_form, false)}
  end

  @impl true
  def handle_event("timezone-detected", %{"timezone" => timezone}, socket) do
    {:noreply, socket |> assign(:client_timezone, timezone)}
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    filtered_buttons = filter_buttons(socket.assigns.all_buttons, query, socket.assigns.filter_type)
    {:noreply, socket |> assign(:search_query, query) |> assign(:buttons, filtered_buttons)}
  end

  @impl true
  def handle_event("filter_type", %{"filter_type" => type}, socket) do
    filtered_buttons = filter_buttons(socket.assigns.all_buttons, socket.assigns.search_query, type)
    {:noreply, socket |> assign(:filter_type, type) |> assign(:buttons, filtered_buttons)}
  end

  @impl true
  def handle_event("clear_search", _, socket) do
    {:noreply, socket
     |> assign(:search_query, "")
     |> assign(:filter_type, "all")
     |> assign(:buttons, socket.assigns.all_buttons)}
  end

  @impl true
  def handle_event("edit", %{"id" => button_id}, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/buttons/#{button_id}")}
  end

  @impl true
  def handle_event("validate_button", %{"button" => button_params}, socket) do
    changeset =
      ButtonLog.Buttons.Button.create_changeset(%ButtonLog.Buttons.Button{}, button_params, socket.assigns.current_user.id)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:button_changeset, changeset)}
  end

  @impl true
  def handle_event("validate_create_button", _params, socket) do
    # Handle form validation during input
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_button", %{"button" => button_params}, socket) do
    user = socket.assigns.current_user

    # Process choices if present - convert indexed map to list and filter empty
    button_params = case Map.get(button_params, "choices") do
      nil -> button_params
      choices when is_map(choices) ->
        # Convert {"0" => "Yes", "1" => "No"} to ["Yes", "No"]
        choices_list = choices
        |> Enum.sort_by(fn {k, _v} -> String.to_integer(k) end)
        |> Enum.map(fn {_k, v} -> v end)
        |> Enum.filter(fn c -> c != nil and String.trim(c) != "" end)

        # Only set choices if we have at least 2 valid options
        if length(choices_list) >= 2 do
          Map.put(button_params, "choices", choices_list)
        else
          Map.delete(button_params, "choices")
        end
      _ -> button_params
    end

    # Parse friend_alerts configuration
    friend_alert_config = parse_friend_alert_config(button_params["friend_alerts"])

    case Buttons.create_button(button_params, user.id, friend_alert_config) do
      {:ok, button} ->
        # Refresh the buttons list to get proper structure with latest_click_at
        updated_buttons = ButtonLog.Buttons.list_user_buttons(user.id)
        filtered_buttons = filter_buttons(updated_buttons, socket.assigns.search_query, socket.assigns.filter_type)

        # Broadcast to all connected clients
        Phoenix.PubSub.broadcast!(
          ButtonLog.PubSub,
          "buttons",
          {:button_created, button}
        )

        {:noreply,
         socket
         |> put_flash(:info, "Button created successfully!")
         |> assign(:show_create_form, false)
         |> assign(:button_changeset, nil)
         |> assign(:all_buttons, updated_buttons)
         |> assign(:buttons, filtered_buttons)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> put_flash(:error, "Failed to create button") |> assign(:button_changeset, changeset)}
    end
  end

  @impl true
  def handle_event("click_with_choice", %{"id" => button_id, "choice" => choice}, socket) do
    user = socket.assigns.current_user
    button = Enum.find(socket.assigns.buttons, &(&1.id == button_id))

    case Buttons.click_button(button_id, user.id, selected_choice: choice) do
      {:ok, click} ->
        # Refresh the buttons list to show updated state (one-time buttons get archived)
        updated_buttons = ButtonLog.Buttons.list_user_buttons(user.id)
        filtered_buttons = filter_buttons(updated_buttons, socket.assigns.search_query, socket.assigns.filter_type)

        # Send notifications to friends
        Notifications.send_button_click_notifications(button_id, user.id, %{
          clicked_at: click.clicked_at,
          action: click.action,
          platform: click.platform,
          selected_choice: choice
        })

        # Broadcast to all connected clients
        Phoenix.PubSub.broadcast!(
          ButtonLog.PubSub,
          "buttons",
          {:button_clicked, click}
        )

        message = "'#{button.name}' completed with choice '#{choice}'"
        {:noreply, socket
         |> assign(:all_buttons, updated_buttons)
         |> assign(:buttons, filtered_buttons)
         |> put_flash(:info, message)}

      {:error, :choice_required} ->
        {:noreply, socket |> put_flash(:error, "This button requires selecting a choice")}

      {:error, :invalid_choice} ->
        {:noreply, socket |> put_flash(:error, "The selected choice is not valid for this button")}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {msg, _opts}} -> "#{field} #{msg}" end)
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{Enum.join(errors, ", ")}")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{reason}")}
    end
  end

  @impl true
  def handle_event("click", %{"id" => button_id}, socket) do
    user = socket.assigns.current_user
    button = Enum.find(socket.assigns.buttons, &(&1.id == button_id))

    case Buttons.click_button(button_id, user.id) do
      {:ok, click} ->
        # Refresh the buttons list to show updated state
        updated_buttons = ButtonLog.Buttons.list_user_buttons(user.id)
        filtered_buttons = filter_buttons(updated_buttons, socket.assigns.search_query, socket.assigns.filter_type)

        # Send notifications to friends
        Notifications.send_button_click_notifications(button_id, user.id, %{
          clicked_at: click.clicked_at,
          action: click.action,
          platform: click.platform
        })

        # Broadcast to all connected clients
        Phoenix.PubSub.broadcast!(
          ButtonLog.PubSub,
          "buttons",
          {:button_clicked, click}
        )

        message = generate_click_message(button, click)
        {:noreply, socket
         |> assign(:all_buttons, updated_buttons)
         |> assign(:buttons, filtered_buttons)
         |> put_flash(:info, message)}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {msg, _opts}} -> "#{field} #{msg}" end)
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{Enum.join(errors, ", ")}")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{reason}")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => button_id}, socket) do
    user = socket.assigns.current_user

    case Buttons.delete_button(button_id, user.id) do
      {:ok, _button} ->
        # Broadcast to all connected clients
        Phoenix.PubSub.broadcast!(
          ButtonLog.PubSub,
          "buttons",
          {:button_deleted, button_id}
        )

        {:noreply, socket |> put_flash(:info, "Button deleted successfully!")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete button: #{reason}")}
    end
  end

  @impl true
  def handle_info({:button_created, button}, socket) do
    # Only add the button if it's not already in our list (avoids duplicates for the creator)
    already_exists = Enum.any?(socket.assigns.all_buttons, fn b -> b.id == button.id end)

    if already_exists do
      {:noreply, socket}
    else
      # For new buttons from other users, add the latest_click_at field (nil for new buttons)
      button_with_latest_click = Map.put(button, :latest_click_at, nil)
      all_buttons = [button_with_latest_click | socket.assigns.all_buttons]
      filtered_buttons = filter_buttons(all_buttons, socket.assigns.search_query, socket.assigns.filter_type)
      {:noreply, socket |> assign(:all_buttons, all_buttons) |> assign(:buttons, filtered_buttons)}
    end
  end

  @impl true
  def handle_info({:button_clicked, _click}, socket) do
    # Don't show flash message here since the original click handler already shows it
    {:noreply, socket}
  end

  @impl true
  def handle_info({:button_deleted, button_id}, socket) do
    all_buttons = Enum.reject(socket.assigns.all_buttons, fn button -> button.id == button_id end)
    filtered_buttons = filter_buttons(all_buttons, socket.assigns.search_query, socket.assigns.filter_type)
    {:noreply, socket |> assign(:all_buttons, all_buttons) |> assign(:buttons, filtered_buttons)}
  end

  # Private helper functions
  defp filter_buttons(buttons, query, type_filter) do
    buttons
    |> filter_by_search(query)
    |> filter_by_type(type_filter)
  end

  defp filter_by_search(buttons, nil), do: buttons
  defp filter_by_search(buttons, ""), do: buttons
  defp filter_by_search(buttons, query) do
    query_downcase = String.downcase(query)
    Enum.filter(buttons, fn button ->
      String.contains?(String.downcase(button.name), query_downcase) ||
        (button.description && String.contains?(String.downcase(button.description), query_downcase))
    end)
  end

  defp filter_by_type(buttons, "all"), do: buttons
  defp filter_by_type(buttons, type) do
    Enum.filter(buttons, fn button -> button.type == type end)
  end

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

  # Parse friend_alerts configuration from form params
  defp parse_friend_alert_config(nil), do: nil
  defp parse_friend_alert_config(%{"mode" => "none"}), do: %{mode: "none"}
  defp parse_friend_alert_config(%{"mode" => "all_friends"}), do: %{mode: "all_friends"}
  defp parse_friend_alert_config(%{"mode" => "select_specific", "friend_ids" => friend_ids}) when is_list(friend_ids) do
    %{mode: "select_specific", friend_ids: friend_ids}
  end
  defp parse_friend_alert_config(%{"mode" => "select_specific"}), do: %{mode: "none"}  # No friends selected
  defp parse_friend_alert_config(_), do: nil
end
