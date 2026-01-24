defmodule ButtonLogWeb.UserChannelTest do
  use ButtonLogWeb.ChannelCase

  alias ButtonLogWeb.UserChannel
  alias ButtonLog.Social

  setup do
    user = insert_user()
    {:ok, _, socket} = socket(ButtonLogWeb.UserSocket, "user_id", %{user_id: user.id})
                       |> subscribe_and_join(UserChannel, "user:#{user.id}")
    {:ok, socket: socket, user: user}
  end

  describe "join" do
    test "user can join their own channel", %{user: user} do
      {:ok, _, socket} = socket(ButtonLogWeb.UserSocket, "user_id", %{user_id: user.id})
                         |> subscribe_and_join(UserChannel, "user:#{user.id}")

      assert socket.assigns.target_user_id == user.id
    end

    test "user can join friend's channel" do
      user = insert_user()
      friend = insert_user(%{email: "friend@test.com", username: "friend"})

      # Create friendship
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      {:ok, _, socket} = socket(ButtonLogWeb.UserSocket, "user_id", %{user_id: user.id})
                         |> subscribe_and_join(UserChannel, "user:#{friend.id}")

      assert socket.assigns.target_user_id == friend.id
    end

    test "user cannot join non-friend's channel" do
      user = insert_user()
      stranger = insert_user(%{email: "stranger@test.com", username: "stranger"})

      result = socket(ButtonLogWeb.UserSocket, "user_id", %{user_id: user.id})
               |> subscribe_and_join(UserChannel, "user:#{stranger.id}")

      assert {:error, %{reason: "unauthorized"}} = result
    end
  end

  describe "update_status" do
    test "updates user status and broadcasts", %{socket: socket, user: _user} do
      ref = push(socket, "update_status", %{"status" => "online"})

      assert_reply ref, :ok
      assert_broadcast "status_updated", %{status: "online"}
    end
  end

  describe "send_alert" do
    test "sends alert to recipient", %{socket: socket, user: user} do
      friend = insert_user(%{email: "alertfriend@test.com", username: "alertfriend"})

      # Create friendship
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      ref = push(socket, "send_alert", %{
        "recipient_id" => friend.id,
        "message" => "Hello friend!"
      })

      assert_reply ref, :ok
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
