defmodule ButtonLogWeb.API.ButtonControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Buttons
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/buttons" do
    test "lists user's buttons", %{conn: conn, user: user, token: token} do
      {:ok, _button} = Buttons.create_button(%{name: "Test Button", type: "instant"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons")

      assert %{"success" => true, "data" => buttons} = json_response(conn, 200)
      assert length(buttons) == 1
      assert hd(buttons)["name"] == "Test Button"
    end

    test "returns empty list when no buttons", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/buttons")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/buttons" do
    test "creates an instant button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons", %{
          button: %{
            name: "New Button",
            type: "instant",
            icon: "star",
            color: "#00BFA5"
          }
        })

      assert %{"success" => true, "data" => button} = json_response(conn, 201)
      assert button["name"] == "New Button"
      assert button["type"] == "instant"
      assert button["icon"] == "star"
      assert button["color"] == "#00BFA5"
      assert button["current_state"] == "idle"
    end

    test "creates a toggle button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons", %{
          button: %{
            name: "Toggle Button",
            type: "toggle"
          }
        })

      assert %{"success" => true, "data" => button} = json_response(conn, 201)
      assert button["type"] == "toggle"
    end

    test "creates a one-time button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons", %{
          button: %{
            name: "One-Time Button",
            type: "one-time"
          }
        })

      assert %{"success" => true, "data" => button} = json_response(conn, 201)
      assert button["type"] == "one-time"
    end

    test "returns error for invalid data", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons", %{
          button: %{
            name: "",
            type: "invalid"
          }
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
    end

    test "returns error for invalid color format", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons", %{
          button: %{
            name: "Button",
            type: "instant",
            color: "invalid"
          }
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
    end
  end

  describe "GET /api/buttons/:id" do
    test "returns the button", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "Test", type: "instant"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons/#{button.id}")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["id"] == button.id
      assert data["name"] == "Test"
    end

    test "returns 404 for non-existent button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end

    test "returns 404 for another user's button", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, button} = Buttons.create_button(%{name: "Other's Button", type: "instant"}, other_user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons/#{button.id}")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end
  end

  describe "PUT /api/buttons/:id" do
    test "updates the button", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "Original", type: "instant"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/buttons/#{button.id}", %{
          button: %{name: "Updated", description: "New description"}
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["name"] == "Updated"
      assert data["description"] == "New description"
    end

    test "returns 404 for non-existent button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/buttons/#{Ecto.UUID.generate()}", %{
          button: %{name: "Updated"}
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end

    test "returns 404 when updating another user's button", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other2@test.com", username: "other2"})
      {:ok, button} = Buttons.create_button(%{name: "Other's Button", type: "instant"}, other_user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/buttons/#{button.id}", %{
          button: %{name: "Hacked"}
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end
  end

  describe "DELETE /api/buttons/:id" do
    test "deletes the button", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "To Delete", type: "instant"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/buttons/#{button.id}")

      # 204 No Content has no body
      assert response(conn, 204)

      # Verify it's deleted
      assert {:error, :not_found} = Buttons.get_button(button.id, user.id)
    end

    test "returns 404 for non-existent button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/buttons/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end
  end

  describe "POST /api/buttons/:id/click" do
    test "clicks an instant button", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "Click Me", type: "instant"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons/#{button.id}/click")

      assert %{"success" => true, "data" => click} = json_response(conn, 200)
      assert click["button_id"] == button.id
      assert click["action"] == "click"
    end

    test "starts a toggle button", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "Toggle", type: "toggle"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons/#{button.id}/click")

      assert %{"success" => true, "data" => click} = json_response(conn, 200)
      assert click["action"] == "start"
    end

    test "stops a toggle button", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "Toggle", type: "toggle"}, user.id)

      # First start it
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/buttons/#{button.id}/click")

      # Then stop it
      conn2 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons/#{button.id}/click")

      assert %{"success" => true, "data" => click} = json_response(conn2, 200)
      assert click["action"] == "end"
    end

    test "returns error for non-existent button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/buttons/#{Ecto.UUID.generate()}/click")

      # Returns 403 NOT_AUTHORIZED to not reveal button existence
      assert %{"success" => false, "error" => error} = json_response(conn, 403)
      assert error["code"] == "NOT_AUTHORIZED"
    end
  end

  describe "GET /api/buttons/:id/history" do
    test "returns click history", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "History", type: "instant"}, user.id)

      # Create some clicks
      {:ok, _} = Buttons.click_button(button.id, user.id)
      {:ok, _} = Buttons.click_button(button.id, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons/#{button.id}/history")

      assert %{"success" => true, "data" => clicks, "meta" => meta} = json_response(conn, 200)
      assert length(clicks) == 2
      assert meta["count"] == 2
    end

    test "returns empty list for button with no clicks", %{conn: conn, user: user, token: token} do
      {:ok, button} = Buttons.create_button(%{name: "No Clicks", type: "instant"}, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons/#{button.id}/history")

      assert %{"success" => true, "data" => [], "meta" => %{"count" => 0}} = json_response(conn, 200)
    end

    test "returns 404 for non-existent button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/buttons/#{Ecto.UUID.generate()}/history")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "NOT_FOUND"
    end
  end

  # Helper functions
  defp insert_user(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    default_attrs = %{
      email: "test#{unique_id}@test.com",
      username: "testuser#{unique_id}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123!")
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash])
    |> ButtonLog.Repo.insert!()
  end
end
