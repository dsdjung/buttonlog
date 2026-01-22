defmodule ButtonLogWeb.API.AuthControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Accounts
  alias ButtonLog.Auth.Token

  describe "POST /api/auth/register" do
    test "creates a new user with valid data", %{conn: conn} do
      conn =
        post(conn, "/api/auth/register", %{
          user: %{
            email: "newuser@example.com",
            username: "newuser",
            display_name: "New User",
            password: "password123!",
            password_confirmation: "password123!"
          }
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 201)
      assert data["user"]["email"] == "newuser@example.com"
      assert data["user"]["username"] == "newuser"
      assert data["token"] != nil
    end

    test "returns error for invalid data", %{conn: conn} do
      conn =
        post(conn, "/api/auth/register", %{
          user: %{
            email: "invalid",
            username: "",
            password: "short"
          }
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 422)
      assert error["code"] == "VALIDATION_ERROR"
    end

    test "returns error for duplicate email", %{conn: conn} do
      # First create a user
      insert_user(%{email: "existing@example.com", username: "existing"})

      # Try to register with same email but wrong password
      conn =
        post(conn, "/api/auth/register", %{
          user: %{
            email: "existing@example.com",
            username: "newuser",
            display_name: "New User",
            password: "wrongpassword!",
            password_confirmation: "wrongpassword!"
          }
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 401)
      assert error["code"] == "INVALID_CREDENTIALS"
    end

    test "logs in existing user with correct password", %{conn: conn} do
      # First create a user
      {:ok, _user} = Accounts.register_user(%{
        email: "existing2@example.com",
        username: "existing2",
        display_name: "Existing User",
        password: "password123!",
        password_confirmation: "password123!"
      })

      # Try to "register" with existing email and correct password
      conn =
        post(conn, "/api/auth/register", %{
          user: %{
            email: "existing2@example.com",
            username: "different",
            display_name: "Different",
            password: "password123!",
            password_confirmation: "password123!"
          }
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["user"]["email"] == "existing2@example.com"
      assert data["token"] != nil
    end
  end

  describe "POST /api/auth/login" do
    setup do
      {:ok, user} = Accounts.register_user(%{
        email: "login@example.com",
        username: "loginuser",
        display_name: "Login User",
        password: "password123!",
        password_confirmation: "password123!"
      })
      %{user: user}
    end

    test "logs in with valid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/auth/login", %{
          email: user.email,
          password: "password123!"
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["user"]["email"] == user.email
      assert data["token"] != nil
    end

    test "returns error for wrong password", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/auth/login", %{
          email: user.email,
          password: "wrongpassword"
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 401)
      assert error["code"] == "INVALID_CREDENTIALS"
    end

    test "returns error for non-existent email", %{conn: conn} do
      conn =
        post(conn, "/api/auth/login", %{
          email: "nonexistent@example.com",
          password: "password123!"
        })

      assert %{"success" => false, "error" => error} = json_response(conn, 401)
      assert error["code"] == "INVALID_CREDENTIALS"
    end
  end

  describe "POST /api/auth/refresh" do
    setup do
      user = insert_user()
      token = Token.create_token(user.id)
      %{user: user, token: token}
    end

    test "returns token for valid token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/auth/refresh")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["token"] != nil
      # The token may be the same if no time-based claims are used
    end

    test "returns error without token", %{conn: conn} do
      conn = post(conn, "/api/auth/refresh")

      assert json_response(conn, 401)
    end

    test "returns error for invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> post("/api/auth/refresh")

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
end
