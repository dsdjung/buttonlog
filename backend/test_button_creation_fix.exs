# Test script to verify button creation now works with latest_click_at field
# Run with: mix run test_button_creation_fix.exs

import Ecto.Query

IO.puts "=== TESTING BUTTON CREATION FIX ==="

# Test user ID
user_id = "bf113d2c-dde1-42f2-a1f5-93a9a4c8f2b5"  # David

IO.puts "Testing for user: David (#{user_id})"

# Test 1: Create a new button
IO.puts "\n1. Creating a new test button..."
button_params = %{
  "name" => "Test Button Creation",
  "type" => "instant",
  "icon" => "🧪",
  "color" => "#FF6B6B",
  "description" => "Testing button creation with latest_click_at field"
}

case ButtonLog.Buttons.create_button(button_params, user_id) do
  {:ok, button} ->
    IO.puts "✅ Button created successfully!"
    IO.puts "  ID: #{button.id}"
    IO.puts "  Name: #{button.name}"
    IO.puts "  Type: #{button.type}"

    # Test 2: Get the button with latest_click_at structure
    IO.puts "\n2. Getting button with latest_click_at structure..."
    buttons = ButtonLog.Buttons.list_user_buttons(user_id)
    new_button = Enum.find(buttons, &(&1.id == button.id))

    if new_button do
      IO.puts "✅ Button found in list with proper structure!"
      IO.puts "  latest_click_at: #{new_button.latest_click_at}"
      IO.puts "  updated_at: #{new_button.updated_at}"
      IO.puts "  inserted_at: #{new_button.inserted_at}"

      # Test 3: Verify the button can be displayed without errors
      IO.puts "\n3. Testing button display compatibility..."
      try do
        # Simulate what the template would do
        if new_button.latest_click_at do
          IO.puts "  ✅ latest_click_at field exists and is accessible"
        else
          IO.puts "  ✅ latest_click_at field exists but is nil (expected for new buttons)"
        end

        # Test template rendering logic
        display_text = if new_button.latest_click_at do
          "Last clicked: #{new_button.latest_click_at}"
        else
          "Never clicked"
        end

        IO.puts "  ✅ Template rendering works: #{display_text}"

      rescue
        error ->
          IO.puts "  ❌ Error accessing latest_click_at: #{inspect(error)}"
      end

    else
      IO.puts "❌ Button not found in list after creation"
    end

    # Test 4: Click the button to verify latest_click_at updates
    IO.puts "\n4. Testing button click to verify latest_click_at updates..."
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

    # Clean up: Delete the test button
    IO.puts "\n5. Cleaning up test button..."
    case ButtonLog.Buttons.delete_button(button.id, user_id) do
      {:ok, _} ->
        IO.puts "✅ Test button deleted successfully"
      {:error, reason} ->
        IO.puts "❌ Failed to delete test button: #{inspect(reason)}"
    end

  {:error, reason} ->
    IO.puts "❌ Failed to create button: #{inspect(reason)}"
end

IO.puts "\n=== TEST COMPLETED ==="

