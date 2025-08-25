# Debug script for notification system
# Run with: mix run debug_notifications.exs

import Ecto.Query

IO.puts "=== NOTIFICATION SYSTEM DIAGNOSTIC ==="

# Check all notification preferences
IO.puts "\n1. Checking all button notification preferences..."
preferences = ButtonLog.Repo.all(ButtonLog.Notifications.ButtonNotificationPreference)
IO.puts "Total notification preferences: #{length(preferences)}"

Enum.each(preferences, fn pref ->
  IO.puts "  - Button: #{pref.button_id}, User: #{pref.user_id}, Friend: #{pref.friend_id}, Enabled: #{pref.enabled}"
end)

# Check all notifications
IO.puts "\n2. Checking all notifications..."
notifications = ButtonLog.Repo.all(ButtonLog.Notifications.Notification)
IO.puts "Total notifications: #{length(notifications)}"

Enum.each(notifications, fn notif ->
  IO.puts "  - Type: #{notif.notification_type}, Recipient: #{notif.recipient_id}, Sender: #{notif.sender_id}, Read: #{notif.read}"
end)

# Check all friendships
IO.puts "\n3. Checking all friendships..."
friendships = ButtonLog.Repo.all(ButtonLog.Social.Friendship)
IO.puts "Total friendships: #{length(friendships)}"

Enum.each(friendships, fn friendship ->
  IO.puts "  - User: #{friendship.user_id} -> Friend: #{friendship.friend_id}, Status: #{friendship.status}"
end)

# Check all users
IO.puts "\n4. Checking all users..."
users = ButtonLog.Repo.all(ButtonLog.Accounts.User)
IO.puts "Total users: #{length(users)}"

Enum.each(users, fn user ->
  IO.puts "  - ID: #{user.id}, Username: #{user.username}, Display: #{user.display_name}"
end)

# Check all buttons
IO.puts "\n5. Checking all buttons..."
buttons = ButtonLog.Repo.all(ButtonLog.Buttons.Button)
IO.puts "Total buttons: #{length(buttons)}"

Enum.each(buttons, fn button ->
  IO.puts "  - ID: #{button.id}, Name: #{button.name}, Owner: #{button.user_id}, Notifications: #{button.notifications_enabled}"
end)

# Test notification recipients for a specific button
if length(buttons) > 0 do
  button = List.first(buttons)
  IO.puts "\n6. Testing notification recipients for button: #{button.name} (#{button.id})"

  # Check if this button has any notification preferences
  button_prefs = ButtonLog.Repo.all(
    from p in ButtonLog.Notifications.ButtonNotificationPreference,
    where: p.button_id == ^button.id
  )
  IO.puts "Button notification preferences: #{length(button_prefs)}"

  # Test getting recipients
  recipients = ButtonLog.Notifications.get_notification_recipients(button.id, button.user_id)
  IO.puts "Notification recipients found: #{length(recipients)}"

  # Test sending notifications
  IO.puts "\n7. Testing notification sending..."
  case ButtonLog.Notifications.send_button_click_notifications(button.id, button.user_id, %{
    clicked_at: DateTime.utc_now(),
    platform: "debug"
  }) do
    {:ok, results} ->
      IO.puts "✅ Notifications sent successfully: #{length(results)}"
    {:error, reason} ->
      IO.puts "❌ Failed to send notifications: #{inspect(reason)}"
  end
end

IO.puts "\n=== DIAGNOSTIC COMPLETE ==="
