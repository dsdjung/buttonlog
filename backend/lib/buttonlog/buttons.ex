defmodule ButtonLog.Buttons do
  @moduledoc """
  The Buttons context.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Buttons.{Button, ButtonClick, ButtonSharing}

  @doc """
  Returns the list of buttons for a user with latest click time.
  """
  def list_user_buttons(user_id) do
    # Get buttons with their latest click time (excluding archived buttons)
    Repo.all(
      from b in Button,
      left_join: bc in ButtonClick, on: b.id == bc.button_id,
      left_join: gifter in assoc(b, :created_by_friend),
      where: b.user_id == ^user_id and (is_nil(b.archived) or b.archived == false),
      group_by: [b.id, b.name, b.description, b.type, b.icon, b.color, b.is_active, b.current_state, b.state_changed_at, b.notifications_enabled, b.auto_stop_enabled, b.calendar_sync_enabled, b.user_id, b.inserted_at, b.updated_at, b.created_by_friend_id, b.gift_message, gifter.id, gifter.username, gifter.display_name],
      order_by: [asc: b.name],
      select: %{
        id: b.id,
        name: b.name,
        description: b.description,
        type: b.type,
        icon: b.icon,
        color: b.color,
        is_active: b.is_active,
        current_state: b.current_state,
        state_changed_at: b.state_changed_at,
        notifications_enabled: b.notifications_enabled,
        auto_stop_enabled: b.auto_stop_enabled,
        calendar_sync_enabled: b.calendar_sync_enabled,
        user_id: b.user_id,
        inserted_at: b.inserted_at,
        updated_at: b.updated_at,
        latest_click_at: max(bc.clicked_at),
        created_by_friend_id: b.created_by_friend_id,
        gift_message: b.gift_message,
        created_by_friend: %{
          id: gifter.id,
          username: gifter.username,
          display_name: gifter.display_name
        }
      }
    )
  end

  @doc """
  Returns the list of buttons created by a user for a specific friend (gift buttons).
  """
  def list_gift_buttons_for_friend(creator_id, friend_id) do
    Repo.all(
      from b in Button,
      left_join: bc in ButtonClick, on: b.id == bc.button_id,
      where: b.user_id == ^friend_id and b.created_by_friend_id == ^creator_id,
      group_by: [b.id, b.name, b.description, b.type, b.icon, b.color, b.is_active, b.current_state, b.state_changed_at, b.notifications_enabled, b.auto_stop_enabled, b.calendar_sync_enabled, b.user_id, b.inserted_at, b.updated_at, b.created_by_friend_id, b.gift_message, b.archived, b.archived_at],
      order_by: [desc: b.inserted_at],
      select: %{
        id: b.id,
        name: b.name,
        description: b.description,
        type: b.type,
        icon: b.icon,
        color: b.color,
        is_active: b.is_active,
        current_state: b.current_state,
        notifications_enabled: b.notifications_enabled,
        user_id: b.user_id,
        inserted_at: b.inserted_at,
        latest_click_at: max(bc.clicked_at),
        gift_message: b.gift_message,
        archived: b.archived,
        archived_at: b.archived_at
      }
    )
  end

  @doc """
  Gets a single button.
  """
  def get_button(id, user_id) do
    case Repo.get_by(Button, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      button -> {:ok, button}
    end
  end

  @doc """
  Creates a button.
  """
  def create_button(attrs \\ %{}, user_id) do
    result = %Button{}
    |> Button.create_changeset(attrs, user_id)
    |> Repo.insert()

    case result do
      {:ok, button} ->
        # Notify the creator about their new button
        notify_button_created(button, user_id)
        {:ok, button}

      error ->
        error
    end
  end

  @doc """
  Updates a button.
  """
  def update_button(id, attrs, user_id) do
    case get_button(id, user_id) do
      {:ok, button} ->
        button
        |> Button.changeset(attrs)
        |> Repo.update()

      error -> error
    end
  end

  @doc """
  Deletes a button.
  """
  def delete_button(id, user_id) do
    case get_button(id, user_id) do
      {:ok, button} ->
        # Notify gift creator before deletion (if this is a gift button)
        notify_gift_creator_of_deletion(button)

        Repo.delete(button)

      error -> error
    end
  end

  @doc """
  Records a button click and handles state changes for timed buttons.
  """
  def click_button(button_id, user_id) do
    # First verify the button exists and belongs to the user
    case get_button(button_id, user_id) do
      {:ok, button} ->
        result = case button.type do
          "timed" ->
            handle_timed_button_click(button, user_id)

          "state" ->
            handle_state_button_click(button, user_id)

          "one-time" ->
            handle_one_time_button_click(button, user_id)

          _other_type ->
            # For instant buttons, just record a click
            click_result = %ButtonClick{}
            |> ButtonClick.create_changeset(%{
              device: "web",
              platform: "web",
              action: "click"
            }, button_id, user_id)
            |> Repo.insert()

            # Notify gift creator if this is a gift button
            if match?({:ok, _}, click_result), do: notify_gift_creator_of_click(button, "click")

            click_result
        end

        result

      error -> error
    end
  end

  defp handle_state_button_click(button, user_id) do
    # Toggle state: idle -> active, active -> idle
    {new_state, action} =
      case button.current_state do
        "idle" -> {"active", "start"}
        "active" -> {"idle", "end"}
        _ -> {"active", "start"}
      end

    result = Repo.transaction(fn ->
      # Update button state
      button
      |> Button.changeset(%{
        current_state: new_state,
        state_changed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()

      # Create the button click record
      %ButtonClick{}
      |> ButtonClick.create_changeset(%{
        device: "web",
        platform: "web",
        action: action
      }, button.id, user_id)
      |> Repo.insert!()
    end)

    # Notify gift creator if this is a gift button (outside transaction)
    if match?({:ok, _}, result), do: notify_gift_creator_of_click(button, action)

    result
  end

  defp handle_timed_button_click(button, user_id) do
    # Toggle state: idle -> active, active -> idle
    {new_state, action} =
      case button.current_state do
        "idle" -> {"active", "start"}
        "active" -> {"idle", "end"}
        _ -> {"active", "start"}  # Default to start if state is nil or unknown
      end

    # Use a transaction to ensure consistency
    result = Repo.transaction(fn ->
      # Update button state
      button
      |> Button.changeset(%{
        current_state: new_state,
        state_changed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()

      # Create the button click record
      click_result = %ButtonClick{}
      |> ButtonClick.create_changeset(%{
        device: "web",
        platform: "web",
        action: action
      }, button.id, user_id)
      |> Repo.insert!()

      click_result
    end)

    # Notify gift creator if this is a gift button (outside transaction)
    if match?({:ok, _}, result), do: notify_gift_creator_of_click(button, action)

    result
  end

  defp handle_one_time_button_click(button, user_id) do
    # One-time buttons: record click then archive the button
    result = Repo.transaction(fn ->
      # Create the button click record
      click_result = %ButtonClick{}
      |> ButtonClick.create_changeset(%{
        device: "web",
        platform: "web",
        action: "click"
      }, button.id, user_id)
      |> Repo.insert!()

      # Archive the button so it no longer appears in the list
      button
      |> Button.changeset(%{
        archived: true,
        archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()

      click_result
    end)

    # Send notifications (outside transaction)
    if match?({:ok, _}, result) do
      # Notify gift creator if this is a gift button (use "complete" action for one-time buttons)
      notify_gift_creator_of_click(button, "complete")
      # Notify the button owner that their one-time button was completed
      notify_one_time_button_completed(button, user_id)
    end

    result
  end

  @doc """
  Starts a timer for a timed button.
  """
  def start_timer(button_id, user_id) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        if button.type == "timed" do
          {:ok, %{started_at: DateTime.utc_now()}}
        else
          {:error, :not_a_timed_button}
        end
      {:error, :not_found} ->
        {:error, :button_not_found}
    end
  end

  @doc """
  Stops a timer for a timed button.
  """
  def stop_timer(button_id, user_id) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        if button.type == "timed" do
          {:ok, 60} # Return duration in seconds
        else
          {:error, :not_a_timed_button}
        end
      {:error, :not_found} ->
        {:error, :button_not_found}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking button changes.
  """
  def change_button(%Button{} = button, attrs \\ %{}) do
    Button.changeset(button, attrs)
  end

  @doc """
  Gets button clicks for a specific button.
  """
  def list_button_clicks(button_id, user_id, limit \\ 50) do
    # First verify the button belongs to the user
    case get_button(button_id, user_id) do
      {:ok, _button} ->
        clicks = Repo.all(
          from bc in ButtonClick,
          where: bc.button_id == ^button_id,
          order_by: [desc: bc.clicked_at],
          limit: ^limit
        )
        {:ok, clicks}

      error -> error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking button click changes.
  """
  def change_button_click(%ButtonClick{} = button_click, attrs \\ %{}) do
    ButtonClick.changeset(button_click, attrs)
  end

  @doc """
  Returns the list of buttons for a user with latest click details including location.
  This is used for friend button views where we want to show status and last activity info.
  """
  def list_user_buttons_with_latest_click(user_id) do
    # First, get all buttons for the user
    buttons = Repo.all(
      from b in Button,
      where: b.user_id == ^user_id,
      order_by: [asc: b.name]
    )

    # For each button, get its latest click with location
    Enum.map(buttons, fn button ->
      latest_click = Repo.one(
        from bc in ButtonClick,
        where: bc.button_id == ^button.id,
        order_by: [desc: bc.clicked_at],
        limit: 1,
        select: %{
          clicked_at: bc.clicked_at,
          action: bc.action,
          location_lat: bc.location_lat,
          location_lng: bc.location_lng,
          device: bc.device,
          platform: bc.platform
        }
      )

      %{
        id: button.id,
        name: button.name,
        description: button.description,
        type: button.type,
        icon: button.icon,
        color: button.color,
        is_active: button.is_active,
        current_state: button.current_state,
        state_changed_at: button.state_changed_at,
        notifications_enabled: button.notifications_enabled,
        auto_stop_enabled: button.auto_stop_enabled,
        calendar_sync_enabled: button.calendar_sync_enabled,
        user_id: button.user_id,
        inserted_at: button.inserted_at,
        updated_at: button.updated_at,
        latest_click_at: latest_click && latest_click.clicked_at,
        latest_click_action: latest_click && latest_click.action,
        latest_click_location_lat: latest_click && latest_click.location_lat,
        latest_click_location_lng: latest_click && latest_click.location_lng,
        latest_click_device: latest_click && latest_click.device,
        latest_click_platform: latest_click && latest_click.platform
      }
    end)
  end

  @doc """
  Gets button activity (clicks) for a friend.
  Returns all button clicks for the friend with button information included.
  This is used for viewing a friend's activity history.
  Supports cursor-based pagination using clicked_at timestamp.
  """
  def list_friend_button_activity(friend_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    cursor = Keyword.get(opts, :cursor)

    query =
      from bc in ButtonClick,
      join: b in Button, on: b.id == bc.button_id,
      where: b.user_id == ^friend_id,
      order_by: [desc: bc.clicked_at, desc: bc.id],
      limit: ^(limit + 1),
      select: %{
        id: bc.id,
        button_id: bc.button_id,
        button_name: b.name,
        button_type: b.type,
        button_icon: b.icon,
        button_color: b.color,
        user_id: bc.user_id,
        clicked_at: bc.clicked_at,
        duration: bc.duration,
        action: bc.action,
        device: bc.device,
        platform: bc.platform,
        inserted_at: bc.inserted_at
      }

    query =
      if cursor do
        from [bc, b] in query,
          where: bc.clicked_at < ^cursor or (bc.clicked_at == ^cursor and bc.id < ^Keyword.get(opts, :cursor_id, ""))
      else
        query
      end

    results = Repo.all(query)

    # Check if there are more results
    has_more = length(results) > limit
    activities = Enum.take(results, limit)

    # Get the next cursor from the last item
    next_cursor =
      if has_more and length(activities) > 0 do
        last = List.last(activities)
        %{clicked_at: last.clicked_at, id: last.id}
      else
        nil
      end

    {activities, next_cursor, has_more}
  end

  # =============================================================================
  # Button Sharing Functions
  # =============================================================================

  @doc """
  Gets the sharing settings for a button with all friends.
  Returns a list of sharing records for each friend the user has.
  If no explicit sharing record exists, the button is shared by default.
  """
  def get_button_sharing(button_id, user_id) do
    case get_button(button_id, user_id) do
      {:ok, _button} ->
        sharing = Repo.all(
          from bs in ButtonSharing,
            where: bs.button_id == ^button_id and bs.user_id == ^user_id
        )
        {:ok, sharing}

      error -> error
    end
  end

  @doc """
  Gets the sharing setting for a specific button and friend.
  Returns nil if no explicit setting exists (defaults to shared).
  """
  def get_button_sharing_for_friend(button_id, friend_id) do
    Repo.one(
      from bs in ButtonSharing,
        where: bs.button_id == ^button_id and bs.friend_id == ^friend_id
    )
  end

  @doc """
  Checks if a button is shared with a specific friend.
  Returns true if shared (default), false if explicitly not shared.
  """
  def is_button_shared_with_friend?(button_id, friend_id) do
    case get_button_sharing_for_friend(button_id, friend_id) do
      nil -> true  # Default: shared if no explicit setting
      sharing -> sharing.is_shared
    end
  end

  @doc """
  Sets the sharing status for a button with a specific friend.
  Creates a new record or updates existing one.
  """
  def set_button_sharing(button_id, user_id, friend_id, is_shared) do
    case get_button_sharing_for_friend(button_id, friend_id) do
      nil ->
        # Create new sharing record
        %ButtonSharing{}
        |> ButtonSharing.changeset(%{
          button_id: button_id,
          user_id: user_id,
          friend_id: friend_id,
          is_shared: is_shared
        })
        |> Repo.insert()

      existing ->
        # Update existing record
        existing
        |> ButtonSharing.changeset(%{is_shared: is_shared})
        |> Repo.update()
    end
  end

  @doc """
  Updates sharing settings for a button with multiple friends at once.
  Takes a list of %{friend_id: String, is_shared: boolean} maps.
  """
  def update_button_sharing_bulk(button_id, user_id, friend_settings) do
    case get_button(button_id, user_id) do
      {:ok, _button} ->
        Repo.transaction(fn ->
          Enum.map(friend_settings, fn %{friend_id: friend_id, is_shared: is_shared} ->
            case set_button_sharing(button_id, user_id, friend_id, is_shared) do
              {:ok, sharing} -> sharing
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end)
        end)

      error -> error
    end
  end

  @doc """
  Gets all unshared friend IDs for a specific button.
  Returns a list of friend_ids where the button is explicitly not shared.
  """
  def get_unshared_friend_ids(button_id) do
    Repo.all(
      from bs in ButtonSharing,
        where: bs.button_id == ^button_id and bs.is_shared == false,
        select: bs.friend_id
    )
  end

  @doc """
  Gets all shared friend IDs for a specific button.
  Returns a list of friend_ids where the button is explicitly shared.
  Used to determine exclusions from the default "share with all" behavior.
  """
  def get_sharing_exclusions(button_id) do
    get_unshared_friend_ids(button_id)
  end

  @doc """
  Lists buttons for a friend that are shared with the viewer.
  Filters out buttons where is_shared is explicitly false.
  """
  def list_shared_buttons_for_friend(friend_id, viewer_id) do
    # Get all buttons for the friend
    buttons = list_user_buttons_with_latest_click(friend_id)

    # Get button IDs that are explicitly NOT shared with the viewer
    unshared_button_ids = Repo.all(
      from bs in ButtonSharing,
        where: bs.user_id == ^friend_id and bs.friend_id == ^viewer_id and bs.is_shared == false,
        select: bs.button_id
    )

    # Filter out unshared buttons
    Enum.reject(buttons, fn button ->
      button.id in unshared_button_ids
    end)
  end

  # =============================================================================
  # Gift Button Functions
  # =============================================================================

  @doc """
  Creates a button for a friend (gift button).
  The button will be owned by the friend but marked as created by the current user.

  Returns {:error, :not_friends} if the users are not friends.
  """
  def create_button_for_friend(attrs, friend_id, creator_id, message \\ nil) do
    alias ButtonLog.Social
    alias ButtonLog.Notifications

    if Social.are_friends?(creator_id, friend_id) do
      # Create the button owned by the friend
      result = %Button{}
      |> Button.create_gift_changeset(attrs, friend_id, creator_id, message)
      |> Repo.insert()

      case result do
        {:ok, button} ->
          # Send notification to the friend about their new button
          creator = ButtonLog.Accounts.get_user!(creator_id)
          Notifications.create_notification(%{
            notification_type: "gift_button_received",
            title: "New Button Gift!",
            message: "#{creator.display_name || creator.username} created a button for you: #{button.name}",
            metadata: %{
              button_id: button.id,
              button_name: button.name,
              creator_id: creator_id
            }
          }, friend_id, creator_id, button.id)

          # Also notify the creator that their gift was sent
          notify_gift_button_sent(button, creator_id, friend_id)

          # Preload the creator for the response
          button = Repo.preload(button, [:created_by_friend])
          {:ok, button}

        error ->
          error
      end
    else
      {:error, :not_friends}
    end
  end

  @doc """
  Sends a notification to the gift creator when a gift button is clicked.
  Called from click_button when the button has a created_by_friend_id.
  """
  def notify_gift_creator_of_click(button, action) do
    if button.created_by_friend_id do
      alias ButtonLog.Notifications

      owner = ButtonLog.Accounts.get_user!(button.user_id)
      action_past = case action do
        "start" -> "started"
        "end" -> "stopped"
        "stop" -> "stopped"
        "complete" -> "completed"
        _ -> "clicked"
      end

      Notifications.create_notification(%{
        notification_type: "gift_button_clicked",
        title: "#{button.name} was #{action_past}!",
        message: "#{owner.display_name || owner.username} #{action_past} the '#{button.name}' button you created for them",
        metadata: %{
          button_id: button.id,
          button_name: button.name,
          action: action
        }
      }, button.created_by_friend_id, button.user_id, button.id)
    end
  end

  @doc """
  Sends a notification to the gift creator when a gift button is deleted.
  Called from delete_button when the button has a created_by_friend_id.
  """
  def notify_gift_creator_of_deletion(button) do
    if button.created_by_friend_id do
      alias ButtonLog.Notifications

      owner = ButtonLog.Accounts.get_user!(button.user_id)

      Notifications.create_notification(%{
        notification_type: "gift_button_deleted",
        title: "Button Removed",
        message: "#{owner.display_name || owner.username} deleted the '#{button.name}' button you created for them",
        metadata: %{
          button_name: button.name
        }
      }, button.created_by_friend_id, button.user_id, nil)
    end
  end

  # Sends a notification to the user when they create a button.
  defp notify_button_created(button, user_id) do
    alias ButtonLog.Notifications

    Notifications.create_notification(%{
      notification_type: "button_created",
      title: "Button Created!",
      message: "Your button '#{button.name}' has been created successfully",
      metadata: %{
        button_id: button.id,
        button_name: button.name
      }
    }, user_id, user_id, button.id)
  end

  # Sends a notification to the creator when they create a gift button for a friend.
  defp notify_gift_button_sent(button, creator_id, friend_id) do
    alias ButtonLog.Notifications

    friend = ButtonLog.Accounts.get_user!(friend_id)

    Notifications.create_notification(%{
      notification_type: "gift_button_sent",
      title: "Gift Button Sent!",
      message: "You created '#{button.name}' for #{friend.display_name || friend.username}",
      metadata: %{
        button_id: button.id,
        button_name: button.name,
        friend_id: friend_id
      }
    }, creator_id, creator_id, button.id)
  end

  # Sends a notification to the user when they complete a one-time button.
  defp notify_one_time_button_completed(button, user_id) do
    alias ButtonLog.Notifications

    Notifications.create_notification(%{
      notification_type: "one_time_button_completed",
      title: "Task Completed!",
      message: "'#{button.name}' has been completed and archived",
      metadata: %{
        button_id: button.id,
        button_name: button.name
      }
    }, user_id, user_id, button.id)
  end
end
