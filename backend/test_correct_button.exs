# Test script for the button that actually has notification preferences
# Run with: mix run test_correct_button.exs

import Ecto.Query

IO.puts "=== TESTING BUTTON WITH ACTUAL NOTIFICATION PREFERENCES ==="

# The button that has notification preferences configured
button_id = "22da3367-26ff-459f-b6a7-2654de40b40d"  # "Had Vitamin"
user_id = "bf113d2c-dde1-42f2-a1f5-93a9a4c8f2b5"   # David (button owner)

IO.puts "Testing button: Had Vitamin (#{button_id})"
IO.puts "Button owner: David (#{user_id})"

# Check notification preferences for this button
IO.puts "\n1. Checking notification preferences..."
preferences = ButtonLog.Repo.all(
  from p in ButtonLog.Notifications.ButtonNotificationPreference,
  where: p.button_id == ^button_id
)

IO.puts "Found #{length(preferences)} notification preferences:"
Enum.each(preferences, fn pref ->
  IO.puts "  - Friend: #{pref.friend_id}, Enabled: #{pref.enabled}"
end)

# Test getting notification recipients
IO.puts "\n2. Testing notification recipients..."
recipients = ButtonLog.Notifications.get_notification_recipients(button_id, user_id)
IO.puts "Notification recipients found: #{length(recipients)}"

# Test sending button click notifications
IO.puts "\n3. Testing notification sending..."
case ButtonLog.Notifications.send_button_click_notifications(button_id, user_id, %{
  clicked_at: DateTime.utc_now(),
  platform: "test"
}) do
  {:ok, results} ->
    IO.puts "✅ Notifications sent successfully: #{length(results)}"

    # Check if notifications were actually created
    IO.puts "\n4. Checking if notifications were created..."
    recent_notifications = ButtonLog.Repo.all(
      from n in ButtonLog.Notifications.Notification,
      where: n.button_id == ^button_id,
      order_by: [desc: n.inserted_at],
      limit: 5
    )

    IO.puts "Recent notifications for this button: #{length(recent_notifications)}"
    Enum.each(recent_notifications, fn notif ->
      IO.puts "  - Type: #{notif.notification_type}, Recipient: #{notif.recipient_id}, Read: #{notif.read}, Created: #{notif.inserted_at}"
    end)

  {:error, reason} ->
    IO.puts "❌ Failed to send notifications: #{inspect(reason)}"
end

IO.puts "\n🎉 Test completed!"
