# Debug script for new button notifications
# Run with: mix run debug_new_button_notifications.exs

import Ecto.Query

IO.puts "=== DEBUGGING NEW BUTTON NOTIFICATIONS ==="

# Get all notification preferences
IO.puts "\n1. All Button Notification Preferences:"
preferences = ButtonLog.Repo.all(ButtonLog.Notifications.ButtonNotificationPreference)
IO.puts "Total preferences: #{length(preferences)}"

Enum.each(preferences, fn pref ->
  IO.puts "  - Button ID: #{pref.button_id}"
  IO.puts "    User ID: #{pref.user_id}"
  IO.puts "    Friend ID: #{pref.friend_id}"
  IO.puts "    Enabled: #{pref.enabled}"
  IO.puts "    Type: #{pref.notification_type}"
  IO.puts ""
end)

# Get all notifications
IO.puts "\n2. All Notifications:"
notifications = ButtonLog.Repo.all(ButtonLog.Notifications.Notification)
IO.puts "Total notifications: #{length(notifications)}"

Enum.each(notifications, fn notif ->
  IO.puts "  - ID: #{notif.id}"
  IO.puts "    Type: #{notif.notification_type}"
  IO.puts "    Title: #{notif.title}"
  IO.puts "    Recipient: #{notif.recipient_id}"
  IO.puts "    Sender: #{notif.sender_id}"
  IO.puts "    Button: #{notif.button_id}"
  IO.puts "    Read: #{notif.read}"
  IO.puts "    Created: #{notif.inserted_at}"
  IO.puts ""
end)

# Get all buttons
IO.puts "\n3. All Buttons:"
buttons = ButtonLog.Repo.all(ButtonLog.Buttons.Button)
IO.puts "Total buttons: #{length(buttons)}"

Enum.each(buttons, fn button ->
  IO.puts "  - ID: #{button.id}"
  IO.puts "    Name: #{button.name}"
  IO.puts "    Owner: #{button.user_id}"
  IO.puts "    Notifications Enabled: #{button.notifications_enabled}"
  IO.puts ""
end)

# Check specific user notifications
coscienzios_id = "f2584b26-ec87-40c5-862d-f3690707a02e"
IO.puts "\n4. Notifications for coscienzios (ID: #{coscienzios_id}):"
user_notifications = ButtonLog.Repo.all(
  from n in ButtonLog.Notifications.Notification,
  where: n.recipient_id == ^coscienzios_id,
  order_by: [desc: n.inserted_at]
)

IO.puts "User has #{length(user_notifications)} notifications:"
Enum.each(user_notifications, fn notif ->
  IO.puts "  - #{notif.title}"
  IO.puts "    Button ID: #{notif.button_id}"
  IO.puts "    Created: #{notif.inserted_at}"
  IO.puts ""
end)

# Check which buttons have notification preferences for coscienzios
IO.puts "\n5. Buttons configured to notify coscienzios:"
buttons_for_coscienzios = ButtonLog.Repo.all(
  from p in ButtonLog.Notifications.ButtonNotificationPreference,
  where: p.friend_id == ^coscienzios_id and p.enabled == true,
  preload: [:button]
)

IO.puts "Found #{length(buttons_for_coscienzios)} buttons configured to notify coscienzios:"
Enum.each(buttons_for_coscienzios, fn pref ->
  IO.puts "  - Button: #{pref.button.name} (ID: #{pref.button.id})"
  IO.puts "    Owner: #{pref.user_id}"
  IO.puts "    Enabled: #{pref.enabled}"
  IO.puts ""
end)

IO.puts "=== DEBUG COMPLETED ==="


