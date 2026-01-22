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
    # Get enabled notification preferences for friends who should be notified
    preferences = Repo.all(
      from p in ButtonNotificationPreference,
      where: p.button_id == ^button_id and p.user_id == ^user_id and p.enabled == true,
      preload: [:friend]
    )

    Enum.map(preferences, fn preference -> preference.friend end)
  end

  # Notification History

  @doc """
  Creates a new notification.
  """
  def create_notification(attrs, recipient_id, sender_id, button_id) do
    %Notification{}
    |> Notification.create_changeset(attrs, recipient_id, sender_id, button_id)
    |> Repo.insert()
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
  Gets paginated notifications for a specific user.
  Returns {notifications, has_more} tuple.
  """
  def get_user_notifications_paginated(user_id, limit \\ 20, offset \\ 0) do
    notifications = Repo.all(
      from n in Notification,
      where: n.recipient_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^(limit + 1),
      offset: ^offset,
      preload: [:sender, :button]
    )

    has_more = length(notifications) > limit
    {Enum.take(notifications, limit), has_more}
  end

  @doc """
  Gets the count of unread notifications for a specific user.
  """
  def count_unread_notifications(user_id) do
    Repo.one(
      from n in Notification,
      where: n.recipient_id == ^user_id and n.read == false,
      select: count(n.id)
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
  Gets notifications from a specific friend (where friend is the sender).
  Used for viewing friend's activity in friend profile views.
  """
  def get_notifications_from_friend(user_id, friend_id, limit \\ 20) do
    Repo.all(
      from n in Notification,
      where: n.recipient_id == ^user_id and n.sender_id == ^friend_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
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
  Creates in-app notifications and sends push notifications.
  """
  def send_button_click_notifications(button_id, user_id, click_data \\ %{}) do
    require Logger
    Logger.debug("Sending button click notifications: button_id=#{button_id}, user_id=#{user_id}")

    # Get all friends who should be notified
    recipients = get_notification_recipients(button_id, user_id)

    # Get button details
    button = ButtonLog.Buttons.get_button(button_id, user_id)

    case button do
      {:ok, button_data} ->
        # Get user details for the button owner
        button_owner = ButtonLog.Accounts.get_user!(button_data.user_id)

        # Determine action verb based on click_data action
        # Support both atom and string keys for action
        action = click_data[:action] || click_data["action"] || "click"
        {_action_verb, action_past} = get_action_verbs(action)

        # Send notifications to each recipient
        results = Enum.map(recipients, fn friend ->
          # Create in-app notification
          notification_result = create_notification(%{
            notification_type: "button_click",
            title: "#{button_data.name} was #{action_past}!",
            message: "#{button_owner.display_name} just #{action_past} their '#{button_data.name}' button",
            clicked_at: click_data[:clicked_at] || DateTime.utc_now(),
            metadata: click_data
          }, friend.id, user_id, button_id)

          # Send push notification asynchronously
          Task.start(fn ->
            ButtonLog.PushNotifications.send_button_click_notification(
              friend.id,
              button_owner.display_name,
              button_data.name,
              button_id,
              action_past
            )
          end)

          # Broadcast via WebSocket for real-time update
          ButtonLogWeb.Endpoint.broadcast(
            "user:#{friend.id}",
            "notification_received",
            %{
              type: "button_click",
              title: "#{button_data.name} was #{action_past}!",
              message: "#{button_owner.display_name} just #{action_past} their '#{button_data.name}' button",
              button_id: button_id,
              sender_id: user_id,
              sender_name: button_owner.display_name,
              action: action
            }
          )

          notification_result
        end)

        Logger.info("Button click notifications sent to #{length(recipients)} recipients")
        {:ok, results}

      {:error, :not_found} ->
        Logger.warning("Button not found for notification: #{button_id}")
        {:error, :button_not_found}
    end
  end

  # Helper function to get appropriate action verbs for notification messages
  defp get_action_verbs(action) when action in ["start", :start] do
    {"start", "started"}
  end

  defp get_action_verbs(action) when action in ["stop", :stop, "end", :end] do
    {"stop", "stopped"}
  end

  defp get_action_verbs(_action) do
    {"click", "clicked"}
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
