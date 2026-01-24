defmodule ButtonLog.MailerTest do
  use ExUnit.Case, async: true

  alias ButtonLog.Mailer
  alias ButtonLog.Emails

  describe "mailer configuration" do
    test "mailer module is configured with swoosh" do
      # Verify the mailer uses Swoosh
      assert function_exported?(Mailer, :deliver, 1)
      assert function_exported?(Mailer, :deliver, 2)
    end

    test "can build and prepare an email for delivery" do
      # Build an email
      email = Emails.friend_invitation("test@example.com", "Test User")

      # Verify it's a valid Swoosh email struct
      assert %Swoosh.Email{} = email
      assert email.to == [{"", "test@example.com"}]
      assert email.subject =~ "Test User"
    end
  end

  describe "local adapter in test environment" do
    test "uses Local adapter in test/dev environments" do
      # In test environment, the adapter should be Local (or Test)
      config = Application.get_env(:buttonlog, ButtonLog.Mailer, [])
      adapter = Keyword.get(config, :adapter)

      # Should be Local adapter in non-production environments
      assert adapter in [Swoosh.Adapters.Local, Swoosh.Adapters.Test, nil]
    end
  end
end
