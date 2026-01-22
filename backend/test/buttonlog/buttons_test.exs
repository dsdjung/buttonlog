defmodule ButtonLog.ButtonsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Buttons
  alias ButtonLog.Buttons.{Button, ButtonClick}
  alias ButtonLog.Accounts

  describe "buttons" do
    setup do
      user = insert_user()
      %{user: user}
    end

    @valid_attrs %{
      name: "Test Button",
      description: "A test button",
      type: "instant",
      icon: "star",
      color: "#00BFA5"
    }

    @invalid_attrs %{name: nil, type: nil}

    test "list_user_buttons/1 returns all buttons for a user", %{user: user} do
      {:ok, button} = Buttons.create_button(@valid_attrs, user.id)
      buttons = Buttons.list_user_buttons(user.id)
      assert length(buttons) == 1
      assert hd(buttons).id == button.id
    end

    test "list_user_buttons/1 excludes archived buttons", %{user: user} do
      {:ok, button1} = Buttons.create_button(@valid_attrs, user.id)
      {:ok, button2} = Buttons.create_button(%{@valid_attrs | name: "Another Button"}, user.id)

      # Archive one button
      Buttons.update_button(button2.id, %{archived: true, archived_at: DateTime.utc_now()}, user.id)

      buttons = Buttons.list_user_buttons(user.id)
      assert length(buttons) == 1
      assert hd(buttons).id == button1.id
    end

    test "list_user_buttons/1 returns empty list for user with no buttons", %{user: user} do
      assert Buttons.list_user_buttons(user.id) == []
    end

    test "get_button/2 returns the button with given id", %{user: user} do
      {:ok, button} = Buttons.create_button(@valid_attrs, user.id)
      assert {:ok, fetched} = Buttons.get_button(button.id, user.id)
      assert fetched.id == button.id
    end

    test "get_button/2 returns error for non-existent button", %{user: user} do
      assert {:error, :not_found} = Buttons.get_button(Ecto.UUID.generate(), user.id)
    end

    test "get_button/2 returns error for button owned by another user", %{user: user} do
      other_user = insert_user()
      {:ok, button} = Buttons.create_button(@valid_attrs, other_user.id)
      assert {:error, :not_found} = Buttons.get_button(button.id, user.id)
    end
  end

  describe "create_button/2" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "creates an instant button with valid data", %{user: user} do
      attrs = %{name: "Instant Button", type: "instant", icon: "bolt", color: "#EF5350"}
      assert {:ok, %Button{} = button} = Buttons.create_button(attrs, user.id)
      assert button.name == "Instant Button"
      assert button.type == "instant"
      assert button.icon == "bolt"
      assert button.color == "#EF5350"
      assert button.is_active == true
      assert button.current_state == "idle"
      assert button.alerts_enabled == true
      assert button.auto_stop_enabled == false
      assert button.user_id == user.id
    end

    test "creates a toggle button with valid data", %{user: user} do
      attrs = %{name: "Toggle Button", type: "toggle"}
      assert {:ok, %Button{} = button} = Buttons.create_button(attrs, user.id)
      assert button.type == "toggle"
      assert button.current_state == "idle"
    end

    test "creates a one-time button with valid data", %{user: user} do
      attrs = %{name: "One-Time Button", type: "one-time"}
      assert {:ok, %Button{} = button} = Buttons.create_button(attrs, user.id)
      assert button.type == "one-time"
      assert button.archived == false
    end

    test "creates a workflow button with valid data", %{user: user} do
      attrs = %{name: "Workflow Button", type: "workflow"}
      assert {:ok, %Button{} = button} = Buttons.create_button(attrs, user.id)
      assert button.type == "workflow"
    end

    test "returns error with invalid type", %{user: user} do
      attrs = %{name: "Invalid Button", type: "invalid_type"}
      assert {:error, changeset} = Buttons.create_button(attrs, user.id)
      assert "is invalid" in errors_on(changeset).type
    end

    test "returns error with missing name", %{user: user} do
      attrs = %{type: "instant"}
      assert {:error, changeset} = Buttons.create_button(attrs, user.id)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error with name too long", %{user: user} do
      attrs = %{name: String.duplicate("a", 101), type: "instant"}
      assert {:error, changeset} = Buttons.create_button(attrs, user.id)
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end

    test "returns error with description too long", %{user: user} do
      attrs = %{name: "Button", type: "instant", description: String.duplicate("a", 501)}
      assert {:error, changeset} = Buttons.create_button(attrs, user.id)
      assert "should be at most 500 character(s)" in errors_on(changeset).description
    end

    test "returns error with invalid color format", %{user: user} do
      attrs = %{name: "Button", type: "instant", color: "red"}
      assert {:error, changeset} = Buttons.create_button(attrs, user.id)
      assert "must be a valid hex color" in errors_on(changeset).color
    end

    test "accepts valid hex colors", %{user: user} do
      attrs = %{name: "Button", type: "instant", color: "#AABBCC"}
      assert {:ok, button} = Buttons.create_button(attrs, user.id)
      assert button.color == "#AABBCC"

      attrs2 = %{name: "Button 2", type: "instant", color: "#aabbcc"}
      assert {:ok, button2} = Buttons.create_button(attrs2, user.id)
      assert button2.color == "#aabbcc"
    end
  end

  describe "update_button/3" do
    setup do
      user = insert_user()
      {:ok, button} = Buttons.create_button(%{name: "Original", type: "instant"}, user.id)
      %{user: user, button: button}
    end

    test "updates the button with valid data", %{user: user, button: button} do
      update_attrs = %{name: "Updated Name", description: "New description"}
      assert {:ok, updated} = Buttons.update_button(button.id, update_attrs, user.id)
      assert updated.name == "Updated Name"
      assert updated.description == "New description"
    end

    test "updates button icon", %{user: user, button: button} do
      assert {:ok, updated} = Buttons.update_button(button.id, %{icon: "heart"}, user.id)
      assert updated.icon == "heart"
    end

    test "updates button color", %{user: user, button: button} do
      assert {:ok, updated} = Buttons.update_button(button.id, %{color: "#FF6B6B"}, user.id)
      assert updated.color == "#FF6B6B"
    end

    test "updates alerts_enabled", %{user: user, button: button} do
      assert {:ok, updated} = Buttons.update_button(button.id, %{alerts_enabled: false}, user.id)
      assert updated.alerts_enabled == false
    end

    test "updates auto_stop settings", %{user: user, button: button} do
      attrs = %{auto_stop_enabled: true, auto_stop_minutes: 60}
      assert {:ok, updated} = Buttons.update_button(button.id, attrs, user.id)
      assert updated.auto_stop_enabled == true
      assert updated.auto_stop_minutes == 60
    end

    test "returns error for invalid auto_stop_minutes", %{user: user, button: button} do
      attrs = %{auto_stop_minutes: 45}
      assert {:error, changeset} = Buttons.update_button(button.id, attrs, user.id)
      assert "must be 15, 30, 60, 120, 240, or 480 minutes" in errors_on(changeset).auto_stop_minutes
    end

    test "accepts valid auto_stop_minutes values", %{user: user, button: button} do
      for minutes <- [15, 30, 60, 120, 240, 480] do
        {:ok, updated} = Buttons.update_button(button.id, %{auto_stop_minutes: minutes}, user.id)
        assert updated.auto_stop_minutes == minutes
      end
    end

    test "returns error for non-existent button", %{user: user} do
      assert {:error, :not_found} = Buttons.update_button(Ecto.UUID.generate(), %{name: "Test"}, user.id)
    end

    test "returns error when updating another user's button", %{button: button} do
      other_user = insert_user()
      assert {:error, :not_found} = Buttons.update_button(button.id, %{name: "Hacked"}, other_user.id)
    end
  end

  describe "delete_button/2" do
    setup do
      user = insert_user()
      {:ok, button} = Buttons.create_button(%{name: "To Delete", type: "instant"}, user.id)
      %{user: user, button: button}
    end

    test "deletes the button", %{user: user, button: button} do
      assert {:ok, %Button{}} = Buttons.delete_button(button.id, user.id)
      assert {:error, :not_found} = Buttons.get_button(button.id, user.id)
    end

    test "returns error for non-existent button", %{user: user} do
      assert {:error, :not_found} = Buttons.delete_button(Ecto.UUID.generate(), user.id)
    end

    test "returns error when deleting another user's button", %{button: button} do
      other_user = insert_user()
      assert {:error, :not_found} = Buttons.delete_button(button.id, other_user.id)
    end
  end

  describe "click_button/2 - instant button" do
    setup do
      user = insert_user()
      {:ok, button} = Buttons.create_button(%{name: "Instant", type: "instant"}, user.id)
      %{user: user, button: button}
    end

    test "records a click for instant button", %{user: user, button: button} do
      assert {:ok, %ButtonClick{} = click} = Buttons.click_button(button.id, user.id)
      assert click.button_id == button.id
      assert click.user_id == user.id
      assert click.action == "click"
    end

    test "records multiple clicks", %{user: user, button: button} do
      {:ok, _click1} = Buttons.click_button(button.id, user.id)
      {:ok, _click2} = Buttons.click_button(button.id, user.id)
      {:ok, _click3} = Buttons.click_button(button.id, user.id)

      clicks = Repo.all(from c in ButtonClick, where: c.button_id == ^button.id)
      assert length(clicks) == 3
    end

    test "returns error for non-existent button", %{user: user} do
      assert {:error, :not_found} = Buttons.click_button(Ecto.UUID.generate(), user.id)
    end
  end

  describe "click_button/2 - toggle button" do
    setup do
      user = insert_user()
      {:ok, button} = Buttons.create_button(%{name: "Toggle", type: "toggle"}, user.id)
      %{user: user, button: button}
    end

    test "starts a toggle button (idle -> active)", %{user: user, button: button} do
      assert button.current_state == "idle"

      {:ok, click} = Buttons.click_button(button.id, user.id)
      assert click.action == "start"

      {:ok, updated_button} = Buttons.get_button(button.id, user.id)
      assert updated_button.current_state == "active"
      assert updated_button.state_changed_at != nil
    end

    test "stops a toggle button (active -> idle)", %{user: user, button: button} do
      # First, start it
      {:ok, _start_click} = Buttons.click_button(button.id, user.id)

      # Then stop it
      {:ok, stop_click} = Buttons.click_button(button.id, user.id)
      assert stop_click.action == "end"

      {:ok, updated_button} = Buttons.get_button(button.id, user.id)
      assert updated_button.current_state == "idle"
    end

    test "toggle button with auto-stop sets scheduled_stop_at", %{user: user} do
      {:ok, button} = Buttons.create_button(
        %{name: "Auto-Stop Toggle", type: "toggle"},
        user.id
      )

      # Enable auto-stop on the button
      {:ok, button} = Buttons.update_button(button.id, %{auto_stop_enabled: true, auto_stop_minutes: 30}, user.id)
      assert button.auto_stop_enabled == true
      assert button.auto_stop_minutes == 30

      {:ok, _click} = Buttons.click_button(button.id, user.id)

      {:ok, updated_button} = Buttons.get_button(button.id, user.id)
      assert updated_button.current_state == "active"
      assert updated_button.scheduled_stop_at != nil
    end
  end

  describe "click_button/2 - one-time button" do
    setup do
      user = insert_user()
      {:ok, button} = Buttons.create_button(%{name: "One-Time", type: "one-time"}, user.id)
      %{user: user, button: button}
    end

    test "completes and archives a one-time button", %{user: user, button: button} do
      {:ok, click} = Buttons.click_button(button.id, user.id)
      # One-time buttons use "click" action but archive the button
      assert click.action == "click"

      {:ok, updated_button} = Buttons.get_button(button.id, user.id)
      assert updated_button.archived == true
      assert updated_button.archived_at != nil
    end
  end

  describe "button history" do
    setup do
      user = insert_user()
      {:ok, button} = Buttons.create_button(%{name: "History Test", type: "instant"}, user.id)
      %{user: user, button: button}
    end

    test "list_button_clicks/3 returns clicks for a button", %{user: user, button: button} do
      {:ok, _click1} = Buttons.click_button(button.id, user.id)
      {:ok, _click2} = Buttons.click_button(button.id, user.id)

      {:ok, history} = Buttons.list_button_clicks(button.id, user.id)
      assert length(history) == 2
    end

    test "list_button_clicks/3 returns empty list for button with no clicks", %{user: user, button: button} do
      {:ok, history} = Buttons.list_button_clicks(button.id, user.id)
      assert history == []
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
