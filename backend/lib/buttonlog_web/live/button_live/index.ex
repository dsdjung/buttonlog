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

      if connected?(socket) do
        Phoenix.PubSub.subscribe(ButtonLog.PubSub, "buttons")
      end

      {:ok,
       socket
       |> assign(:buttons, buttons)
       |> assign(:current_user, user)
       |> assign(:show_create_form, false)
       |> assign(:button_changeset, nil)
       |> assign(:page_title, "ButtonLog")
       |> assign(:authenticated, true)}
    else
      {:ok,
       socket
       |> assign(:buttons, [])
       |> assign(:current_user, nil)
       |> assign(:show_create_form, false)
       |> assign(:button_changeset, nil)
       |> assign(:page_title, "ButtonLog")
       |> assign(:authenticated, false)}
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
  def handle_event("create_button", %{"button" => button_params}, socket) do
    user = socket.assigns.current_user

    case Buttons.create_button(button_params, user.id) do
      {:ok, button} ->
        # Refresh the buttons list to get proper structure with latest_click_at
        updated_buttons = ButtonLog.Buttons.list_user_buttons(user.id)

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
         |> assign(:buttons, updated_buttons)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> put_flash(:error, "Failed to create button") |> assign(:button_changeset, changeset)}
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
         |> assign(:buttons, updated_buttons)
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
    # For new buttons, we need to add the latest_click_at field (nil for new buttons)
    button_with_latest_click = Map.put(button, :latest_click_at, nil)
    buttons = [button_with_latest_click | socket.assigns.buttons]
    {:noreply, socket |> assign(:buttons, buttons)}
  end

  @impl true
  def handle_info({:button_clicked, _click}, socket) do
    # Don't show flash message here since the original click handler already shows it
    {:noreply, socket}
  end

  @impl true
  def handle_info({:button_deleted, button_id}, socket) do
    buttons = Enum.reject(socket.assigns.buttons, fn button -> button.id == button_id end)
    {:noreply, socket |> assign(:buttons, buttons)}
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
    end
  end

  defp generate_click_message(_, _), do: "Button clicked!"

  # Helper function to safely convert timestamps to ISO8601
  defp safe_to_iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp safe_to_iso8601(%NaiveDateTime{} = naive_datetime) do
    naive_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
  end
  defp safe_to_iso8601(nil), do: ""
end
