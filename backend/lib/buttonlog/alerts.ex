defmodule ButtonLog.Alerts do
  @moduledoc """
  The Alerts context.

  Handles in-app alerts sent between users (friend alerts for button clicks, etc).
  This replaces the old Notifications context for friend-to-friend alerts.

  Note: For external webhook/notification delivery, see ButtonLog.Notifications.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Alerts.{Alert, ButtonAlertPreference, FriendAlertPermission}

  # Button Alert Preferences

  @doc """
  Gets alert settings for a specific button.
  """
  def get_button_alert_settings(button_id) do
    Repo.all(
      from p in ButtonAlertPreference,
        where: p.button_id == ^button_id,
        preload: [:friend]
    )
  end

  @doc """
  Gets alert preferences for a specific button and user.
  """
  def get_button_alert_preferences(button_id, user_id) do
    Repo.all(
      from p in ButtonAlertPreference,
        where: p.button_id == ^button_id and p.user_id == ^user_id,
        preload: [:friend]
    )
  end

  @doc """
  Toggles alert setting for a specific friend and button.
  """
  def toggle_button_friend_alert(button_id, user_id, friend_id) do
    case Repo.get_by(ButtonAlertPreference,
           button_id: button_id,
           user_id: user_id,
           friend_id: friend_id
         ) do
      nil ->
        # Create new preference
        %ButtonAlertPreference{}
        |> ButtonAlertPreference.create_changeset(%{enabled: true}, button_id, user_id, friend_id)
        |> Repo.insert()

      preference ->
        # Toggle existing preference
        preference
        |> ButtonAlertPreference.changeset(%{enabled: !preference.enabled})
        |> Repo.update()
    end
  end

  @doc """
  Sets alert preference for a specific friend and button.
  """
  def set_button_friend_alert(button_id, user_id, friend_id, enabled, alert_type \\ "click") do
    case Repo.get_by(ButtonAlertPreference,
           button_id: button_id,
           user_id: user_id,
           friend_id: friend_id
         ) do
      nil ->
        # Create new preference
        %ButtonAlertPreference{}
        |> ButtonAlertPreference.create_changeset(
          %{enabled: enabled, alert_type: alert_type},
          button_id,
          user_id,
          friend_id
        )
        |> Repo.insert()

      preference ->
        # Update existing preference
        preference
        |> ButtonAlertPreference.changeset(%{enabled: enabled, alert_type: alert_type})
        |> Repo.update()
    end
  end

  @doc """
  Gets all friends who should receive alerts for a specific button click.
  """
  def get_alert_recipients(button_id, user_id) do
    # Get enabled alert preferences for friends who should receive alerts
    preferences =
      Repo.all(
        from p in ButtonAlertPreference,
          where: p.button_id == ^button_id and p.user_id == ^user_id and p.enabled == true,
          preload: [:friend]
      )

    Enum.map(preferences, fn preference -> preference.friend end)
  end

  # Alert History

  @doc """
  Creates a new alert.
  """
  def create_alert(attrs, recipient_id, sender_id, button_id) do
    %Alert{}
    |> Alert.create_changeset(attrs, recipient_id, sender_id, button_id)
    |> Repo.insert()
  end

  @doc """
  Gets alerts for a specific user.
  """
  def get_user_alerts(user_id, limit \\ 50) do
    Repo.all(
      from a in Alert,
        where: a.recipient_id == ^user_id,
        order_by: [desc: a.inserted_at],
        limit: ^limit,
        preload: [:sender, :button]
    )
  end

  @doc """
  Gets paginated alerts for a specific user.
  Returns {alerts, has_more} tuple.
  """
  def get_user_alerts_paginated(user_id, limit \\ 20, offset \\ 0) do
    alerts =
      Repo.all(
        from a in Alert,
          where: a.recipient_id == ^user_id,
          order_by: [desc: a.inserted_at],
          limit: ^(limit + 1),
          offset: ^offset,
          preload: [:sender, :button]
      )

    has_more = length(alerts) > limit
    {Enum.take(alerts, limit), has_more}
  end

  @doc """
  Gets the count of unread alerts for a specific user.
  """
  def count_unread_alerts(user_id) do
    Repo.one(
      from a in Alert,
        where: a.recipient_id == ^user_id and a.read == false,
        select: count(a.id)
    )
  end

  @doc """
  Gets unread alerts for a specific user.
  """
  def get_unread_alerts(user_id) do
    Repo.all(
      from a in Alert,
        where: a.recipient_id == ^user_id and a.read == false,
        order_by: [desc: a.inserted_at],
        preload: [:sender, :button]
    )
  end

  @doc """
  Gets alerts from a specific friend (where friend is the sender).
  Used for viewing friend's activity in friend profile views.
  """
  def get_alerts_from_friend(user_id, friend_id, limit \\ 20) do
    Repo.all(
      from a in Alert,
        where: a.recipient_id == ^user_id and a.sender_id == ^friend_id,
        order_by: [desc: a.inserted_at],
        limit: ^limit,
        preload: [:sender, :button]
    )
  end

  @doc """
  Marks an alert as read.
  """
  def mark_alert_read(alert_id, user_id) do
    case Repo.get_by(Alert, id: alert_id, recipient_id: user_id) do
      nil ->
        {:error, :not_found}

      alert ->
        alert
        |> Alert.changeset(%{read: true})
        |> Repo.update()
    end
  end

  @doc """
  Marks all alerts as read for a user.
  """
  def mark_all_alerts_read(user_id) do
    # Get all unread alerts and mark them as read one by one
    unread_alerts = get_unread_alerts(user_id)

    Enum.each(unread_alerts, fn alert ->
      mark_alert_read(alert.id, user_id)
    end)

    {:ok, length(unread_alerts)}
  end

  # Friend Alert Permissions

  @doc """
  Gets alert permissions for a specific friend relationship.
  """
  def get_friend_alert_permissions(user_id, friend_id) do
    Repo.get_by(FriendAlertPermission, user_id: user_id, friend_id: friend_id)
  end

  @doc """
  Creates or updates friend alert permissions.
  """
  def upsert_friend_alert_permissions(attrs, user_id, friend_id) do
    case get_friend_alert_permissions(user_id, friend_id) do
      nil ->
        %FriendAlertPermission{}
        |> FriendAlertPermission.create_changeset(attrs, user_id, friend_id)
        |> Repo.insert()

      permissions ->
        permissions
        |> FriendAlertPermission.changeset(attrs)
        |> Repo.update()
    end
  end

  # Button Click Alerts

  @doc """
  Sends alerts to friends when a button is clicked.
  Creates in-app alerts and sends push notifications.
  """
  def send_button_click_alerts(button_id, user_id, click_data \\ %{}) do
    require Logger
    Logger.debug("Sending button click alerts: button_id=#{button_id}, user_id=#{user_id}")

    # Get all friends who should receive alerts
    recipients = get_alert_recipients(button_id, user_id)

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

        # Send alerts to each recipient
        results =
          Enum.map(recipients, fn friend ->
            # Create in-app alert
            alert_result =
              create_alert(
                %{
                  alert_type: "button_click",
                  title: "#{button_data.name} was #{action_past}!",
                  message:
                    "#{button_owner.display_name} just #{action_past} their '#{button_data.name}' button",
                  clicked_at: click_data[:clicked_at] || DateTime.utc_now(),
                  metadata: click_data
                },
                friend.id,
                user_id,
                button_id
              )

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
              "alert_received",
              %{
                type: "button_click",
                title: "#{button_data.name} was #{action_past}!",
                message:
                  "#{button_owner.display_name} just #{action_past} their '#{button_data.name}' button",
                button_id: button_id,
                sender_id: user_id,
                sender_name: button_owner.display_name,
                action: action
              }
            )

            alert_result
          end)

        Logger.info("Button click alerts sent to #{length(recipients)} recipients")
        {:ok, results}

      {:error, :not_found} ->
        Logger.warning("Button not found for alert: #{button_id}")
        {:error, :button_not_found}
    end
  end

  # Helper function to get appropriate action verbs for alert messages
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
  Gets an alert by ID.
  """
  def get_alert!(id), do: Repo.get!(Alert, id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert changes.
  """
  def change_alert(%Alert{} = alert, attrs \\ %{}) do
    Alert.changeset(alert, attrs)
  end
end
