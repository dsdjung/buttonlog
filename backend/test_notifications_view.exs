# Test script to verify notifications view functionality
# Run with: mix run test_notifications_view.exs

IO.puts "=== TESTING NOTIFICATIONS VIEW ==="

# Get the user "coscienziosgmailcom" to check their notifications
user = ButtonLog.Repo.get_by(ButtonLog.Accounts.User, username: "coscienziosgmailcom")

if user do
  IO.puts "Found user: #{user.display_name} (#{user.username})"
  IO.puts "User ID: #{user.id}"

  # Get their notifications
  notifications = ButtonLog.Notifications.get_user_notifications(user.id, 10)
  IO.puts "\nUser has #{length(notifications)} notifications:"

  Enum.each(notifications, fn notif ->
    IO.puts "  - #{notif.title}"
    IO.puts "    Message: #{notif.message}"
    IO.puts "    Type: #{notif.notification_type}"
    IO.puts "    Read: #{notif.read}"
    IO.puts "    Created: #{notif.inserted_at}"
    IO.puts "    From: #{notif.sender_id}"
    IO.puts "    Button: #{notif.button_id}"
    IO.puts ""
  end)

  # Get unread count
  unread = ButtonLog.Notifications.get_unread_notifications(user.id)
  IO.puts "Unread notifications: #{length(unread)}"

else
  IO.puts "User 'coscienzios' not found!"
end

IO.puts "\n=== TEST COMPLETED ==="
