defmodule ButtonLog.SharedButtonsTest do
  use ButtonLog.DataCase, async: true

  alias ButtonLog.{Buttons, Social}

  describe "shared button access" do
    setup do
      # Create owner user
      owner = insert_user(%{email: "owner@test.com", username: "owner", display_name: "Owner"})

      # Create friend user
      friend = insert_user(%{email: "friend@test.com", username: "friend", display_name: "Friend"})

      # Create stranger user (not a friend)
      stranger = insert_user(%{email: "stranger@test.com", username: "stranger", display_name: "Stranger"})

      # Create friendship between owner and friend
      create_friendship(owner.id, friend.id)

      # Create a button for the owner
      {:ok, button} = Buttons.create_button(%{
        "name" => "Test Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#FF0000"
      }, owner.id)

      %{owner: owner, friend: friend, stranger: stranger, button: button}
    end

    test "owner can always click their own button", %{owner: owner, button: button} do
      assert Buttons.can_click_button?(button.id, owner.id) == true
    end

    test "private button cannot be clicked by friend", %{friend: friend, button: button} do
      # Button defaults to private
      assert Buttons.can_click_button?(button.id, friend.id) == false
    end

    test "private button cannot be clicked by stranger", %{stranger: stranger, button: button} do
      assert Buttons.can_click_button?(button.id, stranger.id) == false
    end

    test "friends sharing mode allows friends to click", %{owner: owner, friend: friend, button: button} do
      # Update sharing mode to friends
      {:ok, _} = Buttons.update_sharing_mode(button.id, owner.id, "friends")

      assert Buttons.can_click_button?(button.id, friend.id) == true
    end

    test "friends sharing mode does not allow strangers to click", %{owner: owner, stranger: stranger, button: button} do
      {:ok, _} = Buttons.update_sharing_mode(button.id, owner.id, "friends")

      assert Buttons.can_click_button?(button.id, stranger.id) == false
    end

    test "invite_only mode requires explicit collaborator", %{owner: owner, friend: friend, button: button} do
      {:ok, _} = Buttons.update_sharing_mode(button.id, owner.id, "invite_only")

      # Friend cannot click without being added as collaborator
      assert Buttons.can_click_button?(button.id, friend.id) == false

      # Add friend as collaborator
      {:ok, _} = Buttons.add_collaborator(button.id, owner.id, friend.id)

      # Now friend can click
      assert Buttons.can_click_button?(button.id, friend.id) == true
    end

    test "public mode allows anyone to click", %{owner: owner, stranger: stranger, button: button} do
      {:ok, _} = Buttons.update_sharing_mode(button.id, owner.id, "public")

      assert Buttons.can_click_button?(button.id, stranger.id) == true
    end
  end

  describe "collaborator management" do
    setup do
      owner = insert_user(%{email: "owner2@test.com", username: "owner2", display_name: "Owner2"})

      friend = insert_user(%{email: "friend2@test.com", username: "friend2", display_name: "Friend2"})

      create_friendship(owner.id, friend.id)

      {:ok, button} = Buttons.create_button(%{
        "name" => "Collab Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#00FF00"
      }, owner.id)

      %{owner: owner, friend: friend, button: button}
    end

    test "owner can add collaborator", %{owner: owner, friend: friend, button: button} do
      {:ok, collab} = Buttons.add_collaborator(button.id, owner.id, friend.id)

      assert collab.user_id == friend.id
      assert collab.button_id == button.id
      assert collab.permission == "click"
    end

    test "owner can remove collaborator", %{owner: owner, friend: friend, button: button} do
      {:ok, _} = Buttons.add_collaborator(button.id, owner.id, friend.id)
      {:ok, _} = Buttons.remove_collaborator(button.id, owner.id, friend.id)

      assert Buttons.is_collaborator?(button.id, friend.id) == false
    end

    test "list_collaborators returns all collaborators", %{owner: owner, friend: friend, button: button} do
      {:ok, _} = Buttons.add_collaborator(button.id, owner.id, friend.id)
      {:ok, collaborators} = Buttons.list_collaborators(button.id, owner.id)

      assert length(collaborators) == 1
      assert hd(collaborators).user_id == friend.id
    end
  end

  describe "share token" do
    setup do
      owner = insert_user(%{email: "owner3@test.com", username: "owner3", display_name: "Owner3"})

      {:ok, button} = Buttons.create_button(%{
        "name" => "Token Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#0000FF"
      }, owner.id)

      %{owner: owner, button: button}
    end

    test "can generate share token", %{owner: owner, button: button} do
      {:ok, updated_button} = Buttons.generate_share_token(button.id, owner.id)

      assert updated_button.share_token != nil
      assert String.length(updated_button.share_token) > 0
    end

    test "can revoke share token", %{owner: owner, button: button} do
      {:ok, _} = Buttons.generate_share_token(button.id, owner.id)
      {:ok, updated_button} = Buttons.revoke_share_token(button.id, owner.id)

      assert updated_button.share_token == nil
    end

    test "can find button by share token", %{owner: owner, button: button} do
      {:ok, updated_button} = Buttons.generate_share_token(button.id, owner.id)
      {:ok, found_button} = Buttons.get_button_by_share_token(updated_button.share_token)

      assert found_button.id == button.id
    end
  end

  describe "list_accessible_buttons" do
    setup do
      owner = insert_user(%{email: "owner4@test.com", username: "owner4", display_name: "Owner4"})

      friend = insert_user(%{email: "friend4@test.com", username: "friend4", display_name: "Friend4"})

      create_friendship(owner.id, friend.id)

      # Create own button for friend
      {:ok, friend_button} = Buttons.create_button(%{
        "name" => "Friend's Own Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#FFFF00"
      }, friend.id)

      # Create shared button owned by owner
      {:ok, shared_button} = Buttons.create_button(%{
        "name" => "Shared Button",
        "type" => "instant",
        "icon" => "heart",
        "color" => "#FF00FF"
      }, owner.id)

      # Share with friends
      {:ok, _} = Buttons.update_sharing_mode(shared_button.id, owner.id, "friends")

      %{owner: owner, friend: friend, friend_button: friend_button, shared_button: shared_button}
    end

    test "includes own buttons", %{friend: friend, friend_button: friend_button} do
      buttons = Buttons.list_accessible_buttons(friend.id)

      button_ids = Enum.map(buttons, & &1.id)
      assert friend_button.id in button_ids
    end

    test "includes shared buttons from friends", %{friend: friend, shared_button: shared_button} do
      buttons = Buttons.list_accessible_buttons(friend.id)

      button_ids = Enum.map(buttons, & &1.id)
      assert shared_button.id in button_ids
    end

    test "marks shared buttons appropriately", %{friend: friend, shared_button: shared_button} do
      buttons = Buttons.list_accessible_buttons(friend.id)

      shared = Enum.find(buttons, fn b -> b.id == shared_button.id end)
      assert shared.is_shared_with_me == true
      assert shared.owner_name != nil
    end
  end

  describe "click_button_with_access_check" do
    setup do
      owner = insert_user(%{email: "owner5@test.com", username: "owner5", display_name: "Owner5"})

      friend = insert_user(%{email: "friend5@test.com", username: "friend5", display_name: "Friend5"})

      create_friendship(owner.id, friend.id)

      {:ok, button} = Buttons.create_button(%{
        "name" => "Clickable Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#CCCCCC"
      }, owner.id)

      %{owner: owner, friend: friend, button: button}
    end

    test "owner can click their button", %{owner: owner, button: button} do
      {:ok, click} = Buttons.click_button_with_access_check(button.id, owner.id)

      assert click.button_id == button.id
      assert click.user_id == owner.id
    end

    test "friend cannot click private button", %{friend: friend, button: button} do
      result = Buttons.click_button_with_access_check(button.id, friend.id)

      assert result == {:error, :not_authorized}
    end

    test "friend can click friends-shared button", %{owner: owner, friend: friend, button: button} do
      {:ok, _} = Buttons.update_sharing_mode(button.id, owner.id, "friends")
      {:ok, click} = Buttons.click_button_with_access_check(button.id, friend.id)

      assert click.button_id == button.id
      assert click.user_id == friend.id
    end

    test "click records the correct clicker user_id", %{owner: owner, friend: friend, button: button} do
      {:ok, _} = Buttons.update_sharing_mode(button.id, owner.id, "friends")

      # Owner clicks
      {:ok, owner_click} = Buttons.click_button_with_access_check(button.id, owner.id)
      assert owner_click.user_id == owner.id

      # Friend clicks
      {:ok, friend_click} = Buttons.click_button_with_access_check(button.id, friend.id)
      assert friend_click.user_id == friend.id
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

  defp create_friendship(user1_id, user2_id) do
    # Create bidirectional friendship
    %ButtonLog.Social.Friendship{}
    |> Ecto.Changeset.cast(%{status: "accepted"}, [:status])
    |> Ecto.Changeset.put_change(:user_id, user1_id)
    |> Ecto.Changeset.put_change(:friend_id, user2_id)
    |> ButtonLog.Repo.insert!()

    %ButtonLog.Social.Friendship{}
    |> Ecto.Changeset.cast(%{status: "accepted"}, [:status])
    |> Ecto.Changeset.put_change(:user_id, user2_id)
    |> Ecto.Changeset.put_change(:friend_id, user1_id)
    |> ButtonLog.Repo.insert!()
  end
end
