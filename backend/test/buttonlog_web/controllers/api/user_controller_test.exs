defmodule ButtonLogWeb.API.UserControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Accounts
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/users/profile" do
    test "returns current user profile", %{conn: conn, user: user, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/profile")

      assert %{
        "success" => true,
        "data" => data
      } = json_response(conn, 200)

      assert data["id"] == user.id
      assert data["email"] == user.email
      assert data["username"] == user.username
      assert data["display_name"] == user.display_name
    end

    test "returns subscription information", %{conn: conn, user: user, token: token} do
      # Update user with subscription info
      {:ok, _} = Accounts.update_user(user, %{
        subscription_tier: "premium",
        subscription_expires_at: DateTime.utc_now() |> DateTime.add(30, :day)
      })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/profile")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["subscription_tier"] == "premium"
      assert data["subscription_expires_at"] != nil
    end

    test "returns user preferences", %{conn: conn, user: user, token: token} do
      {:ok, _} = Accounts.update_user(user, %{
        timezone: "America/New_York",
        language: "en"
      })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/profile")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["timezone"] == "America/New_York"
      assert data["language"] == "en"
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/users/profile")
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/users/profile" do
    test "updates display name", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/profile", %{
          "user" => %{"display_name" => "New Display Name"}
        })

      assert %{
        "success" => true,
        "data" => %{"display_name" => "New Display Name"}
      } = json_response(conn, 200)
    end

    test "updates timezone", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/profile", %{
          "user" => %{"timezone" => "Europe/London"}
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["timezone"] == "Europe/London"
    end

    test "updates language", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/profile", %{
          "user" => %{"language" => "es"}
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["language"] == "es"
    end

    test "updates multiple fields", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/profile", %{
          "user" => %{
            "display_name" => "Updated Name",
            "timezone" => "Asia/Tokyo",
            "language" => "ja"
          }
        })

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["display_name"] == "Updated Name"
      assert data["timezone"] == "Asia/Tokyo"
      assert data["language"] == "ja"
    end

    test "returns error for display_name that is too long", %{conn: conn, token: token} do
      # display_name has max: 100 validation in profile_changeset
      long_name = String.duplicate("a", 101)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/profile", %{
          "user" => %{"display_name" => long_name}
        })

      assert %{
        "success" => false,
        "error" => %{"code" => "VALIDATION_ERROR"}
      } = json_response(conn, 422)
    end

    test "ignores username in profile update (username not updatable via profile)", %{conn: conn, token: token} do
      # The profile endpoint doesn't cast username, so it should be ignored
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/users/profile", %{
          "user" => %{"username" => "newusername", "display_name" => "Valid Name"}
        })

      # Should succeed but username remains unchanged
      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["display_name"] == "Valid Name"
      # Username should not have changed (still the original)
      refute data["username"] == "newusername"
    end

    test "requires authentication", %{conn: conn} do
      conn = put(conn, "/api/users/profile", %{"user" => %{"display_name" => "Test"}})
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/users/:id/public-profile" do
    test "returns public profile for existing user", %{conn: conn, token: token} do
      other_user = insert_user(%{
        email: "other@test.com",
        username: "otheruser",
        display_name: "Other User"
      })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/#{other_user.id}/public-profile")

      assert %{
        "success" => true,
        "data" => data
      } = json_response(conn, 200)

      assert data["id"] == other_user.id
      assert data["username"] == "otheruser"
      assert data["display_name"] == "Other User"
      # Should not include private fields
      refute Map.has_key?(data, "email")
      refute Map.has_key?(data, "subscription_tier")
    end

    test "returns 404 for non-existent user", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/users/#{Ecto.UUID.generate()}/public-profile")

      assert %{
        "success" => false,
        "error" => %{
          "code" => "USER_NOT_FOUND",
          "message" => "User not found"
        }
      } = json_response(conn, 404)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/users/#{Ecto.UUID.generate()}/public-profile")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/users/complete-onboarding" do
    test "marks onboarding as complete", %{conn: conn, user: user, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/users/complete-onboarding")

      assert %{
        "success" => true,
        "data" => %{"onboarding_completed" => true}
      } = json_response(conn, 200)

      # Verify user was updated
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.onboarding_completed == true
    end

    test "succeeds even if already completed", %{conn: conn, user: user, token: token} do
      # First completion
      {:ok, _} = Accounts.update_user(user, %{onboarding_completed: true})

      # Second completion should still succeed
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/users/complete-onboarding")

      assert %{
        "success" => true,
        "data" => %{"onboarding_completed" => true}
      } = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/api/users/complete-onboarding")
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
