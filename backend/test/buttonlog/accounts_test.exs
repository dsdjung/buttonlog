defmodule ButtonLog.AccountsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Accounts
  alias ButtonLog.Accounts.User

  describe "users" do
    @valid_attrs %{
      email: "test@example.com",
      username: "testuser",
      display_name: "Test User",
      password: "password123!",
      password_confirmation: "password123!"
    }

    @invalid_attrs %{email: nil, username: nil, password: nil}

    test "list_users/0 returns all users" do
      user = insert_user()
      users = Accounts.list_users()
      assert Enum.any?(users, &(&1.id == user.id))
    end

    test "get_user!/1 returns the user with given id" do
      user = insert_user()
      assert Accounts.get_user!(user.id).id == user.id
    end

    test "get_user/1 returns the user with given id" do
      user = insert_user()
      assert Accounts.get_user(user.id).id == user.id
    end

    test "get_user/1 returns nil for non-existent user" do
      assert Accounts.get_user(Ecto.UUID.generate()) == nil
    end

    test "get_user_by_email/1 returns the user with given email" do
      user = insert_user(%{email: "unique@example.com"})
      assert Accounts.get_user_by_email("unique@example.com").id == user.id
    end

    test "get_user_by_email/1 returns nil for non-existent email" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end

    test "get_user_by_username/1 returns the user with given username" do
      user = insert_user(%{username: "uniqueuser"})
      assert Accounts.get_user_by_username("uniqueuser").id == user.id
    end

    test "get_user_by_username/1 returns nil for non-existent username" do
      assert Accounts.get_user_by_username("nonexistent") == nil
    end
  end

  describe "register_user/1" do
    test "creates a user with valid data" do
      assert {:ok, %User{} = user} = Accounts.register_user(@valid_attrs)
      assert user.email == "test@example.com"
      assert user.username == "testuser"
      assert user.display_name == "Test User"
      assert user.password_hash != nil
      assert user.onboarding_completed == false
    end

    test "auto-generates username and display_name from email" do
      # Use a unique email to avoid collisions with existing users
      unique_id = System.unique_integer([:positive])
      attrs = %{
        email: "autogen#{unique_id}@example.com",
        password: "password123!",
        password_confirmation: "password123!"
      }
      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.email == "autogen#{unique_id}@example.com"
      # Username should be generated from the email prefix
      assert String.starts_with?(user.username, "autogen#{unique_id}")
      assert user.display_name == "autogen#{unique_id}"
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(@invalid_attrs)
    end

    test "returns error for invalid email format" do
      attrs = Map.put(@valid_attrs, :email, "invalid-email")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "has invalid format" in errors_on(changeset).email
    end

    test "returns error for duplicate email" do
      insert_user(%{email: "duplicate@example.com"})
      attrs = Map.put(@valid_attrs, :email, "duplicate@example.com")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "returns error for duplicate username" do
      insert_user(%{username: "duplicateuser"})
      attrs = Map.put(@valid_attrs, :username, "duplicateuser")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "has already been taken" in errors_on(changeset).username
    end

    test "returns error for short username" do
      attrs = Map.put(@valid_attrs, :username, "ab")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "returns error for mismatched password confirmation" do
      attrs = Map.put(@valid_attrs, :password_confirmation, "different123!")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "does not match confirmation" in errors_on(changeset).password_confirmation
    end

    test "returns error for short password" do
      attrs = @valid_attrs
             |> Map.put(:password, "short")
             |> Map.put(:password_confirmation, "short")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "hashes the password" do
      assert {:ok, user} = Accounts.register_user(@valid_attrs)
      assert user.password_hash != nil
      assert user.password_hash != @valid_attrs.password
      assert Bcrypt.verify_pass(@valid_attrs.password, user.password_hash)
    end
  end

  describe "create_user/1" do
    test "creates a user with valid data" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "test@example.com"
    end
  end

  describe "update_user/2" do
    test "updates the user with valid data" do
      user = insert_user()
      update_attrs = %{display_name: "Updated Name"}

      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, update_attrs)
      assert updated_user.display_name == "Updated Name"
    end

    test "updates user timezone" do
      user = insert_user()
      assert {:ok, updated_user} = Accounts.update_user(user, %{timezone: "America/New_York"})
      assert updated_user.timezone == "America/New_York"
    end

    test "updates user language" do
      user = insert_user()
      assert {:ok, updated_user} = Accounts.update_user(user, %{language: "es"})
      assert updated_user.language == "es"
    end

    test "updates privacy settings" do
      user = insert_user()
      attrs = %{
        profile_visibility: "friends",
        activity_visibility: "private",
        allow_friend_requests: false
      }
      assert {:ok, updated_user} = Accounts.update_user(user, attrs)
      assert updated_user.profile_visibility == "friends"
      assert updated_user.activity_visibility == "private"
      assert updated_user.allow_friend_requests == false
    end

    test "updates onboarding_completed" do
      user = insert_user()
      assert {:ok, updated_user} = Accounts.update_user(user, %{onboarding_completed: true})
      assert updated_user.onboarding_completed == true
    end

    test "returns error for invalid profile_visibility" do
      user = insert_user()
      assert {:error, changeset} = Accounts.update_user(user, %{profile_visibility: "invalid"})
      assert "is invalid" in errors_on(changeset).profile_visibility
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = insert_user()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end
  end

  describe "authenticate_user/2" do
    test "returns user with valid credentials" do
      password = "validpassword123!"
      user = insert_user(%{password: password, password_confirmation: password})

      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.email, password)
      assert authenticated_user.id == user.id
    end

    test "returns error with wrong password" do
      user = insert_user(%{password: "correctpassword!", password_confirmation: "correctpassword!"})

      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, "wrongpassword")
    end

    test "returns error with non-existent email" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("nonexistent@example.com", "anypassword")
    end

    test "is case-sensitive for password" do
      password = "CaseSensitive123!"
      user = insert_user(%{password: password, password_confirmation: password})

      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, "casesensitive123!")
    end
  end

  describe "change_user/2" do
    test "returns a user changeset" do
      user = insert_user()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "get_public_profile/1" do
    test "returns public profile information" do
      user = insert_user(%{display_name: "Public User", avatar: "avatar.jpg"})
      profile = Accounts.get_public_profile(user.id)

      assert profile.id == user.id
      assert profile.display_name == "Public User"
      assert profile.avatar == "avatar.jpg"
      # Should not include sensitive info
      refute Map.has_key?(profile, :email)
      refute Map.has_key?(profile, :password_hash)
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
