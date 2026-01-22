defmodule ButtonLog.GiftButtonsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Buttons
  alias ButtonLog.Alerts

  describe "create_button/2" do
    test "sends notification to creator when button is created" do
      user = insert_user(%{email: "button_creator@test.com", username: "buttoncreator"})

      button_attrs = %{
        "name" => "My New Button",
        "type" => "instant"
      }

      {:ok, button} = Buttons.create_button(button_attrs, user.id)

      # Check that a notification was sent to the creator
      alerts = Alerts.get_user_alerts(user.id)
      assert length(alerts) == 1

      alert = hd(alerts)
      assert alert.alert_type == "button_created"
      assert alert.title == "Button Created!"
      assert alert.message =~ "My New Button"
      assert alert.recipient_id == user.id
      assert alert.button_id == button.id
    end
  end

  describe "create_button_for_friend/4" do
    test "creates a button owned by the friend when users are friends" do
      creator = insert_user(%{email: "creator@test.com", username: "creator", display_name: "Creator"})
      friend = insert_user(%{email: "friend@test.com", username: "friend", display_name: "Friend"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "Morning Routine",
        "type" => "instant",
        "icon" => "sun",
        "color" => "#FFD700"
      }

      {:ok, button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id, "Try this!")

      # Button should be owned by the friend
      assert button.user_id == friend.id
      # But created by the creator
      assert button.created_by_friend_id == creator.id
      assert button.gift_message == "Try this!"
      assert button.name == "Morning Routine"
      assert button.type == "instant"
    end

    test "returns error when users are not friends" do
      creator = insert_user(%{email: "creator2@test.com", username: "creator2"})
      stranger = insert_user(%{email: "stranger@test.com", username: "stranger"})

      button_attrs = %{
        "name" => "Test Button",
        "type" => "instant"
      }

      result = Buttons.create_button_for_friend(button_attrs, stranger.id, creator.id)

      assert result == {:error, :not_friends}
    end

    test "sends notification to friend when gift button is created" do
      creator = insert_user(%{email: "creator3@test.com", username: "creator3", display_name: "The Creator"})
      friend = insert_user(%{email: "friend3@test.com", username: "friend3"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "Exercise Tracker",
        "type" => "toggle"
      }

      {:ok, _button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id)

      # Check that a notification was sent to the friend
      alerts = Alerts.get_user_alerts(friend.id)
      assert length(alerts) == 1

      alert = hd(alerts)
      assert alert.alert_type == "gift_button_received"
      assert alert.title == "New Button Gift!"
      assert alert.message =~ "The Creator"
      assert alert.message =~ "Exercise Tracker"
      assert alert.recipient_id == friend.id
      assert alert.sender_id == creator.id
    end

    test "sends notification to creator when gift button is created" do
      creator = insert_user(%{email: "creator3b@test.com", username: "creator3b", display_name: "The Creator"})
      friend = insert_user(%{email: "friend3b@test.com", username: "friend3b", display_name: "The Friend"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "Exercise Tracker",
        "type" => "toggle"
      }

      {:ok, _button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id)

      # Check that a notification was sent to the creator
      alerts = Alerts.get_user_alerts(creator.id)
      assert length(alerts) == 1

      alert = hd(alerts)
      assert alert.alert_type == "gift_button_sent"
      assert alert.title == "Gift Button Sent!"
      assert alert.message =~ "The Friend"
      assert alert.message =~ "Exercise Tracker"
      assert alert.recipient_id == creator.id
    end
  end

  describe "notify_gift_creator_of_click/2" do
    test "sends notification to creator when gift button is clicked" do
      creator = insert_user(%{email: "creator4@test.com", username: "creator4"})
      friend = insert_user(%{email: "friend4@test.com", username: "friend4", display_name: "My Friend"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "Click Test",
        "type" => "instant"
      }

      {:ok, button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id)

      # Click the button
      {:ok, _click} = Buttons.click_button(button.id, friend.id)

      # Check notification to creator
      alerts = Alerts.get_user_alerts(creator.id)
      # Should have the gift click notification
      click_alert = Enum.find(alerts, &(&1.alert_type == "gift_button_clicked"))

      assert click_alert != nil
      assert click_alert.title =~ "clicked"
      assert click_alert.message =~ "My Friend"
      assert click_alert.message =~ "Click Test"
    end

    test "sends notification with correct action for toggle button start" do
      creator = insert_user(%{email: "creator5@test.com", username: "creator5"})
      friend = insert_user(%{email: "friend5@test.com", username: "friend5", display_name: "Timer Friend"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "Sleep Timer",
        "type" => "toggle"
      }

      {:ok, button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id)

      # Click to start the timer
      {:ok, _click} = Buttons.click_button(button.id, friend.id)

      alerts = Alerts.get_user_alerts(creator.id)
      click_alert = Enum.find(alerts, &(&1.alert_type == "gift_button_clicked"))

      assert click_alert != nil
      assert click_alert.title =~ "started"
      assert click_alert.message =~ "Timer Friend"
      assert click_alert.message =~ "started"
    end

    test "does not send notification for non-gift buttons" do
      user = insert_user(%{email: "solo@test.com", username: "solo"})

      {:ok, button} = Buttons.create_button(%{"name" => "My Button", "type" => "instant"}, user.id)

      # Click the button
      {:ok, _click} = Buttons.click_button(button.id, user.id)

      # No gift click notification should exist (button has no created_by_friend_id)
      alerts = Alerts.get_user_alerts(user.id)
      gift_alerts = Enum.filter(alerts, &(&1.alert_type == "gift_button_clicked"))

      assert Enum.empty?(gift_alerts)
    end
  end

  describe "notify_gift_creator_of_deletion/1" do
    test "sends notification to creator when gift button is deleted" do
      creator = insert_user(%{email: "creator6@test.com", username: "creator6"})
      friend = insert_user(%{email: "friend6@test.com", username: "friend6", display_name: "Deleting Friend"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "Button To Delete",
        "type" => "instant"
      }

      {:ok, button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id)

      # Delete the button
      {:ok, _deleted} = Buttons.delete_button(button.id, friend.id)

      # Check notification to creator
      alerts = Alerts.get_user_alerts(creator.id)
      delete_alert = Enum.find(alerts, &(&1.alert_type == "gift_button_deleted"))

      assert delete_alert != nil
      assert delete_alert.title == "Button Removed"
      assert delete_alert.message =~ "Deleting Friend"
      assert delete_alert.message =~ "Button To Delete"
    end
  end

  describe "one-time buttons" do
    test "one-time button is archived after being clicked" do
      user = insert_user(%{email: "onetime@test.com", username: "onetimeuser"})

      button_attrs = %{
        "name" => "One-Time Task",
        "type" => "one-time"
      }

      {:ok, button} = Buttons.create_button(button_attrs, user.id)

      # Button should initially not be archived
      assert button.archived == false || is_nil(button.archived)

      # Click the button
      {:ok, _click} = Buttons.click_button(button.id, user.id)

      # Fetch the button again to check archived status
      {:ok, updated_button} = Buttons.get_button(button.id, user.id)
      assert updated_button.archived == true
      assert updated_button.archived_at != nil
    end

    test "archived one-time button does not appear in list_user_buttons" do
      user = insert_user(%{email: "onetime2@test.com", username: "onetimeuser2"})

      # Create a regular button and a one-time button
      {:ok, regular_button} = Buttons.create_button(%{"name" => "Regular", "type" => "instant"}, user.id)
      {:ok, one_time_button} = Buttons.create_button(%{"name" => "One-Time", "type" => "one-time"}, user.id)

      # Initially both should appear
      buttons = Buttons.list_user_buttons(user.id)
      button_ids = Enum.map(buttons, & &1.id)
      assert regular_button.id in button_ids
      assert one_time_button.id in button_ids

      # Click the one-time button to archive it
      {:ok, _click} = Buttons.click_button(one_time_button.id, user.id)

      # Now only the regular button should appear
      buttons_after = Buttons.list_user_buttons(user.id)
      button_ids_after = Enum.map(buttons_after, & &1.id)
      assert regular_button.id in button_ids_after
      refute one_time_button.id in button_ids_after
    end

    test "one-time button click is recorded before archiving" do
      user = insert_user(%{email: "onetime3@test.com", username: "onetimeuser3"})

      {:ok, button} = Buttons.create_button(%{"name" => "Track Once", "type" => "one-time"}, user.id)

      # Click the button
      {:ok, click} = Buttons.click_button(button.id, user.id)

      # Verify click was recorded
      assert click.button_id == button.id
      assert click.user_id == user.id
      assert click.action == "click"

      # Verify history still accessible even though button is archived
      {:ok, clicks} = Buttons.list_button_clicks(button.id, user.id)
      assert length(clicks) == 1
    end

    test "one-time button click sends completion notification to owner" do
      user = insert_user(%{email: "onetime4@test.com", username: "onetimeuser4"})

      {:ok, button} = Buttons.create_button(%{"name" => "Complete Me", "type" => "one-time"}, user.id)

      # Click the button
      {:ok, _click} = Buttons.click_button(button.id, user.id)

      # Check that a completion notification was sent to the owner
      alerts = Alerts.get_user_alerts(user.id)
      completion_alert = Enum.find(alerts, &(&1.alert_type == "one_time_button_completed"))

      assert completion_alert != nil
      assert completion_alert.title == "Task Completed!"
      assert completion_alert.message =~ "Complete Me"
      assert completion_alert.message =~ "completed and archived"
      assert completion_alert.recipient_id == user.id
    end

    test "gift one-time button notifies both owner and creator on click" do
      creator = insert_user(%{email: "creator_onetime@test.com", username: "creator_onetime"})
      friend = insert_user(%{email: "friend_onetime@test.com", username: "friend_onetime", display_name: "One Time Friend"})
      create_friendship(creator.id, friend.id)

      button_attrs = %{
        "name" => "One-Time Gift",
        "type" => "one-time"
      }

      {:ok, button} = Buttons.create_button_for_friend(button_attrs, friend.id, creator.id)

      # Click the button
      {:ok, _click} = Buttons.click_button(button.id, friend.id)

      # Check notification was sent to creator (gift_button_clicked)
      creator_alerts = Alerts.get_user_alerts(creator.id)
      creator_alert = Enum.find(creator_alerts, &(&1.alert_type == "gift_button_clicked"))

      assert creator_alert != nil
      assert creator_alert.title =~ "completed"
      assert creator_alert.message =~ "One Time Friend"
      assert creator_alert.message =~ "One-Time Gift"
      assert creator_alert.message =~ "completed"

      # Check notification was sent to owner (one_time_button_completed)
      owner_alerts = Alerts.get_user_alerts(friend.id)
      owner_alert = Enum.find(owner_alerts, &(&1.alert_type == "one_time_button_completed"))

      assert owner_alert != nil
      assert owner_alert.title == "Task Completed!"
      assert owner_alert.message =~ "One-Time Gift"
      assert owner_alert.message =~ "completed and archived"

      # Verify button is archived
      {:ok, updated_button} = Buttons.get_button(button.id, friend.id)
      assert updated_button.archived == true
    end
  end

  describe "list_gift_buttons_for_friend/2" do
    test "returns buttons created by user for a specific friend" do
      creator = insert_user(%{email: "list_creator@test.com", username: "list_creator"})
      friend = insert_user(%{email: "list_friend@test.com", username: "list_friend"})
      other_friend = insert_user(%{email: "other_friend@test.com", username: "other_friend"})
      create_friendship(creator.id, friend.id)
      create_friendship(creator.id, other_friend.id)

      # Create buttons for friend
      {:ok, button1} = Buttons.create_button_for_friend(%{"name" => "Gift 1", "type" => "instant"}, friend.id, creator.id)
      {:ok, button2} = Buttons.create_button_for_friend(%{"name" => "Gift 2", "type" => "toggle"}, friend.id, creator.id, "A message")

      # Create button for other_friend (should not appear)
      {:ok, _other_button} = Buttons.create_button_for_friend(%{"name" => "Other Gift", "type" => "instant"}, other_friend.id, creator.id)

      # Get gift buttons for friend
      gift_buttons = Buttons.list_gift_buttons_for_friend(creator.id, friend.id)

      assert length(gift_buttons) == 2
      button_ids = Enum.map(gift_buttons, & &1.id)
      assert button1.id in button_ids
      assert button2.id in button_ids
    end

    test "includes archived buttons in the list" do
      creator = insert_user(%{email: "archive_list_creator@test.com", username: "archive_list_creator"})
      friend = insert_user(%{email: "archive_list_friend@test.com", username: "archive_list_friend"})
      create_friendship(creator.id, friend.id)

      # Create a one-time button and click it to archive
      {:ok, button} = Buttons.create_button_for_friend(%{"name" => "One-Time Gift", "type" => "one-time"}, friend.id, creator.id)
      {:ok, _click} = Buttons.click_button(button.id, friend.id)

      # Get gift buttons - should include archived
      gift_buttons = Buttons.list_gift_buttons_for_friend(creator.id, friend.id)

      assert length(gift_buttons) == 1
      assert hd(gift_buttons).archived == true
    end

    test "returns empty list when no gift buttons exist" do
      creator = insert_user(%{email: "empty_creator@test.com", username: "empty_creator"})
      friend = insert_user(%{email: "empty_friend@test.com", username: "empty_friend"})
      create_friendship(creator.id, friend.id)

      gift_buttons = Buttons.list_gift_buttons_for_friend(creator.id, friend.id)

      assert gift_buttons == []
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
