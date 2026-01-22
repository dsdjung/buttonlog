defmodule ButtonLog.Support do
  @moduledoc """
  The Support context for handling support tickets and messages.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Support.{Ticket, TicketMessage}

  # ============================================================================
  # User Functions
  # ============================================================================

  @doc """
  Creates a new support ticket for a user.
  """
  def create_ticket(attrs, user_id) do
    %Ticket{}
    |> Ticket.create_changeset(attrs, user_id)
    |> Repo.insert()
  end

  @doc """
  Creates a ticket with an initial message.
  """
  def create_ticket_with_message(attrs, message_content, user_id) do
    Repo.transaction(fn ->
      case create_ticket(attrs, user_id) do
        {:ok, ticket} ->
          case add_message(ticket.id, message_content, user_id) do
            {:ok, _message} -> ticket |> Repo.preload(:messages)
            {:error, reason} -> Repo.rollback(reason)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Adds a message to a ticket.
  """
  def add_message(ticket_id, content, sender_id, opts \\ []) do
    %TicketMessage{}
    |> TicketMessage.create_changeset(%{content: content}, ticket_id, sender_id, opts)
    |> Repo.insert()
  end

  @doc """
  Lists all tickets for a user.
  """
  def list_user_tickets(user_id) do
    Ticket
    |> where([t], t.user_id == ^user_id)
    |> order_by([t], desc: t.updated_at)
    |> preload([:assigned_admin])
    |> Repo.all()
    |> Enum.map(&add_unread_count(&1, user_id))
  end

  @doc """
  Gets a ticket by ID, verifying ownership.
  Returns {:ok, ticket} or {:error, :not_found} or {:error, :unauthorized}
  """
  def get_ticket(ticket_id, user_id) do
    case Repo.get(Ticket, ticket_id) do
      nil ->
        {:error, :not_found}

      ticket ->
        if ticket.user_id == user_id do
          ticket =
            ticket
            |> Repo.preload([
              :assigned_admin,
              messages: {from(m in TicketMessage, where: m.is_internal == false, order_by: m.inserted_at), [:sender]}
            ])
            |> add_unread_count(user_id)

          {:ok, ticket}
        else
          {:error, :unauthorized}
        end
    end
  end

  @doc """
  Marks all unread messages in a ticket as read for a user.
  """
  def mark_ticket_messages_read(ticket_id, user_id) do
    from(m in TicketMessage,
      where: m.ticket_id == ^ticket_id,
      where: m.sender_id != ^user_id,
      where: is_nil(m.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now() |> DateTime.truncate(:second)])
  end

  @doc """
  Counts tickets with unread messages for a user.
  """
  def count_unread_tickets(user_id) do
    from(t in Ticket,
      as: :ticket,
      where: t.user_id == ^user_id,
      where:
        exists(
          from(m in TicketMessage,
            where: m.ticket_id == parent_as(:ticket).id,
            where: m.sender_id != ^user_id,
            where: is_nil(m.read_at)
          )
        )
    )
    |> Repo.aggregate(:count)
  end

  # ============================================================================
  # Admin Functions
  # ============================================================================

  @doc """
  Lists all tickets with optional filters.
  Filters: status, category, priority, assigned_admin_id, search
  """
  def list_all_tickets(filters \\ %{}) do
    Ticket
    |> apply_filters(filters)
    |> order_by([t], desc: t.updated_at)
    |> preload([:user, :assigned_admin])
    |> Repo.all()
  end

  @doc """
  Gets a ticket by ID for admin (no ownership check).
  Includes all messages (including internal notes).
  """
  def get_ticket_admin(ticket_id) do
    case Repo.get(Ticket, ticket_id) do
      nil ->
        {:error, :not_found}

      ticket ->
        ticket =
          ticket
          |> Repo.preload([
            :user,
            :assigned_admin,
            messages: from(m in TicketMessage, order_by: m.inserted_at, preload: [:sender])
          ])

        {:ok, ticket}
    end
  end

  @doc """
  Updates ticket status.
  """
  def update_ticket_status(ticket_id, status) do
    case Repo.get(Ticket, ticket_id) do
      nil ->
        {:error, :not_found}

      ticket ->
        ticket
        |> Ticket.update_status_changeset(status)
        |> Repo.update()
    end
  end

  @doc """
  Updates ticket priority.
  """
  def update_ticket_priority(ticket_id, priority) do
    case Repo.get(Ticket, ticket_id) do
      nil ->
        {:error, :not_found}

      ticket ->
        ticket
        |> Ticket.changeset(%{priority: priority})
        |> Repo.update()
    end
  end

  @doc """
  Assigns a ticket to an admin.
  """
  def assign_ticket(ticket_id, admin_id) do
    case Repo.get(Ticket, ticket_id) do
      nil ->
        {:error, :not_found}

      ticket ->
        ticket
        |> Ticket.assign_changeset(admin_id)
        |> Repo.update()
    end
  end

  @doc """
  Unassigns a ticket.
  """
  def unassign_ticket(ticket_id) do
    assign_ticket(ticket_id, nil)
  end

  @doc """
  Updates multiple ticket fields at once (for admin).
  """
  def update_ticket(ticket_id, attrs) do
    case Repo.get(Ticket, ticket_id) do
      nil ->
        {:error, :not_found}

      ticket ->
        ticket
        |> Ticket.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Gets support statistics for admin dashboard.
  """
  def get_stats do
    total = Repo.aggregate(Ticket, :count)
    open = Repo.aggregate(from(t in Ticket, where: t.status == "open"), :count)
    in_progress = Repo.aggregate(from(t in Ticket, where: t.status == "in_progress"), :count)
    resolved = Repo.aggregate(from(t in Ticket, where: t.status == "resolved"), :count)
    closed = Repo.aggregate(from(t in Ticket, where: t.status == "closed"), :count)
    unassigned = Repo.aggregate(from(t in Ticket, where: is_nil(t.assigned_admin_id), where: t.status in ["open", "in_progress"]), :count)
    high_priority = Repo.aggregate(from(t in Ticket, where: t.priority in ["high", "urgent"], where: t.status in ["open", "in_progress"]), :count)

    # Category breakdown
    categories =
      from(t in Ticket, group_by: t.category, select: {t.category, count(t.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: total,
      open: open,
      in_progress: in_progress,
      resolved: resolved,
      closed: closed,
      unassigned: unassigned,
      high_priority: high_priority,
      by_category: categories
    }
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  @valid_statuses ~w(open in_progress resolved closed)
  @valid_categories ~w(bug feature_request question other)
  @valid_priorities ~w(low normal high urgent)

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query when status in @valid_statuses ->
        where(query, [t], t.status == ^status)

      {:category, category}, query when category in @valid_categories ->
        where(query, [t], t.category == ^category)

      {:priority, priority}, query when priority in @valid_priorities ->
        where(query, [t], t.priority == ^priority)

      {:assigned_admin_id, nil}, query ->
        where(query, [t], is_nil(t.assigned_admin_id))

      {:assigned_admin_id, admin_id}, query ->
        where(query, [t], t.assigned_admin_id == ^admin_id)

      {:search, search}, query when is_binary(search) and search != "" ->
        search_term = "%#{search}%"
        where(query, [t], ilike(t.subject, ^search_term))

      _, query ->
        query
    end)
  end

  defp add_unread_count(ticket, user_id) do
    unread_count =
      from(m in TicketMessage,
        where: m.ticket_id == ^ticket.id,
        where: m.sender_id != ^user_id,
        where: is_nil(m.read_at),
        where: m.is_internal == false
      )
      |> Repo.aggregate(:count)

    Map.put(ticket, :unread_count, unread_count)
  end

  # ============================================================================
  # Notification Functions
  # ============================================================================

  @doc """
  Sends a notification when an admin replies to a ticket.
  Only sends for non-internal messages.
  """
  def notify_ticket_reply(ticket_id, admin_id) do
    with {:ok, ticket} <- get_ticket_admin(ticket_id),
         false <- is_nil(ticket.user_id) do
      admin = ButtonLog.Accounts.get_user!(admin_id)

      notification_attrs = %{
        alert_type: "support_ticket_reply",
        title: "New reply on your support ticket",
        message: "Support team replied to: #{ticket.subject}",
        metadata: %{
          ticket_id: ticket_id,
          ticket_subject: ticket.subject
        }
      }

      # Create in-app alert (sender_id is admin, button_id is nil for support)
      ButtonLog.Alerts.create_alert(
        notification_attrs,
        ticket.user_id,
        admin_id,
        nil
      )

      # Broadcast via WebSocket for real-time update
      ButtonLogWeb.Endpoint.broadcast(
        "user:#{ticket.user_id}",
        "alert_received",
        %{
          type: "support_ticket_reply",
          title: notification_attrs.title,
          message: notification_attrs.message,
          ticket_id: ticket_id,
          sender_id: admin_id,
          sender_name: admin.display_name || admin.username
        }
      )

      :ok
    else
      _ -> :error
    end
  end

  @doc """
  Sends an alert when ticket status is updated.
  """
  def notify_ticket_status_update(ticket_id, new_status) do
    with {:ok, ticket} <- get_ticket_admin(ticket_id),
         false <- is_nil(ticket.user_id) do
      status_display = status_display_name(new_status)

      notification_attrs = %{
        alert_type: "support_ticket_status_update",
        title: "Ticket status updated",
        message: "Your ticket \"#{ticket.subject}\" is now #{status_display}",
        metadata: %{
          ticket_id: ticket_id,
          ticket_subject: ticket.subject,
          new_status: new_status
        }
      }

      # Create in-app alert (no sender for system updates)
      ButtonLog.Alerts.create_alert(
        notification_attrs,
        ticket.user_id,
        nil,
        nil
      )

      # Broadcast via WebSocket for real-time update
      ButtonLogWeb.Endpoint.broadcast(
        "user:#{ticket.user_id}",
        "alert_received",
        %{
          type: "support_ticket_status_update",
          title: notification_attrs.title,
          message: notification_attrs.message,
          ticket_id: ticket_id,
          new_status: new_status
        }
      )

      :ok
    else
      _ -> :error
    end
  end

  defp status_display_name("open"), do: "Open"
  defp status_display_name("in_progress"), do: "In Progress"
  defp status_display_name("resolved"), do: "Resolved"
  defp status_display_name("closed"), do: "Closed"
  defp status_display_name(status), do: status
end
