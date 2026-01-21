# Test script to verify button clicks from show page now send notifications
# Run with: mix run test_button_show_click.exs

import Ecto.Query

IO.puts "=== TESTING BUTTON SHOW PAGE CLICKS ==="

# Test the "Had Vitamin" button (which has notifications configured)
button_id = "22da3367-26ff-459f-b6a7-2654de40b40d"  # Had Vitamin
button_owner_id = "bf113d2c-dde1-42f2-a1f5-93a9a4c8f2b5"  # David

IO.puts "Testing button: Had Vitamin (#{button_id})"
IO.puts "Button owner: David (#{button_owner_id})"

# Check current notifications for coscienzios
coscienzios_id = "f2584b26-ec87-40c5-862d-f3690707a02e"
IO.puts "\n1. Current notifications for coscienzios:"
current_notifications = ButtonLog.Repo.all(
  from n in ButtonLog.Notifications.Notification,
  where: n.recipient_id == ^coscienzios_id,
  order_by: [desc: n.inserted_at]
)
IO.puts "Count: #{length(current_notifications)}"

# Simulate button click (this is what the show page does)
IO.puts "\n2. Simulating button click from show page..."
case ButtonLog.Buttons.click_button(button_id, button_owner_id) do
  {:ok, click} ->
    IO.puts "✅ Button clicked successfully"
    IO.puts "Click action: #{click.action}"
    IO.puts "Click time: #{click.clicked_at}"

    # Now send notifications (this is what we just added to the show page)
    IO.puts "\n3. Sending notifications to friends..."
    case ButtonLog.Notifications.send_button_click_notifications(button_id, button_owner_id, %{
      clicked_at: click.clicked_at,
      action: click.action,
      platform: click.platform
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

  {:error, reason} ->
    IO.puts "❌ Failed to click button: #{inspect(reason)}"
end

IO.puts "=== TEST COMPLETED ==="


