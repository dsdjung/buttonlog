defmodule ButtonLog.SocialTest do
  use ButtonLog.DataCase

  alias ButtonLog.Social
  alias ButtonLog.Social.{Friendship, FriendPermission}
  alias ButtonLog.Accounts

  describe "friendships" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      user3 = insert_user(%{username: "user3", email: "user3@example.com"})
      %{user1: user1, user2: user2, user3: user3}
    end

    test "send_friend_request/2 creates a pending friendship", %{user1: user1, user2: user2} do
      assert {:ok, %Friendship{} = friendship} = Social.send_friend_request(user1.id, user2.id)
      assert friendship.user_id == user1.id
      assert friendship.friend_id == user2.id
      assert friendship.status == "pending"
    end

    test "send_friend_request/2 returns error for non-existent user", %{user1: user1} do
      fake_id = Ecto.UUID.generate()
      assert {:error, :user_not_found} = Social.send_friend_request(user1.id, fake_id)
    end

    test "send_friend_request/2 returns error when already friends", %{user1: user1, user2: user2} do
      {:ok, _friendship} = Social.send_friend_request(user1.id, user2.id)
      assert {:error, :already_friends} = Social.send_friend_request(user1.id, user2.id)
    end

    test "send_friend_request/2 returns error when reverse request pending", %{user1: user1, user2: user2} do
      {:ok, _friendship} = Social.send_friend_request(user2.id, user1.id)
      assert {:error, :already_friends} = Social.send_friend_request(user1.id, user2.id)
    end

    test "accept_friend_request/2 accepts a pending request", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      assert {:ok, accepted} = Social.accept_friend_request(friendship.id, user2.id)
      assert accepted.status == "accepted"
    end

    test "accept_friend_request/2 returns error when wrong user tries to accept", %{user1: user1, user2: user2, user3: user3} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      # user3 should not be able to accept user1's request to user2
      assert {:error, :unauthorized} = Social.accept_friend_request(friendship.id, user3.id)
    end

    test "accept_friend_request/2 returns error when sender tries to accept", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      # The sender should not be able to accept their own request
      assert {:error, :unauthorized} = Social.accept_friend_request(friendship.id, user1.id)
    end

    test "decline_friend_request/2 removes a pending request", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      assert {:ok, :declined} = Social.decline_friend_request(friendship.id, user2.id)

      # The friendship should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Social.get_friendship!(friendship.id)
      end
    end

    test "decline_friend_request/2 returns error for unauthorized user", %{user1: user1, user2: user2, user3: user3} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      assert {:error, :unauthorized} = Social.decline_friend_request(friendship.id, user3.id)
    end

    test "cancel_friend_request/2 removes a sent request", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      assert {:ok, :deleted} = Social.cancel_friend_request(friendship.id, user1.id)

      # The friendship should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Social.get_friendship!(friendship.id)
      end
    end

    test "cancel_friend_request/2 returns error when recipient tries to cancel", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      assert {:error, :unauthorized} = Social.cancel_friend_request(friendship.id, user2.id)
    end

    test "remove_friend/2 removes an accepted friendship", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, user2.id)

      assert {:ok, :deleted} = Social.remove_friend(friendship.id, user1.id)

      # Users should no longer be friends
      assert Social.are_friends?(user1.id, user2.id) == false
    end

    test "remove_friend/2 can be called by either user", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, user2.id)

      # user2 should also be able to remove the friendship
      assert {:ok, :deleted} = Social.remove_friend(friendship.id, user2.id)
    end

    test "remove_friend/2 returns error for unauthorized user", %{user1: user1, user2: user2, user3: user3} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, user2.id)

      assert {:error, :unauthorized} = Social.remove_friend(friendship.id, user3.id)
    end
  end

  describe "are_friends?/2" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      %{user1: user1, user2: user2}
    end

    test "returns false for users with no relationship", %{user1: user1, user2: user2} do
      assert Social.are_friends?(user1.id, user2.id) == false
    end

    test "returns false for pending friendship", %{user1: user1, user2: user2} do
      {:ok, _friendship} = Social.send_friend_request(user1.id, user2.id)
      assert Social.are_friends?(user1.id, user2.id) == false
    end

    test "returns true for accepted friendship", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, user2.id)

      assert Social.are_friends?(user1.id, user2.id) == true
      # Should work both directions
      assert Social.are_friends?(user2.id, user1.id) == true
    end
  end

  describe "get_user_friends/1" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      user3 = insert_user(%{username: "user3", email: "user3@example.com"})
      %{user1: user1, user2: user2, user3: user3}
    end

    test "returns empty list for user with no friends", %{user1: user1} do
      assert Social.get_user_friends(user1.id) == []
    end

    test "returns accepted friends only", %{user1: user1, user2: user2, user3: user3} do
      # Create and accept friendship with user2
      {:ok, friendship1} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(friendship1.id, user2.id)

      # Create pending friendship with user3
      {:ok, _friendship2} = Social.send_friend_request(user1.id, user3.id)

      friends = Social.get_user_friends(user1.id)
      assert length(friends) == 1
      assert hd(friends).id == user2.id
    end

    test "returns friends from both directions", %{user1: user1, user2: user2, user3: user3} do
      # user1 sends request to user2
      {:ok, friendship1} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(friendship1.id, user2.id)

      # user3 sends request to user1
      {:ok, friendship2} = Social.send_friend_request(user3.id, user1.id)
      {:ok, _} = Social.accept_friend_request(friendship2.id, user1.id)

      friends = Social.get_user_friends(user1.id)
      friend_ids = Enum.map(friends, & &1.id)

      assert length(friends) == 2
      assert user2.id in friend_ids
      assert user3.id in friend_ids
    end
  end

  describe "get_pending_friend_requests/1" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      user3 = insert_user(%{username: "user3", email: "user3@example.com"})
      %{user1: user1, user2: user2, user3: user3}
    end

    test "returns empty list when no pending requests", %{user1: user1} do
      assert Social.get_pending_friend_requests(user1.id) == []
    end

    test "returns pending requests sent to the user", %{user1: user1, user2: user2, user3: user3} do
      {:ok, _} = Social.send_friend_request(user2.id, user1.id)
      {:ok, _} = Social.send_friend_request(user3.id, user1.id)

      requests = Social.get_pending_friend_requests(user1.id)
      assert length(requests) == 2

      sender_ids = Enum.map(requests, & &1.user.id)
      assert user2.id in sender_ids
      assert user3.id in sender_ids
    end

    test "does not return requests sent by the user", %{user1: user1, user2: user2} do
      {:ok, _} = Social.send_friend_request(user1.id, user2.id)

      requests = Social.get_pending_friend_requests(user1.id)
      assert requests == []
    end
  end

  describe "get_sent_friend_requests/1" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      %{user1: user1, user2: user2}
    end

    test "returns empty list when no sent requests", %{user1: user1} do
      assert Social.get_sent_friend_requests(user1.id) == []
    end

    test "returns requests sent by the user", %{user1: user1, user2: user2} do
      {:ok, _} = Social.send_friend_request(user1.id, user2.id)

      requests = Social.get_sent_friend_requests(user1.id)
      assert length(requests) == 1
      assert hd(requests).friend.id == user2.id
    end
  end

  describe "get_friendship_between_users/2" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      %{user1: user1, user2: user2}
    end

    test "returns nil when no friendship exists", %{user1: user1, user2: user2} do
      assert Social.get_friendship_between_users(user1.id, user2.id) == nil
    end

    test "returns friendship regardless of direction", %{user1: user1, user2: user2} do
      {:ok, friendship} = Social.send_friend_request(user1.id, user2.id)

      # Should find it both ways
      assert Social.get_friendship_between_users(user1.id, user2.id).id == friendship.id
      assert Social.get_friendship_between_users(user2.id, user1.id).id == friendship.id
    end
  end

  describe "friend permissions" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      %{user1: user1, user2: user2}
    end

    test "get_friend_permissions/2 returns nil when no permissions set", %{user1: user1, user2: user2} do
      assert Social.get_friend_permissions(user1.id, user2.id) == nil
    end

    test "upsert_friend_permissions/3 creates new permissions", %{user1: user1, user2: user2} do
      attrs = %{can_view_history: true, can_view_buttons: true, can_receive_alerts: false}
      assert {:ok, %FriendPermission{} = perm} = Social.upsert_friend_permissions(attrs, user1.id, user2.id)

      assert perm.user_id == user1.id
      assert perm.friend_id == user2.id
      assert perm.can_view_history == true
      assert perm.can_view_buttons == true
    end

    test "upsert_friend_permissions/3 updates existing permissions", %{user1: user1, user2: user2} do
      attrs1 = %{can_view_history: true, can_view_buttons: true}
      {:ok, _perm1} = Social.upsert_friend_permissions(attrs1, user1.id, user2.id)

      attrs2 = %{can_view_history: false}
      {:ok, perm2} = Social.upsert_friend_permissions(attrs2, user1.id, user2.id)

      assert perm2.can_view_history == false
      # can_view_buttons should still be true
      assert perm2.can_view_buttons == true
    end

    test "can_view_history?/2 returns true by default", %{user1: user1, user2: user2} do
      assert Social.can_view_history?(user1.id, user2.id) == true
    end

    test "can_view_history?/2 respects permission settings", %{user1: user1, user2: user2} do
      {:ok, _} = Social.upsert_friend_permissions(%{can_view_history: false}, user1.id, user2.id)
      assert Social.can_view_history?(user1.id, user2.id) == false
    end

    test "can_view_buttons?/2 returns true by default", %{user1: user1, user2: user2} do
      assert Social.can_view_buttons?(user1.id, user2.id) == true
    end

    test "can_view_buttons?/2 respects permission settings", %{user1: user1, user2: user2} do
      {:ok, _} = Social.upsert_friend_permissions(%{can_view_buttons: false}, user1.id, user2.id)
      assert Social.can_view_buttons?(user1.id, user2.id) == false
    end

    test "can_receive_notifications?/2 returns true by default", %{user1: user1, user2: user2} do
      assert Social.can_receive_notifications?(user1.id, user2.id) == true
    end
  end

  describe "get_user_friend_ids/1" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      user3 = insert_user(%{username: "user3", email: "user3@example.com"})
      %{user1: user1, user2: user2, user3: user3}
    end

    test "returns empty list when no friends", %{user1: user1} do
      assert Social.get_user_friend_ids(user1.id) == []
    end

    test "returns friend IDs for accepted friendships", %{user1: user1, user2: user2, user3: user3} do
      {:ok, f1} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(f1.id, user2.id)

      {:ok, f2} = Social.send_friend_request(user3.id, user1.id)
      {:ok, _} = Social.accept_friend_request(f2.id, user1.id)

      friend_ids = Social.get_user_friend_ids(user1.id)
      assert length(friend_ids) == 2
      assert user2.id in friend_ids
      assert user3.id in friend_ids
    end
  end

  describe "get_existing_friend_ids/1" do
    setup do
      user1 = insert_user(%{username: "user1", email: "user1@example.com"})
      user2 = insert_user(%{username: "user2", email: "user2@example.com"})
      user3 = insert_user(%{username: "user3", email: "user3@example.com"})
      %{user1: user1, user2: user2, user3: user3}
    end

    test "includes pending friendships", %{user1: user1, user2: user2} do
      {:ok, _} = Social.send_friend_request(user1.id, user2.id)

      existing_ids = Social.get_existing_friend_ids(user1.id)
      assert user2.id in existing_ids
    end

    test "includes accepted friendships", %{user1: user1, user2: user2} do
      {:ok, f} = Social.send_friend_request(user1.id, user2.id)
      {:ok, _} = Social.accept_friend_request(f.id, user2.id)

      existing_ids = Social.get_existing_friend_ids(user1.id)
      assert user2.id in existing_ids
    end
  end

  # Helper functions

  defp insert_user(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    default_attrs = %{
      email: "user#{unique_id}@example.com",
      username: "user#{unique_id}",
      display_name: "User #{unique_id}",
      password: "password123!",
      password_confirmation: "password123!"
    }

    {:ok, user} = Accounts.register_user(Map.merge(default_attrs, attrs))
    user
  end
end
