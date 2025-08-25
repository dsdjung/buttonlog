# Test script to simulate clicking the Exercise button and test notifications
# Run with: mix run test_exercise_button.exs

import Ecto.Query

IO.puts "=== TESTING EXERCISE BUTTON NOTIFICATIONS ==="

# The Exercise button that has notifications configured
exercise_button_id = "c86afcc4-02ee-4e2e-9f36-a47a5cefb42c"
button_owner_id = "bf113d2c-dde1-42f2-a1f5-93a9a4c8f2b5"  # David

IO.puts "Testing button: Exercise (#{exercise_button_id})"
IO.puts "Button owner: David (#{button_owner_id})"

# Check current notification preferences
IO.puts "\n1. Current notification preferences for this button:"
preferences = ButtonLog.Repo.all(
  from p in ButtonLog.Notifications.ButtonNotificationPreference,
  where: p.button_id == ^exercise_button_id
)

Enum.each(preferences, fn pref ->
  IO.puts "  - User: #{pref.user_id}, Friend: #{pref.friend_id}, Enabled: #{pref.enabled}"
end)

# Check current notifications for coscienzios
coscienzios_id = "f2584b26-ec87-40c5-862d-f3690707a02e"
IO.puts "\n2. Current notifications for coscienzios:"
current_notifications = ButtonLog.Repo.all(
  from n in ButtonLog.Notifications.Notification,
  where: n.recipient_id == ^coscienzios_id
)
IO.puts "Count: #{length(current_notifications)}"

# Simulate button click and send notifications
IO.puts "\n3. Simulating button click and sending notifications..."
case ButtonLog.Notifications.send_button_click_notifications(exercise_button_id, button_owner_id, %{
  clicked_at: DateTime.utc_now(),
  platform: "test"
}) do
  {:ok, results} ->
    IO.puts "✅ Notifications sent successfully: #{length(results)}"

    # Check if new notifications were created
    IO.puts "\n4. Checking if new notifications were created..."
    new_notifications = ButtonLog.Repo.all(
      from n in ButtonLog.Notifications.Notification,
      where: n.recipient_id == ^coscienzios_id,
      order_by: [desc: n.inserted_at],
      limit: 5
    )

    IO.puts "Total notifications for coscienzios now: #{length(new_notifications)}"
    IO.puts "Recent notifications:"
    Enum.each(new_notifications, fn notif ->
      IO.puts "  - #{notif.title}"
      IO.puts "    Button: #{notif.button_id}"
      IO.puts "    Created: #{notif.inserted_at}"
      IO.puts "    Read: #{notif.read}"
      IO.puts ""
    end)

  {:error, reason} ->
    IO.puts "❌ Failed to send notifications: #{inspect(reason)}"
end

IO.puts "=== TEST COMPLETED ==="

