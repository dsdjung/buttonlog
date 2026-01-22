defmodule ButtonLogWeb.API.SupportControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Support
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/support/tickets" do
    test "lists user's tickets", %{conn: conn, user: user, token: token} do
      {:ok, _ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/support/tickets")

      assert %{"success" => true, "data" => tickets} = json_response(conn, 200)
      assert length(tickets) == 1
    end

    test "returns empty list when no tickets", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/support/tickets")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/support/tickets")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/support/tickets" do
    test "creates a ticket", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/support/tickets", %{
          ticket: %{
            subject: "Need help",
            category: "question"
          }
        })

      assert %{"success" => true, "data" => ticket} = json_response(conn, 201)
      assert ticket["subject"] == "Need help"
      assert ticket["category"] == "question"
      assert ticket["status"] == "open"
    end

    test "creates a ticket with initial message", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/support/tickets", %{
          ticket: %{
            subject: "Bug report",
            category: "bug",
            message: "I found a bug!"
          }
        })

      assert %{"success" => true, "data" => ticket} = json_response(conn, 201)
      assert length(ticket["messages"]) == 1
      assert hd(ticket["messages"])["content"] == "I found a bug!"
    end

    test "returns error for invalid data", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/support/tickets", %{
          ticket: %{
            subject: "",
            category: "invalid"
          }
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
    end
  end

  describe "GET /api/support/tickets/:id" do
    test "returns ticket with messages", %{conn: conn, user: user, token: token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)
      {:ok, _message} = Support.add_message(ticket.id, "Hello", user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/support/tickets/#{ticket.id}")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["id"] == ticket.id
      assert length(data["messages"]) == 1
    end

    test "returns 404 for non-existent ticket", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/support/tickets/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end

    test "returns 403 for other user's ticket", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, other_user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/support/tickets/#{ticket.id}")

      assert %{"success" => false, "error" => error} = json_response(conn, 403)
      assert error["code"] == "FORBIDDEN"
    end
  end

  describe "POST /api/support/tickets/:id/messages" do
    test "adds a message to ticket", %{conn: conn, user: user, token: token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/support/tickets/#{ticket.id}/messages", %{
          message: %{content: "Follow up message"}
        })

      assert %{"success" => true, "data" => message} = json_response(conn, 201)
      assert message["content"] == "Follow up message"
    end

    test "returns error for empty message", %{conn: conn, user: user, token: token} do
      {:ok, ticket} = Support.create_ticket(%{subject: "Test", category: "bug"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/support/tickets/#{ticket.id}/messages", %{
          message: %{content: ""}
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
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
end
