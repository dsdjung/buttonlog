# Test script to verify buttons now include latest click time
# Run with: mix run test_button_latest_click.exs

import Ecto.Query

IO.puts "=== TESTING BUTTON LATEST CLICK TIME ==="

# Test user ID
user_id = "bf113d2c-dde1-42f2-a1f5-93a9a4c8f2b5"  # David

IO.puts "Testing for user: David (#{user_id})"

# Get buttons with latest click time
IO.puts "\n1. Getting buttons with latest click time..."
buttons = ButtonLog.Buttons.list_user_buttons(user_id)

IO.puts "Found #{length(buttons)} buttons:"
Enum.each(buttons, fn button ->
  IO.puts "  - #{button.name}"
  IO.puts "    ID: #{button.id}"
  IO.puts "    Type: #{button.type}"
  IO.puts "    Latest click: #{button.latest_click_at}"
  IO.puts "    Updated at: #{button.updated_at}"
  IO.puts "    Inserted at: #{button.inserted_at}"
  IO.puts ""
end)

# Test specific button clicks
IO.puts "\n2. Testing button clicks to verify latest_click_at updates..."
if length(buttons) > 0 do
  button = List.first(buttons)
  IO.puts "Testing button: #{button.name} (#{button.id})"
  IO.puts "Current latest_click_at: #{button.latest_click_at}"

  # Click the button
  case ButtonLog.Buttons.click_button(button.id, user_id) do
    {:ok, click} ->
      IO.puts "✅ Button clicked successfully at: #{click.clicked_at}"

      # Get updated button list
      updated_buttons = ButtonLog.Buttons.list_user_buttons(user_id)
      updated_button = Enum.find(updated_buttons, &(&1.id == button.id))

      IO.puts "Updated latest_click_at: #{updated_button.latest_click_at}"
      IO.puts "Click time matches: #{updated_button.latest_click_at == click.clicked_at}"

    {:error, reason} ->
      IO.puts "❌ Failed to click button: #{inspect(reason)}"
  end
end

IO.puts "\n=== TEST COMPLETED ==="

