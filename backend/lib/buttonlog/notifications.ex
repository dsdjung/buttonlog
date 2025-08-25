defmodule ButtonLog.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Notifications.{Notification, ButtonNotificationPreference, FriendNotificationPermission}

  # Button Notification Preferences

  @doc """
  Gets notification settings for a specific button.
  """
  def get_button_notification_settings(button_id) do
    Repo.all(
      from p in ButtonNotificationPreference,
      where: p.button_id == ^button_id,
      preload: [:friend]
    )
  end

  @doc """
  Gets notification preferences for a specific button and user.
  """
  def get_button_notification_preferences(button_id, user_id) do
    Repo.all(
      from p in ButtonNotificationPreference,
      where: p.button_id == ^button_id and p.user_id == ^user_id,
      preload: [:friend]
    )
  end

  @doc """
  Toggles notification setting for a specific friend and button.
  """
  def toggle_button_friend_notification(button_id, user_id, friend_id) do
    case Repo.get_by(ButtonNotificationPreference,
                     button_id: button_id,
                     user_id: user_id,
                     friend_id: friend_id) do
      nil ->
        # Create new preference
        %ButtonNotificationPreference{}
        |> ButtonNotificationPreference.create_changeset(%{enabled: true}, button_id, user_id, friend_id)
        |> Repo.insert()

      preference ->
        # Toggle existing preference
        preference
        |> ButtonNotificationPreference.changeset(%{enabled: !preference.enabled})
        |> Repo.update()
    end
  end

  @doc """
  Sets notification preference for a specific friend and button.
  """
  def set_button_friend_notification(button_id, user_id, friend_id, enabled, notification_type \\ "click") do
    case Repo.get_by(ButtonNotificationPreference,
                     button_id: button_id,
                     user_id: user_id,
                     friend_id: friend_id) do
      nil ->
        # Create new preference
        %ButtonNotificationPreference{}
        |> ButtonNotificationPreference.create_changeset(%{enabled: enabled, notification_type: notification_type},
                                                      button_id, user_id, friend_id)
        |> Repo.insert()

      preference ->
        # Update existing preference
        preference
        |> ButtonNotificationPreference.changeset(%{enabled: enabled, notification_type: notification_type})
        |> Repo.update()
    end
  end

  @doc """
  Gets all friends who should be notified for a specific button click.
  """
  def get_notification_recipients(button_id, user_id) do
    IO.puts "=== GET NOTIFICATION RECIPIENTS DEBUG ==="
    IO.puts "button_id: #{button_id}"
    IO.puts "user_id: #{user_id}"

    # For now, just get enabled notification preferences without permission checks
    # We'll add permission checks later when the system is working
    preferences = Repo.all(
      from p in ButtonNotificationPreference,
      where: p.button_id == ^button_id and p.user_id == ^user_id and p.enabled == true,
      preload: [:friend]
    )

    IO.puts "Found #{length(preferences)} enabled notification preferences"

    recipients = Enum.map(preferences, fn preference ->
      IO.puts "Friend #{preference.friend.display_name} (#{preference.friend.id}) will be notified"
      preference.friend
    end)

    IO.puts "Total recipients: #{length(recipients)}"
    recipients
  end

  # Notification History

  @doc """
  Creates a new notification.
  """
  def create_notification(attrs, recipient_id, sender_id, button_id) do
    IO.puts "=== CREATE NOTIFICATION DEBUG ==="
    IO.puts "attrs: #{inspect(attrs)}"
    IO.puts "recipient_id: #{recipient_id}"
    IO.puts "sender_id: #{sender_id}"
    IO.puts "button_id: #{button_id}"

    changeset = %Notification{}
    |> Notification.create_changeset(attrs, recipient_id, sender_id, button_id)

    IO.puts "Changeset valid?: #{changeset.valid?}"
    if not changeset.valid? do
      IO.puts "Changeset errors: #{inspect(changeset.errors)}"
    end

    result = Repo.insert(changeset)
    IO.puts "Insert result: #{inspect(result)}"
    result
  end

  @doc """
  Gets notifications for a specific user.
  """
  def get_user_notifications(user_id, limit \\ 50) do
    Repo.all(
      from n in Notification,
      where: n.recipient_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      preload: [:sender, :button]
    )
  end

  @doc """
  Gets unread notifications for a specific user.
  """
  def get_unread_notifications(user_id) do
    Repo.all(
      from n in Notification,
      where: n.recipient_id == ^user_id and n.read == false,
      order_by: [desc: n.inserted_at],
      preload: [:sender, :button]
    )
  end

  @doc """
  Marks a notification as read.
  """
  def mark_notification_read(notification_id, user_id) do
    case Repo.get_by(Notification, id: notification_id, recipient_id: user_id) do
      nil -> {:error, :not_found}
      notification ->
        notification
        |> Notification.changeset(%{read: true})
        |> Repo.update()
    end
  end

  @doc """
  Marks all notifications as read for a user.
  """
  def mark_all_notifications_read(user_id) do
    # Get all unread notifications and mark them as read one by one
    unread_notifications = get_unread_notifications(user_id)

    Enum.each(unread_notifications, fn notification ->
      mark_notification_read(notification.id, user_id)
    end)

    {:ok, length(unread_notifications)}
  end

  # Friend Notification Permissions

  @doc """
  Gets notification permissions for a specific friend relationship.
  """
  def get_friend_notification_permissions(user_id, friend_id) do
    Repo.get_by(FriendNotificationPermission, user_id: user_id, friend_id: friend_id)
  end

  @doc """
  Creates or updates friend notification permissions.
  """
  def upsert_friend_notification_permissions(attrs, user_id, friend_id) do
    case get_friend_notification_permissions(user_id, friend_id) do
      nil ->
        %FriendNotificationPermission{}
        |> FriendNotificationPermission.create_changeset(attrs, user_id, friend_id)
        |> Repo.insert()

      permissions ->
        permissions
        |> FriendNotificationPermission.changeset(attrs)
        |> Repo.update()
    end
  end

  # Button Click Notifications

  @doc """
  Sends notifications to friends when a button is clicked.
  """
  def send_button_click_notifications(button_id, user_id, click_data \\ %{}) do
    IO.puts "=== SEND BUTTON CLICK NOTIFICATIONS DEBUG ==="
    IO.puts "button_id: #{button_id}"
    IO.puts "user_id: #{user_id}"
    IO.puts "click_data: #{inspect(click_data)}"

    # Get all friends who should be notified
    recipients = get_notification_recipients(button_id, user_id)

    # Get button details
    button = ButtonLog.Buttons.get_button(button_id, user_id)
    IO.puts "Button lookup result: #{inspect(button)}"

    case button do
      {:ok, button_data} ->
        IO.puts "Button found: #{button_data.name}"

        # Get user details for the button owner
        button_owner = ButtonLog.Accounts.get_user!(button_data.user_id)
        IO.puts "Button owner: #{button_owner.display_name}"

        # Send notifications to each recipient
        results = Enum.map(recipients, fn friend ->
          IO.puts "Creating notification for friend: #{friend.display_name} (#{friend.id})"

          notification_result = create_notification(%{
            notification_type: "button_click",
            title: "#{button_data.name} was clicked!",
            message: "#{button_owner.display_name} just clicked their '#{button_data.name}' button",
            clicked_at: click_data[:clicked_at] || DateTime.utc_now(),
            metadata: click_data
          }, friend.id, user_id, button_id)

          IO.puts "Notification creation result: #{inspect(notification_result)}"
          notification_result
        end)

        IO.puts "All notification results: #{inspect(results)}"
        {:ok, results}

      {:error, :not_found} ->
        IO.puts "Button not found!"
        {:error, :button_not_found}
    end
  end

  @doc """
  Gets a notification by ID.
  """
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.
  """
  def change_notification(%Notification{} = notification, attrs \\ %{}) do
    Notification.changeset(notification, attrs)
  end
end
