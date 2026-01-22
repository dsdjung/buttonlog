defmodule ButtonLogWeb.API.MobileControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Mobile
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "POST /api/devices/register" do
    test "registers a new device", %{conn: conn, token: token} do
      device_token = "test_device_token_#{System.unique_integer()}"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/devices/register", %{
          "device_token" => device_token,
          "platform" => "android",
          "app_version" => "1.0.0",
          "os_version" => "14.0"
        })

      assert %{
        "success" => true,
        "data" => %{
          "device_token" => ^device_token,
          "platform" => "android",
          "is_active" => true
        }
      } = json_response(conn, 200)
    end

    test "registers an iphone device", %{conn: conn, token: token} do
      device_token = "test_iphone_token_#{System.unique_integer()}"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/devices/register", %{
          "device_token" => device_token,
          "platform" => "iphone"
        })

      assert %{"success" => true, "data" => %{"platform" => "iphone"}} = json_response(conn, 200)
    end

    test "updates existing device registration", %{conn: conn, user: user, token: token} do
      device_token = "existing_token_#{System.unique_integer()}"

      # First registration
      {:ok, _} = Mobile.create_connection(
        %{device_token: device_token, platform: "android", app_version: "1.0.0"},
        user.id
      )

      # Update via API
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/devices/register", %{
          "device_token" => device_token,
          "platform" => "android",
          "app_version" => "2.0.0"
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["device_token"] == device_token
    end

    test "returns error for invalid platform", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/devices/register", %{
          "device_token" => "test_token",
          "platform" => "invalid_platform"
        })

      assert %{
        "success" => false,
        "error" => %{
          "code" => "VALIDATION_ERROR",
          "message" => "Failed to register device"
        }
      } = json_response(conn, 422)
    end

    test "returns error when device_token is missing", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/devices/register", %{
          "platform" => "android"
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
    end

    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/api/devices/register", %{
        "device_token" => "test",
        "platform" => "android"
      })
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/devices/unregister" do
    test "unregisters a device", %{conn: conn, user: user, token: token} do
      device_token = "unregister_token_#{System.unique_integer()}"

      # First register
      {:ok, _} = Mobile.create_connection(
        %{device_token: device_token, platform: "android"},
        user.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/devices/unregister", %{"device_token" => device_token})

      assert %{
        "success" => true,
        "data" => %{"message" => "Device unregistered successfully"}
      } = json_response(conn, 200)

      # Verify device is deactivated
      connection = Mobile.get_connection_by_token(device_token)
      assert connection.is_active == false
    end

    test "returns 404 for non-existent device", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/devices/unregister", %{"device_token" => "non_existent_token"})

      assert %{
        "success" => false,
        "error" => %{
          "code" => "DEVICE_NOT_FOUND",
          "message" => "Device not found"
        }
      } = json_response(conn, 404)
    end

    test "requires authentication", %{conn: conn} do
      conn = delete(conn, "/api/devices/unregister", %{"device_token" => "some_token"})
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/devices" do
    test "lists user's devices", %{conn: conn, user: user, token: token} do
      # Register some devices
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token1_#{System.unique_integer()}", platform: "android", app_version: "1.0.0"},
        user.id
      )
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token2_#{System.unique_integer()}", platform: "iphone", app_version: "2.0.0"},
        user.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/devices")

      assert %{"success" => true, "data" => devices} = json_response(conn, 200)
      assert length(devices) == 2
    end

    test "returns only active devices", %{conn: conn, user: user, token: token} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "active_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, conn2} = Mobile.create_connection(
        %{device_token: "inactive_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )
      {:ok, _} = Mobile.deactivate_connection(conn2.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/devices")

      assert %{"success" => true, "data" => devices} = json_response(conn, 200)
      assert length(devices) == 1
    end

    test "returns empty list when no devices", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/devices")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "returns formatted device data", %{conn: conn, user: user, token: token} do
      {:ok, _} = Mobile.create_connection(
        %{
          device_token: "formatted_#{System.unique_integer()}",
          platform: "android",
          app_version: "1.2.3",
          os_version: "14.0"
        },
        user.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/devices")

      assert %{"success" => true, "data" => [device]} = json_response(conn, 200)
      assert device["platform"] == "android"
      assert device["app_version"] == "1.2.3"
      assert device["os_version"] == "14.0"
      assert device["is_active"] == true
      assert device["last_seen_at"] != nil
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/devices")
      assert json_response(conn, 401)
    end

    test "does not return other user's devices", %{conn: conn, token: token} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, _} = Mobile.create_connection(
        %{device_token: "other_token_#{System.unique_integer()}", platform: "android"},
        other_user.id
      )

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/devices")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
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
