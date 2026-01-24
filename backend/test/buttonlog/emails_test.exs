defmodule ButtonLog.EmailsTest do
  use ExUnit.Case, async: true

  alias ButtonLog.Emails

  describe "from_email/0" do
    test "returns default email when not configured" do
      # Clear any existing config
      Application.delete_env(:buttonlog, :email)

      assert Emails.from_email() == "noreply@buttonlog.app"
    end

    test "returns configured email when set" do
      Application.put_env(:buttonlog, :email, [
        from_address: "custom@example.com",
        from_name: "Custom Name"
      ])

      assert Emails.from_email() == "custom@example.com"

      # Clean up
      Application.delete_env(:buttonlog, :email)
    end
  end

  describe "from_name/0" do
    test "returns default name when not configured" do
      Application.delete_env(:buttonlog, :email)

      assert Emails.from_name() == "ButtonLog"
    end

    test "returns configured name when set" do
      Application.put_env(:buttonlog, :email, [
        from_address: "custom@example.com",
        from_name: "Custom Sender"
      ])

      assert Emails.from_name() == "Custom Sender"

      # Clean up
      Application.delete_env(:buttonlog, :email)
    end
  end

  describe "friend_invitation/2" do
    test "creates email with correct structure" do
      email = Emails.friend_invitation("friend@example.com", "John Doe")

      # Check basic email properties
      assert email.to == [{"", "friend@example.com"}]
      assert email.subject == "John Doe invited you to join ButtonLog!"

      # Check from address uses configured or default values
      {from_name, from_email} = email.from
      assert from_name == Emails.from_name()
      assert from_email == Emails.from_email()

      # Check HTML body contains inviter name
      assert email.html_body =~ "John Doe"
      assert email.html_body =~ "invited"
      assert email.html_body =~ "ButtonLog"

      # Check text body contains inviter name
      assert email.text_body =~ "John Doe"
      assert email.text_body =~ "invited"
    end

    test "includes app store links in email" do
      email = Emails.friend_invitation("friend@example.com", "Jane")

      # Check for app store links
      assert email.html_body =~ "apps.apple.com"
      assert email.html_body =~ "play.google.com"

      assert email.text_body =~ "apps.apple.com"
      assert email.text_body =~ "play.google.com"
    end

    test "handles special characters in inviter name" do
      email = Emails.friend_invitation("friend@example.com", "John O'Brien")

      assert email.subject == "John O'Brien invited you to join ButtonLog!"
      assert email.html_body =~ "John O'Brien"
    end
  end
end
