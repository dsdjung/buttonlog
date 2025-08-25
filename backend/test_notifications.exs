# Test script for the notification system
# Run with: mix run test_notifications.exs

# Set up default notification permissions for existing friendships
IO.puts "Setting up notification permissions for existing friendships..."
case ButtonLog.Social.create_default_notification_permissions_for_friendships() do
  {:ok, count} ->
    IO.puts "✅ Created notification permissions for #{count} friendships"
  {:error, reason} ->
    IO.puts "❌ Failed to create notification permissions: #{inspect(reason)}"
end

# Get some real user and button IDs from the database
IO.puts "\nGetting real user and button IDs..."
users = ButtonLog.Repo.all(ButtonLog.Accounts.User)
buttons = ButtonLog.Repo.all(ButtonLog.Buttons.Button)

if length(users) >= 2 and length(buttons) >= 1 do
  user1 = List.first(users)
  user2 = List.last(users)
  button = List.first(buttons)

  IO.puts "Using user1: #{user1.id} (#{user1.username})"
  IO.puts "Using user2: #{user2.id} (#{user2.username})"
  IO.puts "Using button: #{button.id} (#{button.name}) - owned by user: #{button.user_id}"

  # Test notification creation
  IO.puts "\nTesting notification creation..."
  case ButtonLog.Notifications.create_notification(%{
    notification_type: "button_click",
    title: "Test Button Clicked!",
    message: "This is a test notification",
    clicked_at: DateTime.utc_now()
  }, user1.id, user2.id, button.id) do
    {:ok, notification} ->
      IO.puts "✅ Test notification created successfully: #{inspect(notification)}"
    {:error, reason} ->
      IO.puts "❌ Failed to create test notification: #{inspect(reason)}"
  end

  # Test getting notification recipients
  IO.puts "\nTesting notification recipients..."
  recipients = ButtonLog.Notifications.get_notification_recipients(button.id, button.user_id)
  IO.puts "Found #{length(recipients)} notification recipients"

  # Test sending button click notifications
  IO.puts "\nTesting button click notifications..."
  case ButtonLog.Notifications.send_button_click_notifications(button.id, button.user_id, %{
    clicked_at: DateTime.utc_now(),
    platform: "test"
  }) do
    {:ok, results} ->
      IO.puts "✅ Button click notifications sent: #{inspect(results)}"
    {:error, reason} ->
      IO.puts "❌ Failed to send button click notifications: #{inspect(reason)}"
  end
else
  IO.puts "❌ Need at least 2 users and 1 button to test notifications"
  IO.puts "Users found: #{length(users)}"
  IO.puts "Buttons found: #{length(buttons)}"
end

IO.puts "\n🎉 Notification system test completed!"
