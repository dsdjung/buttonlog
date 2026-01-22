defmodule ButtonLogWeb.API.AlertControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Alerts
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/alerts" do
    test "lists user's alerts with pagination", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 1", message: "Test message 1"},
        user.id, sender.id, button.id
      )
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 2", message: "Test message 2"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts")

      assert %{
        "success" => true,
        "data" => alerts,
        "pagination" => %{"has_more" => false, "offset" => 0, "limit" => 50}
      } = json_response(conn, 200)

      assert length(alerts) == 2
    end

    test "returns empty list when no alerts", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "respects limit parameter", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      for i <- 1..5 do
        {:ok, _} = Alerts.create_alert(
          %{alert_type: "button_click", title: "Alert #{i}", message: "Test message #{i}"},
          user.id, sender.id, button.id
        )
      end

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts", %{"limit" => "2"})

      assert %{
        "success" => true,
        "data" => alerts,
        "pagination" => %{"has_more" => true, "limit" => 2}
      } = json_response(conn, 200)

      assert length(alerts) == 2
    end

    test "respects offset parameter", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      for i <- 1..5 do
        {:ok, _} = Alerts.create_alert(
          %{alert_type: "button_click", title: "Alert #{i}", message: "Test message #{i}"},
          user.id, sender.id, button.id
        )
      end

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts", %{"offset" => "2", "limit" => "10"})

      assert %{"success" => true, "data" => alerts} = json_response(conn, 200)
      assert length(alerts) == 3
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/alerts")
      assert json_response(conn, 401)
    end

    test "returns formatted alert data", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender", display_name: "Sender Name"})
      button = insert_button(sender, %{name: "My Button"})

      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test Title", message: "Test Body", metadata: %{"key" => "value"}},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts")

      assert %{"success" => true, "data" => [alert]} = json_response(conn, 200)
      assert alert["title"] == "Test Title"
      assert alert["body"] == "Test Body"
      assert alert["type"] == "button_click"
      assert alert["read"] == false
      assert alert["metadata"] == %{"key" => "value"}
      assert alert["sender"]["username"] == "sender"
      assert alert["sender"]["display_name"] == "Sender Name"
      assert alert["button"]["name"] == "My Button"
    end
  end

  describe "GET /api/alerts/unread/count" do
    test "returns unread count", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 1", message: "Test"},
        user.id, sender.id, button.id
      )
      {:ok, alert2} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 2", message: "Test"},
        user.id, sender.id, button.id
      )

      # Mark one as read
      {:ok, _} = Alerts.mark_alert_read(alert2.id, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts/unread/count")

      assert %{"success" => true, "data" => %{"count" => 1}} = json_response(conn, 200)
    end

    test "returns 0 when all read", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts/unread/count")

      assert %{"success" => true, "data" => %{"count" => 0}} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/alerts/unread/count")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/alerts/unread" do
    test "returns only unread alerts", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Unread Alert", message: "Test"},
        user.id, sender.id, button.id
      )
      {:ok, alert2} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Read Alert", message: "Test"},
        user.id, sender.id, button.id
      )

      # Mark one as read
      {:ok, _} = Alerts.mark_alert_read(alert2.id, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts/unread")

      assert %{"success" => true, "data" => alerts} = json_response(conn, 200)
      assert length(alerts) == 1
      assert hd(alerts)["title"] == "Unread Alert"
    end

    test "returns empty list when all read", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts/unread")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/alerts/unread")
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/alerts/:id/read" do
    test "marks alert as read", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test Alert", message: "Test"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/alerts/#{alert.id}/read")

      assert %{"success" => true, "data" => %{"id" => id, "read" => true}} = json_response(conn, 200)
      assert id == alert.id
    end

    test "returns 404 for non-existent alert", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/alerts/#{Ecto.UUID.generate()}/read")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "ALERT_NOT_FOUND"
    end

    test "returns 404 for another user's alert", %{conn: conn, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test Alert", message: "Test"},
        other_user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/alerts/#{alert.id}/read")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "ALERT_NOT_FOUND"
    end

    test "requires authentication", %{conn: conn} do
      conn = put(conn, "/api/alerts/#{Ecto.UUID.generate()}/read")
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/alerts/read-all" do
    test "marks all alerts as read", %{conn: conn, user: user, token: token} do
      sender = insert_user(%{email: "sender@test.com", username: "sender"})
      button = insert_button(sender, %{name: "Test Button"})

      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 1", message: "Test"},
        user.id, sender.id, button.id
      )
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 2", message: "Test"},
        user.id, sender.id, button.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/alerts/read-all")

      assert %{"success" => true, "data" => %{"marked_count" => 2}} = json_response(conn, 200)

      # Verify all are marked read
      assert Alerts.count_unread_alerts(user.id) == 0
    end

    test "returns 0 when no unread alerts", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/alerts/read-all")

      assert %{"success" => true, "data" => %{"marked_count" => 0}} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = put(conn, "/api/alerts/read-all")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/alerts/from/:friend_id" do
    test "returns alerts from specific friend", %{conn: conn, user: user, token: token} do
      sender1 = insert_user(%{email: "sender1@test.com", username: "sender1"})
      sender2 = insert_user(%{email: "sender2@test.com", username: "sender2"})
      button1 = insert_button(sender1, %{name: "Button 1"})
      button2 = insert_button(sender2, %{name: "Button 2"})

      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "From Sender 1", message: "Test"},
        user.id, sender1.id, button1.id
      )
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "From Sender 2", message: "Test"},
        user.id, sender2.id, button2.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts/from/#{sender1.id}")

      assert %{"success" => true, "data" => alerts} = json_response(conn, 200)
      assert length(alerts) == 1
      assert hd(alerts)["title"] == "From Sender 1"
    end

    test "returns empty list when no alerts from friend", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/alerts/from/#{other_user.id}")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/alerts/from/#{Ecto.UUID.generate()}")
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
