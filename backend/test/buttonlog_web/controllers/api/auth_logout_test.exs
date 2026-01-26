defmodule ButtonLogWeb.API.AuthLogoutTest do
  use ButtonLogWeb.ConnCase
  alias ButtonLog.Auth.{Token, TokenBlacklist}

  setup do
    # Ensure the TokenBlacklist is started for tests
    case GenServer.whereis(TokenBlacklist) do
      nil ->
        {:ok, _pid} = TokenBlacklist.start_link([])
        :ok

      _pid ->
        # Clear the ETS table for a clean test state
        :ets.delete_all_objects(:token_blacklist)
        :ok
    end

    user = insert_user()
    token = Token.create_token(user.id)
    %{user: user, token: token}
  end

  describe "POST /api/auth/logout" do
    test "successfully logs out with valid token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/auth/logout")

      assert json_response(conn, 200)["success"] == true
      assert json_response(conn, 200)["message"] =~ "Logged out"
    end

    test "logs out even without token", %{conn: conn} do
      conn = post(conn, "/api/auth/logout")

      assert json_response(conn, 200)["success"] == true
    end

    test "revoked token cannot be used for API calls", %{conn: conn, token: token} do
      # First, logout to revoke the token
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/auth/logout")

      # Try to use the revoked token for an authenticated endpoint
      conn2 =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/profile")

      # Should be unauthorized
      assert json_response(conn2, 401)
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
