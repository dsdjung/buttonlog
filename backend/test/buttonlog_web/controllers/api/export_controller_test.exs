defmodule ButtonLogWeb.API.ExportControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Auth.Token
  alias ButtonLog.Repo
  alias ButtonLog.Buttons.Button

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/users/export" do
    test "exports user data as JSON by default", %{conn: conn, user: user, token: token} do
      # Create some test data
      insert_button(user.id, %{name: "Test Button 1"})
      insert_button(user.id, %{name: "Test Button 2"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/export")

      assert response = response(conn, 200)
      assert get_resp_header(conn, "content-type") |> List.first() |> String.contains?("application/json")
      assert get_resp_header(conn, "content-disposition") |> List.first() |> String.contains?("attachment")

      # Parse and verify JSON content
      data = Jason.decode!(response)
      assert Map.has_key?(data, "user")
      assert Map.has_key?(data, "buttons")
      assert Map.has_key?(data, "statistics")
      assert data["user"]["id"] == user.id
    end

    test "exports user data as JSON when format=json", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/export", %{"format" => "json"})

      assert response = response(conn, 200)
      assert get_resp_header(conn, "content-type") |> List.first() |> String.contains?("application/json")
    end

    test "exports user data as CSV when format=csv", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/export", %{"format" => "csv"})

      assert response = response(conn, 200)
      assert get_resp_header(conn, "content-type") |> List.first() |> String.contains?("text/csv")
      assert String.contains?(response, "# ButtonLog Data Export")
      assert String.contains?(response, "## USER PROFILE")
    end

    test "includes buttons in export", %{conn: conn, user: user, token: token} do
      insert_button(user.id, %{name: "My Special Button", type: "instant"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/export")

      data = Jason.decode!(response(conn, 200))
      assert length(data["buttons"]) == 1
      assert hd(data["buttons"])["name"] == "My Special Button"
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/users/export")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/users/export/info" do
    test "returns export metadata", %{conn: conn, user: user, token: token} do
      # Create test data
      insert_button(user.id, %{name: "Button 1"})
      insert_button(user.id, %{name: "Button 2"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/export/info")

      assert %{
        "success" => true,
        "data" => %{
          "buttons_count" => 2,
          "clicks_count" => 0,
          "friends_count" => 0,
          "available_formats" => ["json", "csv"],
          "estimated_size" => _
        }
      } = json_response(conn, 200)
    end

    test "returns correct counts for empty user", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/export/info")

      assert %{
        "success" => true,
        "data" => %{
          "buttons_count" => 0,
          "clicks_count" => 0,
          "friends_count" => 0
        }
      } = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/users/export/info")
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
    |> Repo.insert!()
  end

  defp insert_button(user_id, attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    default_attrs = %{
      name: "Test Button #{unique_id}",
      type: "instant",
      user_id: user_id
    }

    attrs = Map.merge(default_attrs, attrs)

    %Button{}
    |> Ecto.Changeset.cast(attrs, [:name, :type, :user_id])
    |> Repo.insert!()
  end
end
