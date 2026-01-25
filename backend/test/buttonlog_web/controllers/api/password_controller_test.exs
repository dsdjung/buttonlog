defmodule ButtonLogWeb.API.PasswordControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "PUT /api/users/password" do
    test "changes password with valid credentials", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/password", %{
          "current_password" => "password123!",
          "new_password" => "newpassword456",
          "confirm_password" => "newpassword456"
        })

      assert %{"success" => true, "data" => %{"message" => _}} = json_response(conn, 200)
    end

    test "returns error when current password is wrong", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/password", %{
          "current_password" => "wrongpassword",
          "new_password" => "newpassword456",
          "confirm_password" => "newpassword456"
        })

      assert %{"success" => false, "error" => %{"code" => "INVALID_CURRENT_PASSWORD"}} = json_response(conn, 401)
    end

    test "returns error when passwords don't match", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/password", %{
          "current_password" => "password123!",
          "new_password" => "newpassword456",
          "confirm_password" => "differentpassword"
        })

      assert %{"success" => false, "error" => %{"code" => "PASSWORD_MISMATCH"}} = json_response(conn, 422)
    end

    test "returns error when new password is too short", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/password", %{
          "current_password" => "password123!",
          "new_password" => "short",
          "confirm_password" => "short"
        })

      assert %{"success" => false, "error" => %{"code" => "PASSWORD_TOO_SHORT"}} = json_response(conn, 422)
    end

    test "requires authentication", %{conn: conn} do
      conn = put(conn, "/api/users/password", %{
        "current_password" => "password123!",
        "new_password" => "newpassword456",
        "confirm_password" => "newpassword456"
      })

      assert json_response(conn, 401)
    end
  end

  # Helper function
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
