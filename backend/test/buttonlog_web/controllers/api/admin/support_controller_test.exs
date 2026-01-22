defmodule ButtonLogWeb.API.Admin.SupportControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Support
  alias ButtonLog.Auth.Token

  setup do
    admin = insert_admin()
    user = insert_user()
    admin_token = Token.create_token(admin.id)
    user_token = Token.create_token(user.id)
    {:ok, admin: admin, user: user, admin_token: admin_token, user_token: user_token}
  end

  describe "GET /api/admin/support/tickets" do
    test "lists all tickets for admin", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, _ticket1} = Support.create_ticket(%{subject: "Bug", category: "bug"}, user.id)
      {:ok, _ticket2} = Support.create_ticket(%{subject: "Feature", category: "feature_request"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> get("/api/admin/support/tickets")

      assert %{"success" => true, "data" => tickets} = json_response(conn, 200)
      assert length(tickets) == 2
    end

    test "filters by status", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, ticket1} = Support.create_ticket(%{subject: "Open", category: "bug"}, user.id)
      {:ok, _ticket2} = Support.create_ticket(%{subject: "Other", category: "bug"}, user.id)
      Support.update_ticket_status(ticket1.id, "in_progress")

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> get("/api/admin/support/tickets", %{status: "in_progress"})

      assert %{"success" => true, "data" => tickets} = json_response(conn, 200)
      assert length(tickets) == 1
      assert hd(tickets)["status"] == "in_progress"
    end

    test "returns 403 for non-admin", %{conn: conn, user_token: user_token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{user_token}")
        |> get("/api/admin/support/tickets")

      assert %{"success" => false, "error" => error} = json_response(conn, 403)
      assert error["code"] == "FORBIDDEN"
    end
  end

  describe "GET /api/admin/support/tickets/:id" do
    test "returns ticket with internal messages for admin", %{conn: conn, admin: admin, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)
      {:ok, _} = Support.add_message(ticket.id, "User message", user.id)
      {:ok, _} = Support.add_message(ticket.id, "Internal note", admin.id, is_internal: true)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> get("/api/admin/support/tickets/#{ticket.id}")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert length(data["messages"]) == 2
      assert Enum.any?(data["messages"], & &1["is_internal"])
    end

    test "returns 404 for non-existent ticket", %{conn: conn, admin_token: admin_token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> get("/api/admin/support/tickets/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end
  end

  describe "PUT /api/admin/support/tickets/:id" do
    test "updates ticket status", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> put("/api/admin/support/tickets/#{ticket.id}", %{
          ticket: %{status: "in_progress"}
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["status"] == "in_progress"
    end

    test "updates ticket priority", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> put("/api/admin/support/tickets/#{ticket.id}", %{
          ticket: %{priority: "urgent"}
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["priority"] == "urgent"
    end

    test "assigns ticket to admin", %{conn: conn, admin: admin, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> put("/api/admin/support/tickets/#{ticket.id}", %{
          ticket: %{assigned_admin_id: admin.id}
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["assigned_admin"]["id"] == admin.id
    end

    test "returns error for invalid status", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> put("/api/admin/support/tickets/#{ticket.id}", %{
          ticket: %{status: "invalid_status"}
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
    end
  end

  describe "POST /api/admin/support/tickets/:id/messages" do
    test "adds a reply to ticket", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> post("/api/admin/support/tickets/#{ticket.id}/messages", %{
          message: %{content: "Admin reply"}
        })

      assert %{"success" => true, "data" => message} = json_response(conn, 201)
      assert message["content"] == "Admin reply"
      assert message["sender_is_admin"] == true
    end

    test "adds an internal note", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> post("/api/admin/support/tickets/#{ticket.id}/messages", %{
          message: %{content: "Internal note", is_internal: true}
        })

      assert %{"success" => true, "data" => message} = json_response(conn, 201)
      assert message["is_internal"] == true
    end
  end

  describe "GET /api/admin/support/stats" do
    test "returns support statistics", %{conn: conn, user: user, admin_token: admin_token} do
      {:ok, _ticket1} = Support.create_ticket(%{subject: "Open", category: "bug"}, user.id)
      {:ok, _ticket2} = Support.create_ticket(%{subject: "Question", category: "question", priority: "high"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{admin_token}")
        |> get("/api/admin/support/stats")

      assert %{"success" => true, "data" => stats} = json_response(conn, 200)
      assert stats["open"] == 2
      assert stats["high_priority"] == 1
      assert stats["by_category"]["bug"] == 1
      assert stats["by_category"]["question"] == 1
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
