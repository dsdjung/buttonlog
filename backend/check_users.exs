# Check what users exist in the system
# Run with: mix run check_users.exs

IO.puts "=== CHECKING USERS ==="

users = ButtonLog.Repo.all(ButtonLog.Accounts.User)

IO.puts "Total users: #{length(users)}"
IO.puts ""

Enum.each(users, fn user ->
  IO.puts "ID: #{user.id}"
  IO.puts "Username: #{user.username}"
  IO.puts "Display Name: #{user.display_name}"
  IO.puts "Email: #{user.email}"
  IO.puts "---"
end)

IO.puts "=== CHECK COMPLETED ==="


