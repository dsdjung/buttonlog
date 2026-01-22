defmodule ButtonLogWeb.SupportLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Support

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = ButtonLog.Accounts.get_user!(user_id)
      tickets = Support.list_user_tickets(user_id)
      unread_count = Support.count_unread_tickets(user_id)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:tickets, tickets)
       |> assign(:unread_count, unread_count)
       |> assign(:selected_ticket, nil)
       |> assign(:show_new_ticket_form, false)
       |> assign(:form_subject, "")
       |> assign(:form_category, "question")
       |> assign(:form_priority, "normal")
       |> assign(:form_message, "")
       |> assign(:new_message, "")
       |> assign(:submitting, false)
       |> assign(:page_title, "Help & Support")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access support")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_params(%{"id" => ticket_id}, _url, socket) do
    user_id = socket.assigns.current_user.id

    case Support.get_ticket(ticket_id, user_id) do
      {:ok, ticket} ->
        # Mark messages as read when viewing the ticket
        Support.mark_ticket_messages_read(ticket_id, user_id)
        # Refresh unread count
        unread_count = Support.count_unread_tickets(user_id)

        {:noreply,
         socket
         |> assign(:selected_ticket, ticket)
         |> assign(:unread_count, unread_count)
         |> assign(:page_title, "Ticket: #{ticket.subject}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Ticket not found")
         |> push_navigate(to: ~p"/support")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:selected_ticket, nil)
     |> assign(:page_title, "Help & Support")}
  end

  @impl true
  def handle_event("show_new_ticket_form", _params, socket) do
    {:noreply, assign(socket, :show_new_ticket_form, true)}
  end

  @impl true
  def handle_event("hide_new_ticket_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_new_ticket_form, false)
     |> assign(:form_subject, "")
     |> assign(:form_category, "question")
     |> assign(:form_priority, "normal")
     |> assign(:form_message, "")}
  end

  @impl true
  def handle_event("validate_ticket", %{"ticket" => ticket_params}, socket) do
    {:noreply,
     socket
     |> assign(:form_subject, Map.get(ticket_params, "subject", ""))
     |> assign(:form_category, Map.get(ticket_params, "category", "question"))
     |> assign(:form_priority, Map.get(ticket_params, "priority", "normal"))
     |> assign(:form_message, Map.get(ticket_params, "message", ""))}
  end

  @impl true
  def handle_event("create_ticket", %{"ticket" => ticket_params}, socket) do
    subject = String.trim(Map.get(ticket_params, "subject", ""))
    category = Map.get(ticket_params, "category", "question")
    priority = Map.get(ticket_params, "priority", "normal")
    message = String.trim(Map.get(ticket_params, "message", ""))
    user_id = socket.assigns.current_user.id

    if subject == "" || message == "" do
      {:noreply, put_flash(socket, :error, "Subject and message are required")}
    else
      socket = assign(socket, :submitting, true)

      ticket_attrs = %{
        subject: subject,
        category: category,
        priority: priority
      }

      case Support.create_ticket_with_message(ticket_attrs, message, user_id) do
        {:ok, ticket} ->
          tickets = Support.list_user_tickets(user_id)

          {:noreply,
           socket
           |> assign(:tickets, tickets)
           |> assign(:show_new_ticket_form, false)
           |> assign(:form_subject, "")
           |> assign(:form_category, "question")
           |> assign(:form_priority, "normal")
           |> assign(:form_message, "")
           |> assign(:submitting, false)
           |> put_flash(:info, "Ticket created successfully")
           |> push_navigate(to: ~p"/support/#{ticket.id}")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> assign(:submitting, false)
           |> put_flash(:error, "Failed to create ticket")}
      end
    end
  end

  @impl true
  def handle_event("validate_message", %{"reply" => %{"content" => content}}, socket) do
    {:noreply, assign(socket, :new_message, content)}
  end

  @impl true
  def handle_event("send_message", %{"reply" => %{"content" => content}}, socket) do
    message = String.trim(content)
    ticket = socket.assigns.selected_ticket
    user_id = socket.assigns.current_user.id

    if message == "" do
      {:noreply, put_flash(socket, :error, "Message cannot be empty")}
    else
      case Support.add_message(ticket.id, message, user_id) do
        {:ok, _new_message} ->
          # Reload the ticket to get updated messages
          {:ok, updated_ticket} = Support.get_ticket(ticket.id, user_id)

          {:noreply,
           socket
           |> assign(:selected_ticket, updated_ticket)
           |> assign(:new_message, "")
           |> put_flash(:info, "Message sent")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Failed to send message")}
      end
    end
  end

  @impl true
  def handle_event("back_to_list", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/support")}
  end

  # Helper functions
  defp category_icon(category) do
    case category do
      "bug" -> "bug"
      "feature_request" -> "lightbulb"
      "question" -> "question-mark-circle"
      _ -> "chat-bubble-left-ellipsis"
    end
  end

  defp category_display(category) do
    case category do
      "bug" -> "Bug Report"
      "feature_request" -> "Feature Request"
      "question" -> "Question"
      _ -> "Other"
    end
  end

  defp status_color(status) do
    case status do
      "open" -> "yellow"
      "in_progress" -> "blue"
      "resolved" -> "green"
      "closed" -> "gray"
      _ -> "gray"
    end
  end

  defp status_display(status) do
    case status do
      "open" -> "Open"
      "in_progress" -> "In Progress"
      "resolved" -> "Resolved"
      "closed" -> "Closed"
      _ -> status
    end
  end

  defp priority_display(priority) do
    case priority do
      "low" -> "Low"
      "normal" -> "Normal"
      "high" -> "High"
      "urgent" -> "Urgent"
      _ -> priority
    end
  end

  defp format_datetime(nil), do: ""
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y %I:%M %p")
  defp format_datetime(%NaiveDateTime{} = ndt), do: Calendar.strftime(ndt, "%b %d, %Y %I:%M %p")

  defp is_active_status?(status), do: status in ["open", "in_progress"]
end
