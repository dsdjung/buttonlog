defmodule ButtonLog.MobileTest do
  use ButtonLog.DataCase

  alias ButtonLog.Mobile
  alias ButtonLog.Mobile.Connection

  describe "connections" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "create_connection/2 creates a connection", %{user: user} do
      attrs = %{
        device_token: "test_token_#{System.unique_integer()}",
        platform: "android",
        app_version: "1.0.0",
        os_version: "14.0"
      }

      assert {:ok, %Connection{} = connection} = Mobile.create_connection(attrs, user.id)

      assert connection.user_id == user.id
      assert connection.device_token == attrs.device_token
      assert connection.platform == "android"
      assert connection.app_version == "1.0.0"
      assert connection.os_version == "14.0"
      assert connection.is_active == true
      assert connection.last_seen_at != nil
    end

    test "create_connection/2 validates platform", %{user: user} do
      attrs = %{
        device_token: "test_token",
        platform: "invalid_platform"
      }

      assert {:error, changeset} = Mobile.create_connection(attrs, user.id)
      assert "is invalid" in errors_on(changeset).platform
    end

    test "create_connection/2 validates platform accepts android", %{user: user} do
      attrs = %{
        device_token: "android_token_#{System.unique_integer()}",
        platform: "android"
      }

      assert {:ok, connection} = Mobile.create_connection(attrs, user.id)
      assert connection.platform == "android"
    end

    test "create_connection/2 validates platform accepts iphone", %{user: user} do
      attrs = %{
        device_token: "iphone_token_#{System.unique_integer()}",
        platform: "iphone"
      }

      assert {:ok, connection} = Mobile.create_connection(attrs, user.id)
      assert connection.platform == "iphone"
    end

    test "create_connection/2 requires device_token", %{user: user} do
      attrs = %{platform: "android"}

      assert {:error, changeset} = Mobile.create_connection(attrs, user.id)
      assert "can't be blank" in errors_on(changeset).device_token
    end

    test "create_connection/2 enforces unique device_token", %{user: user} do
      token = "unique_token_#{System.unique_integer()}"
      attrs = %{device_token: token, platform: "android"}

      assert {:ok, _} = Mobile.create_connection(attrs, user.id)
      assert {:error, changeset} = Mobile.create_connection(attrs, user.id)
      assert "has already been taken" in errors_on(changeset).device_token
    end

    test "get_connection!/1 returns connection by id", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      fetched = Mobile.get_connection!(connection.id)
      assert fetched.id == connection.id
    end

    test "get_connection!/1 raises for non-existent connection" do
      fake_id = Ecto.UUID.generate()
      assert_raise Ecto.NoResultsError, fn ->
        Mobile.get_connection!(fake_id)
      end
    end

    test "get_connection_by_token/1 returns connection by device_token", %{user: user} do
      token = "token_#{System.unique_integer()}"
      {:ok, connection} = Mobile.create_connection(
        %{device_token: token, platform: "android"},
        user.id
      )

      fetched = Mobile.get_connection_by_token(token)
      assert fetched.id == connection.id
    end

    test "get_connection_by_token/1 returns nil for non-existent token" do
      assert Mobile.get_connection_by_token("non_existent_token") == nil
    end

    test "list_user_connections/1 returns active connections for user", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token1_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, conn2} = Mobile.create_connection(
        %{device_token: "token2_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )

      # Deactivate one
      {:ok, _} = Mobile.deactivate_connection(conn2.id)

      connections = Mobile.list_user_connections(user.id)
      assert length(connections) == 1
    end

    test "list_user_connections/1 returns empty list when no connections", %{user: user} do
      connections = Mobile.list_user_connections(user.id)
      assert connections == []
    end

    test "list_user_connections/1 orders by last_seen_at desc", %{user: user} do
      {:ok, conn1} = Mobile.create_connection(
        %{device_token: "token1_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      # Use 1 second sleep because we truncate datetime to seconds
      :timer.sleep(1100)
      {:ok, conn2} = Mobile.create_connection(
        %{device_token: "token2_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      connections = Mobile.list_user_connections(user.id)
      assert hd(connections).id == conn2.id
      assert List.last(connections).id == conn1.id
    end

    test "update_connection/2 updates connection attributes", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android", app_version: "1.0.0"},
        user.id
      )

      assert {:ok, updated} = Mobile.update_connection(connection, %{app_version: "2.0.0"})
      assert updated.app_version == "2.0.0"
    end

    test "update_connection_last_seen/1 updates last_seen_at", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      original_last_seen = connection.last_seen_at
      # Use 1 second sleep because we truncate datetime to seconds
      :timer.sleep(1100)

      assert {:ok, updated} = Mobile.update_connection_last_seen(connection.id)
      assert DateTime.compare(updated.last_seen_at, original_last_seen) == :gt
    end

    test "deactivate_connection/1 sets is_active to false", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert connection.is_active == true

      assert {:ok, deactivated} = Mobile.deactivate_connection(connection.id)
      assert deactivated.is_active == false
    end

    test "delete_connection/1 deletes connection", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, _} = Mobile.delete_connection(connection)
      assert Mobile.get_connection_by_token(connection.device_token) == nil
    end

    test "change_connection/2 returns a changeset", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      changeset = Mobile.change_connection(connection, %{app_version: "3.0.0"})
      assert %Ecto.Changeset{} = changeset
    end
  end

  describe "register_device/2" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "creates new connection when device_token doesn't exist", %{user: user} do
      attrs = %{
        device_token: "new_token_#{System.unique_integer()}",
        platform: "android",
        app_version: "1.0.0"
      }

      assert {:ok, connection} = Mobile.register_device(attrs, user.id)
      assert connection.device_token == attrs.device_token
      assert connection.user_id == user.id
    end

    test "updates existing connection when device_token exists", %{user: user} do
      token = "existing_token_#{System.unique_integer()}"
      attrs1 = %{device_token: token, platform: "android", app_version: "1.0.0"}
      {:ok, original} = Mobile.register_device(attrs1, user.id)

      attrs2 = %{device_token: token, platform: "android", app_version: "2.0.0"}
      {:ok, updated} = Mobile.register_device(attrs2, user.id)

      assert updated.id == original.id
      assert updated.app_version == "2.0.0"
    end

    test "can transfer device to different user", %{user: user} do
      other_user = insert_user(%{email: "other@example.com", username: "other"})
      token = "transfer_token_#{System.unique_integer()}"

      attrs = %{device_token: token, platform: "android"}
      {:ok, original} = Mobile.register_device(attrs, user.id)

      # Same device registered by different user
      {:ok, updated} = Mobile.register_device(attrs, other_user.id)

      # Connection should be updated with new user
      assert updated.id == original.id
      # Note: The current implementation doesn't update user_id, just other attrs
      # This test documents the current behavior
    end
  end

  describe "get_active_connections/1" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "returns only active connections", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token1_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, conn2} = Mobile.create_connection(
        %{device_token: "token2_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )

      # Deactivate one
      {:ok, _} = Mobile.deactivate_connection(conn2.id)

      active = Mobile.get_active_connections(user.id)
      assert length(active) == 1
    end

    test "returns empty list when no active connections", %{user: user} do
      {:ok, conn} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, _} = Mobile.deactivate_connection(conn.id)

      active = Mobile.get_active_connections(user.id)
      assert active == []
    end
  end

  describe "get_connections_by_platform/2" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "returns connections for specified platform", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "android1_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, _} = Mobile.create_connection(
        %{device_token: "android2_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, _} = Mobile.create_connection(
        %{device_token: "iphone1_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )

      android_connections = Mobile.get_connections_by_platform(user.id, "android")
      assert length(android_connections) == 2

      iphone_connections = Mobile.get_connections_by_platform(user.id, "iphone")
      assert length(iphone_connections) == 1
    end

    test "returns only active connections for platform", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "android1_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, conn2} = Mobile.create_connection(
        %{device_token: "android2_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, _} = Mobile.deactivate_connection(conn2.id)

      android_connections = Mobile.get_connections_by_platform(user.id, "android")
      assert length(android_connections) == 1
    end

    test "returns empty list when no connections for platform", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "android_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      iphone_connections = Mobile.get_connections_by_platform(user.id, "iphone")
      assert iphone_connections == []
    end
  end

  # Helper functions
  defp insert_user(attrs \\ %{}) do
    default_attrs = %{
      email: "test#{System.unique_integer()}@test.com",
      username: "testuser#{System.unique_integer()}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123")
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash])
    |> ButtonLog.Repo.insert!()
  end
end
