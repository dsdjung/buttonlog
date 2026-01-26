# Script to set passwords for test accounts
# Run with: cd backend && source .env && mix run priv/repo/scripts/set_test_passwords.exs
#
# This sets passwords for the integration test accounts so they can authenticate
# via the password-based login endpoint for testing purposes.

alias ButtonLog.Accounts.User
alias ButtonLog.Repo

# Password to set for all test accounts
test_password = "Test123!"

# Test accounts that need passwords
test_emails = [
  "dsdjungtest1@gmail.com",  # Android test account
  "dsdjungtest@gmail.com"     # iOS test account
]

IO.puts("\n=== Setting Test Account Passwords ===\n")

for email <- test_emails do
  case Repo.get_by(User, email: email) do
    nil ->
      IO.puts("❌ User not found: #{email}")

    user ->
      changeset = User.password_changeset(user, %{
        password: test_password,
        password_confirmation: test_password
      })

      case Repo.update(changeset) do
        {:ok, _user} ->
          IO.puts("✅ Password set for: #{email}")

        {:error, changeset} ->
          IO.puts("❌ Failed to set password for #{email}: #{inspect(changeset.errors)}")
      end
  end
end

IO.puts("\n=== Done ===")
IO.puts("Test accounts can now login with password: #{test_password}\n")
