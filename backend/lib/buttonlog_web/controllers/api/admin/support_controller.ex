defmodule ButtonLogWeb.API.Admin.SupportController do
  use ButtonLogWeb, :controller

  alias ButtonLog.Support

  @doc """
  Lists all support tickets with optional filters.
  GET /api/admin/support/tickets
  Query params: status, category, priority, assigned_admin_id, search
  """
  def index(conn, params) do
    filters =
      params
      |> Map.take(["status", "category", "priority", "assigned_admin_id", "search"])
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.new()

    tickets = Support.list_all_tickets(filters)

    json(conn, %{
      success: true,
      data: Enum.map(tickets, &serialize_ticket_admin/1),
      meta: %{
        timestamp: DateTime.utc_now(),
        count: length(tickets),
        filters: filters
      }
    })
  end

  @doc """
  Gets a specific support ticket with all messages (including internal).
  GET /api/admin/support/tickets/:id
  """
  def show(conn, %{"id" => ticket_id}) do
    case Support.get_ticket_admin(ticket_id) do
      {:ok, ticket} ->
        json(conn, %{
          success: true,
          data: serialize_ticket_admin_detail(ticket)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Ticket not found"}
        })
    end
  end

  @doc """
  Updates a ticket (status, priority, assignment).
  PUT /api/admin/support/tickets/:id
  """
  def update(conn, %{"id" => ticket_id, "ticket" => ticket_params}) do
    case Support.update_ticket(ticket_id, ticket_params) do
      {:ok, ticket} ->
        ticket = ticket |> ButtonLog.Repo.preload([:user, :assigned_admin])

        json(conn, %{
          success: true,
          data: serialize_ticket_admin(ticket)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Ticket not found"}
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
  Adds a message to a ticket (with optional internal note flag).
  POST /api/admin/support/tickets/:id/messages
  """
  def add_message(conn, %{"id" => ticket_id, "message" => message_params}) do
    admin = conn.assigns.current_user
    content = Map.get(message_params, "content")
    is_internal = Map.get(message_params, "is_internal", false)

    case Support.get_ticket_admin(ticket_id) do
      {:ok, _ticket} ->
        case Support.add_message(ticket_id, content, admin.id, is_internal: is_internal) do
          {:ok, message} ->
            message = message |> ButtonLog.Repo.preload(:sender)

            conn
            |> put_status(:created)
            |> json(%{
              success: true,
              data: serialize_message_admin(message)
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
    end
  end

  @doc """
  Gets support statistics for the admin dashboard.
  GET /api/admin/support/stats
  """
  def stats(conn, _params) do
    stats = Support.get_stats()

    json(conn, %{
      success: true,
      data: stats,
      meta: %{
        timestamp: DateTime.utc_now()
      }
    })
  end

  # ============================================================================
  # Serialization
  # ============================================================================

  defp serialize_ticket_admin(ticket) do
    %{
      id: ticket.id,
      subject: ticket.subject,
      category: ticket.category,
      priority: ticket.priority,
      status: ticket.status,
      user: serialize_user(ticket.user),
      assigned_admin: serialize_user(ticket.assigned_admin),
      created_at: ticket.inserted_at,
      updated_at: ticket.updated_at
    }
  end

  defp serialize_ticket_admin_detail(ticket) do
    ticket
    |> serialize_ticket_admin()
    |> Map.put(:messages, Enum.map(ticket.messages || [], &serialize_message_admin/1))
  end

  defp serialize_message_admin(message) do
    sender = message.sender

    %{
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: if(sender, do: sender.display_name || sender.username, else: nil),
      sender_is_admin: if(sender, do: sender.is_admin, else: false),
      is_internal: message.is_internal,
      created_at: message.inserted_at,
      read_at: message.read_at
    }
  end

  defp serialize_user(nil), do: nil

  defp serialize_user(user) do
    %{
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      email: user.email,
      is_admin: user.is_admin
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
