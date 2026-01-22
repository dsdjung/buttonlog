defmodule ButtonLogWeb.API.SupportController do
  use ButtonLogWeb, :controller

  alias ButtonLog.Support

  @doc """
  Lists all support tickets for the current user.
  GET /api/support/tickets
  """
  def index(conn, _params) do
    user = conn.assigns.current_user
    tickets = Support.list_user_tickets(user.id)

    json(conn, %{
      success: true,
      data: Enum.map(tickets, &serialize_ticket/1),
      meta: %{
        timestamp: DateTime.utc_now(),
        count: length(tickets)
      }
    })
  end

  @doc """
  Gets a specific support ticket with messages.
  GET /api/support/tickets/:id
  """
  def show(conn, %{"id" => ticket_id}) do
    user = conn.assigns.current_user

    case Support.get_ticket(ticket_id, user.id) do
      {:ok, ticket} ->
        # Mark messages as read when viewing
        Support.mark_ticket_messages_read(ticket_id, user.id)

        json(conn, %{
          success: true,
          data: serialize_ticket_with_messages(ticket)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Ticket not found"}
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{code: "FORBIDDEN", message: "Access denied"}
        })
    end
  end

  @doc """
  Creates a new support ticket.
  POST /api/support/tickets
  """
  def create(conn, %{"ticket" => ticket_params}) do
    user = conn.assigns.current_user

    # Extract initial message if provided
    message = Map.get(ticket_params, "message")
    ticket_attrs = Map.drop(ticket_params, ["message"])

    result =
      if message && message != "" do
        Support.create_ticket_with_message(ticket_attrs, message, user.id)
      else
        Support.create_ticket(ticket_attrs, user.id)
      end

    case result do
      {:ok, ticket} ->
        ticket = ticket |> ButtonLog.Repo.preload([messages: [:sender], assigned_admin: []])

        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: serialize_ticket_with_messages(ticket)
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid ticket data",
            details: format_changeset_errors(changeset)
          }
        })
    end
  end

  @doc """
  Adds a message to a ticket.
  POST /api/support/tickets/:id/messages
  """
  def add_message(conn, %{"id" => ticket_id, "message" => message_params}) do
    user = conn.assigns.current_user
    content = Map.get(message_params, "content")

    # First verify ticket ownership
    case Support.get_ticket(ticket_id, user.id) do
      {:ok, _ticket} ->
        case Support.add_message(ticket_id, content, user.id) do
          {:ok, message} ->
            message = message |> ButtonLog.Repo.preload(:sender)

            conn
            |> put_status(:created)
            |> json(%{
              success: true,
              data: serialize_message(message, user.id)
            })

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              success: false,
              error: %{
                code: "VALIDATION_ERROR",
                message: "Invalid message",
                details: format_changeset_errors(changeset)
              }
            })
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Ticket not found"}
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{code: "FORBIDDEN", message: "Access denied"}
        })
    end
  end

  # ============================================================================
  # Serialization
  # ============================================================================

  defp serialize_ticket(ticket) do
    %{
      id: ticket.id,
      subject: ticket.subject,
      category: ticket.category,
      priority: ticket.priority,
      status: ticket.status,
      unread_count: Map.get(ticket, :unread_count, 0),
      assigned_admin: serialize_admin(ticket.assigned_admin),
      created_at: ticket.inserted_at,
      updated_at: ticket.updated_at
    }
  end

  defp serialize_ticket_with_messages(ticket) do
    user_id = ticket.user_id

    ticket
    |> serialize_ticket()
    |> Map.put(:messages, Enum.map(ticket.messages || [], &serialize_message(&1, user_id)))
  end

  defp serialize_message(message, viewer_user_id) do
    sender = message.sender

    %{
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: if(sender, do: sender.display_name || sender.username, else: nil),
      is_from_support: message.sender_id != viewer_user_id,
      created_at: message.inserted_at,
      read_at: message.read_at
    }
  end

  defp serialize_admin(nil), do: nil

  defp serialize_admin(admin) do
    %{
      id: admin.id,
      name: admin.display_name || admin.username
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
