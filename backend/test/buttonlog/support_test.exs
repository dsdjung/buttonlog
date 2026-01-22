defmodule ButtonLog.SupportTest do
  use ButtonLog.DataCase

  alias ButtonLog.Support
  alias ButtonLog.Support.TicketMessage

  describe "create_ticket/2" do
    test "creates a ticket with valid attributes" do
      user = insert_user()

      attrs = %{
        subject: "Test ticket",
        category: "bug"
      }

      assert {:ok, ticket} = Support.create_ticket(attrs, user.id)
      assert ticket.subject == "Test ticket"
      assert ticket.category == "bug"
      assert ticket.priority == "normal"
      assert ticket.status == "open"
      assert ticket.user_id == user.id
    end

    test "creates a ticket with priority" do
      user = insert_user()

      attrs = %{
        subject: "Urgent issue",
        category: "bug",
        priority: "urgent"
      }

      assert {:ok, ticket} = Support.create_ticket(attrs, user.id)
      assert ticket.priority == "urgent"
    end

    test "fails with invalid category" do
      user = insert_user()

      attrs = %{
        subject: "Test",
        category: "invalid_category"
      }

      assert {:error, changeset} = Support.create_ticket(attrs, user.id)
      assert "is invalid" in errors_on(changeset).category
    end

    test "fails without required fields" do
      user = insert_user()

      assert {:error, changeset} = Support.create_ticket(%{}, user.id)
      assert "can't be blank" in errors_on(changeset).subject
      assert "can't be blank" in errors_on(changeset).category
    end
  end

  describe "create_ticket_with_message/3" do
    test "creates a ticket with initial message" do
      user = insert_user()

      attrs = %{
        subject: "Need help",
        category: "question"
      }

      assert {:ok, ticket} = Support.create_ticket_with_message(attrs, "Hello, I need help!", user.id)
      assert ticket.subject == "Need help"
      assert length(ticket.messages) == 1
      assert hd(ticket.messages).content == "Hello, I need help!"
    end
  end

  describe "add_message/3" do
    test "adds a message to a ticket" do
      user = insert_user()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:ok, message} = Support.add_message(ticket.id, "This is my message", user.id)
      assert message.content == "This is my message"
      assert message.sender_id == user.id
      assert message.is_internal == false
    end

    test "admin can add internal note" do
      user = insert_user()
      admin = insert_admin()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:ok, message} = Support.add_message(ticket.id, "Internal note", admin.id, is_internal: true)
      assert message.is_internal == true
    end

    test "fails with empty content" do
      user = insert_user()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:error, changeset} = Support.add_message(ticket.id, "", user.id)
      assert "can't be blank" in errors_on(changeset).content
    end
  end

  describe "list_user_tickets/1" do
    test "returns only user's tickets" do
      user1 = insert_user()
      user2 = insert_user(%{email: "user2@test.com", username: "user2"})

      {:ok, ticket1} = Support.create_ticket(%{subject: "User1 ticket", category: "bug"}, user1.id)
      {:ok, _ticket2} = Support.create_ticket(%{subject: "User2 ticket", category: "bug"}, user2.id)

      tickets = Support.list_user_tickets(user1.id)
      assert length(tickets) == 1
      assert hd(tickets).id == ticket1.id
    end

    test "returns multiple tickets" do
      user = insert_user()

      {:ok, _ticket1} = Support.create_ticket(%{subject: "First", category: "bug"}, user.id)
      {:ok, _ticket2} = Support.create_ticket(%{subject: "Second", category: "bug"}, user.id)

      tickets = Support.list_user_tickets(user.id)
      # Should return both tickets
      assert length(tickets) == 2
    end
  end

  describe "get_ticket/2" do
    test "returns ticket for owner" do
      user = insert_user()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:ok, found} = Support.get_ticket(ticket.id, user.id)
      assert found.id == ticket.id
    end

    test "returns not_found for non-existent ticket" do
      user = insert_user()

      assert {:error, :not_found} = Support.get_ticket(Ecto.UUID.generate(), user.id)
    end

    test "returns unauthorized for other user's ticket" do
      user1 = insert_user()
      user2 = insert_user(%{email: "user2@test.com", username: "user2"})
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user1.id)

      assert {:error, :unauthorized} = Support.get_ticket(ticket.id, user2.id)
    end

    test "filters out internal messages for regular users" do
      user = insert_user()
      admin = insert_admin()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      Support.add_message(ticket.id, "User message", user.id)
      Support.add_message(ticket.id, "Admin reply", admin.id)
      Support.add_message(ticket.id, "Internal note", admin.id, is_internal: true)

      {:ok, found} = Support.get_ticket(ticket.id, user.id)
      assert length(found.messages) == 2
      refute Enum.any?(found.messages, & &1.is_internal)
    end
  end

  describe "list_all_tickets/1 (admin)" do
    test "returns all tickets" do
      user1 = insert_user()
      user2 = insert_user(%{email: "user2@test.com", username: "user2"})

      {:ok, _} = Support.create_ticket(%{subject: "Ticket 1", category: "bug"}, user1.id)
      {:ok, _} = Support.create_ticket(%{subject: "Ticket 2", category: "question"}, user2.id)

      tickets = Support.list_all_tickets(%{})
      assert length(tickets) == 2
    end

    test "filters by status" do
      user = insert_user()
      {:ok, ticket1} = Support.create_ticket(%{subject: "Open", category: "bug"}, user.id)
      {:ok, _} = Support.create_ticket(%{subject: "Closed", category: "bug"}, user.id)
      Support.update_ticket_status(ticket1.id, "in_progress")

      tickets = Support.list_all_tickets(%{status: "in_progress"})
      assert length(tickets) == 1
      assert hd(tickets).status == "in_progress"
    end

    test "filters by category" do
      user = insert_user()
      {:ok, _} = Support.create_ticket(%{subject: "Bug", category: "bug"}, user.id)
      {:ok, _} = Support.create_ticket(%{subject: "Feature", category: "feature_request"}, user.id)

      tickets = Support.list_all_tickets(%{category: "bug"})
      assert length(tickets) == 1
      assert hd(tickets).category == "bug"
    end

    test "filters by priority" do
      user = insert_user()
      {:ok, _} = Support.create_ticket(%{subject: "Normal", category: "bug", priority: "normal"}, user.id)
      {:ok, _} = Support.create_ticket(%{subject: "Urgent", category: "bug", priority: "urgent"}, user.id)

      tickets = Support.list_all_tickets(%{priority: "urgent"})
      assert length(tickets) == 1
      assert hd(tickets).priority == "urgent"
    end
  end

  describe "update_ticket_status/2" do
    test "updates ticket status" do
      user = insert_user()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:ok, updated} = Support.update_ticket_status(ticket.id, "in_progress")
      assert updated.status == "in_progress"
    end

    test "fails with invalid status" do
      user = insert_user()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:error, changeset} = Support.update_ticket_status(ticket.id, "invalid_status")
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "assign_ticket/2" do
    test "assigns ticket to admin" do
      user = insert_user()
      admin = insert_admin()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      assert {:ok, updated} = Support.assign_ticket(ticket.id, admin.id)
      assert updated.assigned_admin_id == admin.id
    end

    test "unassigns ticket with nil" do
      user = insert_user()
      admin = insert_admin()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)
      {:ok, assigned} = Support.assign_ticket(ticket.id, admin.id)

      assert {:ok, unassigned} = Support.assign_ticket(assigned.id, nil)
      assert unassigned.assigned_admin_id == nil
    end
  end

  describe "get_ticket_admin/1" do
    test "returns ticket with all messages including internal" do
      user = insert_user()
      admin = insert_admin()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      Support.add_message(ticket.id, "User message", user.id)
      Support.add_message(ticket.id, "Internal note", admin.id, is_internal: true)

      {:ok, found} = Support.get_ticket_admin(ticket.id)
      assert length(found.messages) == 2
      assert Enum.any?(found.messages, & &1.is_internal)
    end
  end

  describe "get_stats/0" do
    test "returns correct stats" do
      user = insert_user()
      admin = insert_admin()

      {:ok, ticket1} = Support.create_ticket(%{subject: "Open 1", category: "bug"}, user.id)
      {:ok, _ticket2} = Support.create_ticket(%{subject: "Open 2", category: "question", priority: "high"}, user.id)
      {:ok, ticket3} = Support.create_ticket(%{subject: "In Progress", category: "feature_request"}, user.id)

      Support.update_ticket_status(ticket3.id, "in_progress")
      Support.assign_ticket(ticket1.id, admin.id)

      stats = Support.get_stats()

      assert stats.open == 2
      assert stats.in_progress == 1
      assert stats.unassigned == 2
      assert stats.high_priority == 1
      assert stats.by_category["bug"] == 1
      assert stats.by_category["question"] == 1
      assert stats.by_category["feature_request"] == 1
    end
  end

  describe "mark_ticket_messages_read/2" do
    test "marks unread messages as read" do
      user = insert_user()
      admin = insert_admin()
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      {:ok, message1} = Support.add_message(ticket.id, "User message", user.id)
      {:ok, message2} = Support.add_message(ticket.id, "Admin reply", admin.id)

      # Initially unread
      assert Repo.get!(TicketMessage, message1.id).read_at == nil
      assert Repo.get!(TicketMessage, message2.id).read_at == nil

      # Mark as read for user (should only mark admin's message)
      Support.mark_ticket_messages_read(ticket.id, user.id)

      # User's own message shouldn't be marked read by themselves
      # But admin's message should be marked read
      updated_message2 = Repo.get!(TicketMessage, message2.id)
      assert updated_message2.read_at != nil
    end
  end

  # Helper functions
  defp insert_user(attrs \\ %{}) do
    default_attrs = %{
      email: "test#{System.unique_integer()}@test.com",
      username: "testuser#{System.unique_integer()}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      is_admin: false
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash, :is_admin])
    |> ButtonLog.Repo.insert!()
  end

  defp insert_admin(attrs \\ %{}) do
    insert_user(Map.merge(%{
      email: "admin#{System.unique_integer()}@test.com",
      username: "admin#{System.unique_integer()}",
      is_admin: true
    }, attrs))
  end
end
