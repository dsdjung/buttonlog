defmodule ButtonLogWeb.API.SocialControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Social
  alias ButtonLog.Auth.Token

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/friends" do
    test "lists user's friends", %{conn: conn, user: user, token: token} do
      friend = insert_user(%{email: "friend@test.com", username: "friend"})

      # Create and accept friendship
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/friends")

      assert %{"success" => true, "data" => friends} = json_response(conn, 200)
      assert length(friends) == 1
      assert hd(friends)["friend_user"]["id"] == friend.id
    end

    test "returns empty list when no friends", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/friends")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/friends")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/friends/request" do
    # Invite-only model: only email is accepted
    # Whether user is registered or not, the response is identical

    test "sends invite to registered user by email", %{conn: conn, user: _user, token: token} do
      _other_user = insert_user(%{email: "byemail@test.com", username: "byemail"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/friends/request", %{email: "byemail@test.com"})

      # Response format is unified (same for existing users and invitations)
      # to prevent email enumeration attacks
      assert %{"success" => true, "data" => data} = json_response(conn, 201)
      assert data["invite_sent"] == true
      assert data["email"] == "byemail@test.com"
    end

    test "sends invite to unregistered email (same response as registered)", %{conn: conn, token: token} do
      # When sending invite to an unregistered email,
      # the response should be identical to a registered user
      # to prevent email enumeration attacks
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/friends/request", %{email: "unregistered@example.com"})

      assert %{"success" => true, "data" => data} = json_response(conn, 201)
      assert data["invite_sent"] == true
      assert data["email"] == "unregistered@example.com"
    end

    test "returns success even if already friends (to prevent enumeration)", %{conn: conn, user: user, token: token} do
      friend = insert_user(%{email: "alreadyfriend@test.com", username: "alreadyfriend"})
      {:ok, _} = Social.send_friend_request(user.id, friend.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/friends/request", %{email: "alreadyfriend@test.com"})

      # Returns success to prevent enumeration
      assert %{"success" => true, "data" => data} = json_response(conn, 201)
      assert data["invite_sent"] == true
    end

    test "returns error for missing email", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/friends/request", %{})

      assert %{"success" => false, "error" => error} = json_response(conn, 400)
      assert error["code"] == "MISSING_EMAIL"
    end

    test "returns error for self invite", %{conn: conn, user: user, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/friends/request", %{email: user.email})

      assert %{"success" => false, "error" => error} = json_response(conn, 400)
      assert error["code"] == "INVALID_REQUEST"
    end
  end

  describe "PUT /api/friends/:id/accept" do
    test "accepts a friend request", %{conn: conn, user: user, token: token} do
      requester = insert_user(%{email: "requester@test.com", username: "requester"})
      {:ok, friendship} = Social.send_friend_request(requester.id, user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/friends/#{friendship.id}/accept")

      assert %{"success" => true, "data" => data} = json_response(conn, 200)
      assert data["status"] == "accepted"
    end

    test "returns error for non-existent friendship", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put("/api/friends/#{Ecto.UUID.generate()}/accept")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "FRIENDSHIP_NOT_FOUND"
    end

    test "returns error when not recipient", %{conn: conn, user: user, token: token} do
      other_user = insert_user(%{email: "other3@test.com", username: "other3"})
      third_user = insert_user(%{email: "third@test.com", username: "third"})

      # user sends to other_user, but third_user tries to accept
      {:ok, friendship} = Social.send_friend_request(user.id, other_user.id)

      third_token = Token.create_token(third_user.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{third_token}")
        |> put("/api/friends/#{friendship.id}/accept")

      assert %{"success" => false, "error" => error} = json_response(conn, 403)
      assert error["code"] == "UNAUTHORIZED"
    end
  end

  describe "DELETE /api/friends/:id" do
    test "removes a friend", %{conn: conn, user: user, token: token} do
      friend = insert_user(%{email: "toremove@test.com", username: "toremove"})
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/friends/#{friendship.id}")

      assert %{"success" => true} = json_response(conn, 200)

      # Verify they're no longer friends
      assert Social.are_friends?(user.id, friend.id) == false
    end

    test "returns error for non-existent friendship", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/friends/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => error} = json_response(conn, 404)
      assert error["code"] == "FRIENDSHIP_NOT_FOUND"
    end
  end

  describe "GET /api/friends/:friend_id/buttons" do
    test "returns friend's shared buttons", %{conn: conn, user: user, token: token} do
      friend = insert_user(%{email: "btnfriend@test.com", username: "btnfriend"})

      # Create and accept friendship
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      # Create a button for the friend
      {:ok, _button} = ButtonLog.Buttons.create_button(%{name: "Friend's Button", type: "instant"}, friend.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/friends/#{friend.id}/buttons")

      assert %{"success" => true, "data" => _buttons} = json_response(conn, 200)
    end

    test "returns error when not friends", %{conn: conn, token: token} do
      stranger = insert_user(%{email: "stranger@test.com", username: "stranger"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/friends/#{stranger.id}/buttons")

      assert %{"success" => false, "error" => error} = json_response(conn, 403)
      assert error["code"] == "NOT_FRIENDS"
    end
  end

  describe "GET /api/friends/:friend_id/activity" do
    test "returns friend's activity", %{conn: conn, user: user, token: token} do
      friend = insert_user(%{email: "actfriend@test.com", username: "actfriend"})

      # Create and accept friendship
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/friends/#{friend.id}/activity")

      assert %{"success" => true, "data" => _activities, "meta" => _meta} = json_response(conn, 200)
    end

    test "returns error when not friends", %{conn: conn, token: token} do
      stranger = insert_user(%{email: "stranger2@test.com", username: "stranger2"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/friends/#{stranger.id}/activity")

      assert %{"success" => false, "error" => error} = json_response(conn, 403)
      assert error["code"] == "NOT_FRIENDS"
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
