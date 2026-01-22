defmodule ButtonLogWeb.API.NotificationControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Notifications
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/notifications" do
    test "returns empty list when no notifications", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/notifications")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "returns user notifications", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender", display_name: "Sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Test Notification", message: "Test message"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/notifications")

      assert %{"success" => true, "data" => [notification]} = json_response(conn, 200)
      assert notification["title"] == "Test Notification"
      assert notification["body"] == "Test message"
      assert notification["type"] == "button_click"
      assert notification["is_read"] == false
    end

    test "returns notifications with sender info", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender", display_name: "Sender Name"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Test", message: "Test message"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/notifications")

      assert %{"success" => true, "data" => [notification]} = json_response(conn, 200)
      assert notification["sender"]["id"] == sender.id
      assert notification["sender"]["username"] == "sender"
      assert notification["sender"]["display_name"] == "Sender Name"
    end

    test "returns notifications with metadata", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Notifications.create_notification(
        %{
          notification_type: "button_click",
          title: "Test",
          message: "Test message",
          metadata: %{"action" => "start", "duration" => 60}
        },
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/notifications")

      assert %{"success" => true, "data" => [notification]} = json_response(conn, 200)
      assert notification["data"]["action"] == "start"
      assert notification["data"]["duration"] == 60
    end

    test "returns multiple notifications ordered by date", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "First", message: "First message"},
        user.id, sender.id, button.id
      )
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Second", message: "Second message"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/notifications")

      assert %{"success" => true, "data" => notifications} = json_response(conn, 200)
      assert length(notifications) == 2
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/notifications")
      assert json_response(conn, 401)
    end

    test "does not return other user's notifications", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Other's Notification", message: "Message"},
        other_user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/notifications")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end
  end

  describe "PUT /api/notifications/:id/read" do
    test "marks notification as read", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, notification} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Test", message: "Test message"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/notifications/#{notification.id}/read")

      assert %{
        "success" => true,
        "data" => %{
          "id" => id,
          "is_read" => true
        }
      } = json_response(conn, 200)

      assert id == notification.id
    end

    test "returns 404 for non-existent notification", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/notifications/#{Ecto.UUID.generate()}/read")

      assert %{
        "success" => false,
        "error" => %{
          "code" => "NOTIFICATION_NOT_FOUND",
          "message" => "Notification not found"
        }
      } = json_response(conn, 404)
    end

    test "returns 404 for another user's notification", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, notification} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Other's Notification", message: "Message"},
        other_user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/notifications/#{notification.id}/read")

      assert %{
        "success" => false,
        "error" => %{"code" => "NOTIFICATION_NOT_FOUND"}
      } = json_response(conn, 404)
    end

    test "requires authentication", %{conn: conn} do
      conn = put(conn, "/api/notifications/#{Ecto.UUID.generate()}/read")
      assert json_response(conn, 401)
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

  defp insert_button(user, attrs) do
    default_attrs = %{
      name: "Test Button",
      type: "instant",
      color: "#3B82F6",
      icon: "star"
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Buttons.Button{}
    |> Ecto.Changeset.cast(attrs, [:name, :type, :color, :icon])
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> ButtonLog.Repo.insert!()
  end
end
