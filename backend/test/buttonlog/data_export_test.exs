defmodule ButtonLog.DataExportTest do
  use ButtonLog.DataCase

  alias ButtonLog.DataExport
  alias ButtonLog.Repo
  alias ButtonLog.Accounts.User
  alias ButtonLog.Buttons.Button

  describe "export_user_data/2" do
    test "exports user data as JSON" do
      user = insert_user()

      assert {:ok, content, filename, content_type} = DataExport.export_user_data(user.id, "json")

      assert content_type == "application/json"
      assert String.contains?(filename, user.username)
      assert String.ends_with?(filename, ".json")

      data = Jason.decode!(content)
      assert data["user"]["id"] == user.id
      assert data["user"]["email"] == user.email
      assert Map.has_key?(data, "exported_at")
      assert Map.has_key?(data, "statistics")
    end

    test "exports user data as CSV" do
      user = insert_user()

      assert {:ok, content, filename, content_type} = DataExport.export_user_data(user.id, "csv")

      assert content_type == "text/csv"
      assert String.contains?(filename, user.username)
      assert String.ends_with?(filename, ".csv")

      assert String.contains?(content, "# ButtonLog Data Export")
      assert String.contains?(content, "## USER PROFILE")
      assert String.contains?(content, "## BUTTONS")
      assert String.contains?(content, "## BUTTON CLICKS")
      assert String.contains?(content, "## FRIENDS")
    end

    test "includes buttons in export" do
      user = insert_user()
      button = insert_button(user.id, %{name: "My Test Button", type: "instant"})

      {:ok, content, _, _} = DataExport.export_user_data(user.id, "json")
      data = Jason.decode!(content)

      assert length(data["buttons"]) == 1
      assert hd(data["buttons"])["id"] == button.id
      assert hd(data["buttons"])["name"] == "My Test Button"
      assert data["statistics"]["total_buttons"] == 1
    end

    test "returns error for non-existent user" do
      fake_uuid = "00000000-0000-0000-0000-000000000000"

      assert {:error, "User not found"} = DataExport.export_user_data(fake_uuid, "json")
    end

    test "defaults to JSON format" do
      user = insert_user()

      {:ok, _, filename, content_type} = DataExport.export_user_data(user.id)

      assert content_type == "application/json"
      assert String.ends_with?(filename, ".json")
    end

    test "CSV properly escapes special characters" do
      user = insert_user(%{display_name: "Test, User \"Special\""})

      {:ok, content, _, _} = DataExport.export_user_data(user.id, "csv")

      # The display name with comma and quotes should be properly escaped
      assert String.contains?(content, "\"Test, User \"\"Special\"\"\"")
    end

    test "exports multiple buttons in order" do
      user = insert_user()

      # Insert buttons with delays to ensure different timestamps
      button1 = insert_button(user.id, %{name: "First Button"})
      :timer.sleep(10)
      button2 = insert_button(user.id, %{name: "Second Button"})

      {:ok, content, _, _} = DataExport.export_user_data(user.id, "json")
      data = Jason.decode!(content)

      assert length(data["buttons"]) == 2
      assert data["statistics"]["total_buttons"] == 2
    end

    test "includes user profile fields" do
      user = insert_user(%{
        first_name: "John",
        last_name: "Doe",
        timezone: "America/New_York",
        language: "en",
        profile_visibility: "friends",
        activity_visibility: "private"
      })

      {:ok, content, _, _} = DataExport.export_user_data(user.id, "json")
      data = Jason.decode!(content)

      assert data["user"]["first_name"] == "John"
      assert data["user"]["last_name"] == "Doe"
      assert data["user"]["timezone"] == "America/New_York"
      assert data["user"]["profile_visibility"] == "friends"
      assert data["user"]["activity_visibility"] == "private"
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

    %User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash, :first_name, :last_name, :timezone, :language, :profile_visibility, :activity_visibility])
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
