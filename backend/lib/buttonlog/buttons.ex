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
      group_by: [b.id, b.name, b.description, b.type, b.icon, b.color, b.is_active, b.current_state, b.state_changed_at, b.alerts_enabled, b.auto_stop_enabled, b.auto_stop_minutes, b.scheduled_stop_at, b.calendar_sync_enabled, b.user_id, b.inserted_at, b.updated_at, b.created_by_friend_id, b.gift_message, gifter.id, gifter.username, gifter.display_name],
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
        alerts_enabled: b.alerts_enabled,
        auto_stop_enabled: b.auto_stop_enabled,
        auto_stop_minutes: b.auto_stop_minutes,
        scheduled_stop_at: b.scheduled_stop_at,
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
      group_by: [b.id, b.name, b.description, b.type, b.icon, b.color, b.is_active, b.current_state, b.state_changed_at, b.alerts_enabled, b.auto_stop_enabled, b.calendar_sync_enabled, b.user_id, b.inserted_at, b.updated_at, b.created_by_friend_id, b.gift_message, b.archived, b.archived_at],
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
        alerts_enabled: b.alerts_enabled,
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
          "toggle" ->
            handle_toggle_button_click(button, user_id)

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

  defp handle_toggle_button_click(button, user_id) do
    # Toggle state: idle -> active, active -> idle
    {new_state, action} =
      case button.current_state do
        "idle" -> {"active", "start"}
        "active" -> {"idle", "end"}
        _ -> {"active", "start"}  # Default to start if state is nil or unknown
      end

    # Calculate scheduled_stop_at if starting with auto-stop enabled
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    scheduled_stop_at = calculate_scheduled_stop_at(button, action, now)

    # Use a transaction to ensure consistency
    result = Repo.transaction(fn ->
      # Update button state
      button
      |> Button.changeset(%{
        current_state: new_state,
        state_changed_at: now,
        scheduled_stop_at: scheduled_stop_at
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

  # Calculate when the button should auto-stop
  defp calculate_scheduled_stop_at(button, action, now) do
    cond do
      # When starting and auto-stop is enabled with a duration
      action == "start" and button.auto_stop_enabled and button.auto_stop_minutes ->
        DateTime.add(now, button.auto_stop_minutes * 60, :second)

      # When stopping (manually or otherwise), clear the scheduled stop
      action in ["end", "stop"] ->
        nil

      # Otherwise no scheduled stop
      true ->
        nil
    end
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
  Starts a timer for a toggle button.
  """
  def start_timer(button_id, user_id) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        if button.type == "toggle" do
          {:ok, %{started_at: DateTime.utc_now()}}
        else
          {:error, :not_a_toggle_button}
        end
      {:error, :not_found} ->
        {:error, :button_not_found}
    end
  end

  @doc """
  Stops a timer for a toggle button.
  """
  def stop_timer(button_id, user_id) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        if button.type == "toggle" do
          {:ok, 60} # Return duration in seconds
        else
          {:error, :not_a_toggle_button}
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
        alerts_enabled: button.notifications_enabled,
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
    alias ButtonLog.Alerts

    if Social.are_friends?(creator_id, friend_id) do
      # Create the button owned by the friend
      result = %Button{}
      |> Button.create_gift_changeset(attrs, friend_id, creator_id, message)
      |> Repo.insert()

      case result do
        {:ok, button} ->
          # Send notification to the friend about their new button
          creator = ButtonLog.Accounts.get_user!(creator_id)
          Alerts.create_alert(%{
            alert_type: "gift_button_received",
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
      alias ButtonLog.Alerts

      owner = ButtonLog.Accounts.get_user!(button.user_id)
      action_past = case action do
        "start" -> "started"
        "end" -> "stopped"
        "stop" -> "stopped"
        "complete" -> "completed"
        _ -> "clicked"
      end

      Alerts.create_alert(%{
        alert_type: "gift_button_clicked",
        title: "#{button.name} was #{action_past}!",
        message: "#{owner.display_name || owner.username} #{action_past} the '#{button.name}' button you created for them",
        metadata: %{
          button_id: button.id,
          button_name: button.name,
          action: action,
          friend_id: button.user_id  # The friend who received and clicked the gift button
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
      alias ButtonLog.Alerts

      owner = ButtonLog.Accounts.get_user!(button.user_id)

      Alerts.create_alert(%{
        alert_type: "gift_button_deleted",
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
    alias ButtonLog.Alerts

    Alerts.create_alert(%{
      alert_type: "button_created",
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
    alias ButtonLog.Alerts

    friend = ButtonLog.Accounts.get_user!(friend_id)

    Alerts.create_alert(%{
      alert_type: "gift_button_sent",
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
    alias ButtonLog.Alerts

    Alerts.create_alert(%{
      alert_type: "one_time_button_completed",
      title: "Task Completed!",
      message: "'#{button.name}' has been completed and archived",
      metadata: %{
        button_id: button.id,
        button_name: button.name
      }
    }, user_id, user_id, button.id)
  end

  # =============================================================================
  # Button Collaborator Functions (Shared Buttons)
  # =============================================================================

  alias ButtonLog.Buttons.ButtonCollaborator

  @doc """
  Gets a button by ID without ownership check.
  Used internally for shared button access.
  """
  def get_button_by_id(id) do
    case Repo.get(Button, id) do
      nil -> {:error, :not_found}
      button -> {:ok, button}
    end
  end

  @doc """
  Checks if a user can click a button.
  Returns true if:
  - User is the button owner
  - Button is shared with friends and user is a friend
  - User is an explicit collaborator
  - Button has public sharing mode
  """
  def can_click_button?(button_id, user_id) do
    case get_button_by_id(button_id) do
      {:ok, button} ->
        cond do
          # Owner can always click
          button.user_id == user_id -> true

          # Check based on sharing mode
          button.sharing_mode == "private" -> false

          button.sharing_mode == "friends" ->
            ButtonLog.Social.are_friends?(button.user_id, user_id)

          button.sharing_mode == "invite_only" ->
            is_collaborator?(button_id, user_id)

          button.sharing_mode == "public" ->
            true

          # Default: only owner
          true -> false
        end

      {:error, _} -> false
    end
  end

  @doc """
  Checks if a user can view button history.
  Same rules as can_click_button? for now.
  """
  def can_view_button_history?(button_id, user_id) do
    can_click_button?(button_id, user_id)
  end

  @doc """
  Checks if a user is an explicit collaborator on a button.
  """
  def is_collaborator?(button_id, user_id) do
    Repo.exists?(
      from bc in ButtonCollaborator,
        where: bc.button_id == ^button_id and bc.user_id == ^user_id and not is_nil(bc.accepted_at)
    )
  end

  @doc """
  Records a button click with access checking.
  Allows non-owners to click if they have access.
  """
  def click_button_with_access_check(button_id, user_id, click_attrs \\ %{}) do
    if can_click_button?(button_id, user_id) do
      case get_button_by_id(button_id) do
        {:ok, button} ->
          result = case button.type do
            "toggle" ->
              handle_toggle_button_click_for_collaborator(button, user_id, click_attrs)

            "one-time" ->
              # Only owner can complete one-time buttons
              if button.user_id == user_id do
                handle_one_time_button_click(button, user_id)
              else
                {:error, :owner_only_action}
              end

            _other_type ->
              # For instant buttons, just record a click
              %ButtonClick{}
              |> ButtonClick.create_changeset(
                Map.merge(%{
                  device: click_attrs[:device] || "web",
                  platform: click_attrs[:platform] || "web",
                  action: "click"
                }, click_attrs),
                button_id,
                user_id
              )
              |> Repo.insert()
          end

          # Notify owner if clicked by collaborator
          case result do
            {:ok, click} ->
              if button.user_id != user_id do
                notify_owner_of_collaborator_click(button, user_id, click)
              end
              {:ok, click}
            error -> error
          end

        error -> error
      end
    else
      {:error, :not_authorized}
    end
  end

  defp handle_toggle_button_click_for_collaborator(button, user_id, click_attrs) do
    # Toggle state: idle -> active, active -> idle
    {new_state, action} =
      case button.current_state do
        "idle" -> {"active", "start"}
        "active" -> {"idle", "end"}
        _ -> {"active", "start"}
      end

    # Calculate scheduled_stop_at if starting with auto-stop enabled
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    scheduled_stop_at = calculate_scheduled_stop_at(button, action, now)

    Repo.transaction(fn ->
      # Update button state
      button
      |> Button.changeset(%{
        current_state: new_state,
        state_changed_at: now,
        scheduled_stop_at: scheduled_stop_at
      })
      |> Repo.update!()

      # Create the button click record
      %ButtonClick{}
      |> ButtonClick.create_changeset(
        Map.merge(%{
          device: click_attrs[:device] || "web",
          platform: click_attrs[:platform] || "web",
          action: action
        }, click_attrs),
        button.id,
        user_id
      )
      |> Repo.insert!()
    end)
  end

  defp notify_owner_of_collaborator_click(button, clicker_id, _click) do
    alias ButtonLog.Alerts

    clicker = ButtonLog.Accounts.get_user!(clicker_id)

    Alerts.create_alert(%{
      alert_type: "shared_button_clicked",
      title: "#{button.name} was clicked!",
      message: "#{clicker.display_name || clicker.username} clicked your shared button '#{button.name}'",
      metadata: %{
        button_id: button.id,
        button_name: button.name,
        clicker_id: clicker_id
      }
    }, button.user_id, clicker_id, button.id)
  end

  @doc """
  Updates the sharing mode for a button.
  Only the owner can update sharing settings.
  """
  def update_sharing_mode(button_id, user_id, mode) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        button
        |> Button.sharing_changeset(%{sharing_mode: mode})
        |> Repo.update()

      error -> error
    end
  end

  @doc """
  Generates a share token for public link sharing.
  Only the owner can generate share links.
  """
  def generate_share_token(button_id, user_id, opts \\ []) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        token = Ecto.UUID.generate()
        expires_at = Keyword.get(opts, :expires_at)

        button
        |> Button.sharing_changeset(%{
          share_token: token,
          share_token_expires_at: expires_at
        })
        |> Repo.update()

      error -> error
    end
  end

  @doc """
  Revokes a share token for a button.
  Only the owner can revoke share links.
  """
  def revoke_share_token(button_id, user_id) do
    case get_button(button_id, user_id) do
      {:ok, button} ->
        button
        |> Button.sharing_changeset(%{
          share_token: nil,
          share_token_expires_at: nil
        })
        |> Repo.update()

      error -> error
    end
  end

  @doc """
  Gets a button by its share token.
  Returns error if token is expired or not found.
  """
  def get_button_by_share_token(token) do
    now = DateTime.utc_now()

    case Repo.one(
      from b in Button,
        where: b.share_token == ^token,
        where: is_nil(b.share_token_expires_at) or b.share_token_expires_at > ^now
    ) do
      nil -> {:error, :not_found}
      button -> {:ok, button}
    end
  end

  @doc """
  Adds a collaborator to a button.
  Only the owner can add collaborators.
  The collaborator must be a friend of the owner (unless public mode).
  """
  def add_collaborator(button_id, owner_id, collaborator_user_id) do
    case get_button(button_id, owner_id) do
      {:ok, button} ->
        # For invite_only mode, verify the collaborator is a friend
        if button.sharing_mode == "invite_only" and
           not ButtonLog.Social.are_friends?(owner_id, collaborator_user_id) do
          {:error, :not_friends}
        else
          %ButtonCollaborator{}
          |> ButtonCollaborator.changeset(%{
            button_id: button_id,
            user_id: collaborator_user_id,
            invited_by_id: owner_id,
            permission: "click",
            accepted_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.insert()
          |> case do
            {:ok, collab} ->
              # Notify the new collaborator
              notify_collaborator_added(button, owner_id, collaborator_user_id)
              {:ok, collab}
            error -> error
          end
        end

      error -> error
    end
  end

  @doc """
  Removes a collaborator from a button.
  Only the owner can remove collaborators.
  """
  def remove_collaborator(button_id, owner_id, collaborator_user_id) do
    case get_button(button_id, owner_id) do
      {:ok, _button} ->
        case Repo.one(
          from bc in ButtonCollaborator,
            where: bc.button_id == ^button_id and bc.user_id == ^collaborator_user_id
        ) do
          nil -> {:error, :not_found}
          collaborator -> Repo.delete(collaborator)
        end

      error -> error
    end
  end

  @doc """
  Lists all collaborators for a button.
  Only the owner or existing collaborators can see the list.
  """
  def list_collaborators(button_id, user_id) do
    case get_button_by_id(button_id) do
      {:ok, button} ->
        if button.user_id == user_id or is_collaborator?(button_id, user_id) do
          collaborators = Repo.all(
            from bc in ButtonCollaborator,
              join: u in assoc(bc, :user),
              where: bc.button_id == ^button_id,
              select: %{
                id: bc.id,
                user_id: bc.user_id,
                user_name: u.display_name,
                username: u.username,
                permission: bc.permission,
                accepted_at: bc.accepted_at,
                inserted_at: bc.inserted_at
              }
          )
          {:ok, collaborators}
        else
          {:error, :not_authorized}
        end

      error -> error
    end
  end

  @doc """
  Gets all user IDs who are collaborators on a button (for broadcasting).
  """
  def get_collaborator_user_ids(button_id) do
    Repo.all(
      from bc in ButtonCollaborator,
        where: bc.button_id == ^button_id and not is_nil(bc.accepted_at),
        select: bc.user_id
    )
  end

  @doc """
  Gets the owner ID for a button.
  """
  def get_button_owner_id(button_id) do
    Repo.one(
      from b in Button,
        where: b.id == ^button_id,
        select: b.user_id
    )
  end

  @doc """
  Joins a button via share token.
  Adds the user as a collaborator if the token is valid.
  """
  def join_by_share_token(token, user_id) do
    case get_button_by_share_token(token) do
      {:ok, button} ->
        if button.sharing_mode == "public" do
          # Check if already a collaborator
          if is_collaborator?(button.id, user_id) or button.user_id == user_id do
            {:ok, button}
          else
            # Add as collaborator
            case add_collaborator_direct(button.id, user_id, button.user_id) do
              {:ok, _} -> {:ok, button}
              error -> error
            end
          end
        else
          {:error, :not_public}
        end

      error -> error
    end
  end

  # Add collaborator directly without owner check (for public link joins)
  defp add_collaborator_direct(button_id, user_id, invited_by_id) do
    %ButtonCollaborator{}
    |> ButtonCollaborator.changeset(%{
      button_id: button_id,
      user_id: user_id,
      invited_by_id: invited_by_id,
      permission: "click",
      accepted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert()
  end

  defp notify_collaborator_added(button, owner_id, collaborator_id) do
    alias ButtonLog.Alerts

    owner = ButtonLog.Accounts.get_user!(owner_id)

    Alerts.create_alert(%{
      alert_type: "button_shared_with_you",
      title: "Button Shared!",
      message: "#{owner.display_name || owner.username} shared '#{button.name}' with you",
      metadata: %{
        button_id: button.id,
        button_name: button.name,
        owner_id: owner_id
      }
    }, collaborator_id, owner_id, button.id)
  end

  @doc """
  Lists all buttons accessible to a user (own buttons + shared with me).
  Returns own buttons first, then shared buttons with owner info.
  """
  def list_accessible_buttons(user_id) do
    # Get own buttons
    own_buttons = list_user_buttons(user_id)
    |> Enum.map(fn button ->
      Map.merge(button, %{
        is_shared_with_me: false,
        owner_id: user_id,
        owner_name: nil
      })
    end)

    # Get buttons shared with this user
    shared_buttons = list_buttons_shared_with_user(user_id)

    # Combine and return
    own_buttons ++ shared_buttons
  end

  @doc """
  Lists buttons that have been shared with a user.
  Includes buttons where:
  - User is an explicit collaborator
  - Button is shared with friends and user is a friend
  """
  def list_buttons_shared_with_user(user_id) do
    # Get buttons where user is an explicit collaborator
    collaborator_button_ids = Repo.all(
      from bc in ButtonCollaborator,
        where: bc.user_id == ^user_id and not is_nil(bc.accepted_at),
        select: bc.button_id
    )

    # Get friend IDs for checking "friends" sharing mode
    friend_ids = ButtonLog.Social.get_user_friend_ids(user_id)

    # Query buttons that are shared with this user
    Repo.all(
      from b in Button,
        left_join: bc in ButtonClick, on: b.id == bc.button_id,
        join: owner in assoc(b, :user),
        where: b.user_id != ^user_id,  # Not own buttons
        where: (is_nil(b.archived) or b.archived == false),  # Not archived
        where: (
          # Explicit collaborator
          b.id in ^collaborator_button_ids or
          # Friends sharing mode and is a friend
          (b.sharing_mode == "friends" and b.user_id in ^friend_ids)
        ),
        group_by: [b.id, b.name, b.description, b.type, b.icon, b.color, b.is_active,
                   b.current_state, b.state_changed_at, b.alerts_enabled,
                   b.auto_stop_enabled, b.auto_stop_minutes, b.scheduled_stop_at,
                   b.calendar_sync_enabled, b.user_id,
                   b.inserted_at, b.updated_at, b.sharing_mode, owner.id,
                   owner.display_name, owner.username],
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
          alerts_enabled: b.alerts_enabled,
          auto_stop_enabled: b.auto_stop_enabled,
          auto_stop_minutes: b.auto_stop_minutes,
          scheduled_stop_at: b.scheduled_stop_at,
          calendar_sync_enabled: b.calendar_sync_enabled,
          user_id: b.user_id,
          inserted_at: b.inserted_at,
          updated_at: b.updated_at,
          latest_click_at: max(bc.clicked_at),
          sharing_mode: b.sharing_mode,
          is_shared_with_me: true,
          owner_id: owner.id,
          owner_name: coalesce(owner.display_name, owner.username)
        }
    )
  end

  # =============================================================================
  # Auto-Stop Functions
  # =============================================================================

  @doc """
  Returns all buttons that have scheduled stops that are due.
  Used by the auto-stop background job.
  """
  def list_buttons_due_for_auto_stop do
    now = DateTime.utc_now()

    Repo.all(
      from b in Button,
        where: not is_nil(b.scheduled_stop_at) and b.scheduled_stop_at <= ^now,
        where: b.current_state == "active"
    )
  end

  @doc """
  Processes auto-stop for a single button.
  Called by the background job for each button that is due.
  """
  def process_auto_stop(button_id) do
    case Repo.get(Button, button_id) do
      nil ->
        {:error, :not_found}

      button ->
        if button.current_state == "active" and button.scheduled_stop_at do
          perform_auto_stop(button)
        else
          {:ok, :already_stopped}
        end
    end
  end

  defp perform_auto_stop(button) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    result = Repo.transaction(fn ->
      # Update button state to idle and clear scheduled_stop_at
      button
      |> Button.changeset(%{
        current_state: "idle",
        state_changed_at: now,
        scheduled_stop_at: nil
      })
      |> Repo.update!()

      # Create a button click record with "auto_stop" action
      %ButtonClick{}
      |> ButtonClick.create_changeset(%{
        device: "system",
        platform: "auto_stop",
        action: "auto_stop"
      }, button.id, button.user_id)
      |> Repo.insert!()
    end)

    # Send notification to the user about auto-stop
    case result do
      {:ok, click} ->
        notify_auto_stop(button)
        {:ok, click}

      error ->
        error
    end
  end

  defp notify_auto_stop(button) do
    alias ButtonLog.Alerts

    # Calculate how long the button was active
    duration_text = format_auto_stop_duration(button.auto_stop_minutes)

    Alerts.create_alert(%{
      alert_type: "button_auto_stopped",
      title: "#{button.name} auto-stopped",
      message: "Your button '#{button.name}' was automatically stopped after #{duration_text}",
      metadata: %{
        button_id: button.id,
        button_name: button.name,
        auto_stop_minutes: button.auto_stop_minutes
      }
    }, button.user_id, button.user_id, button.id)
  end

  defp format_auto_stop_duration(nil), do: "the configured time"
  defp format_auto_stop_duration(minutes) when minutes < 60, do: "#{minutes} minutes"
  defp format_auto_stop_duration(60), do: "1 hour"
  defp format_auto_stop_duration(minutes) when rem(minutes, 60) == 0, do: "#{div(minutes, 60)} hours"
  defp format_auto_stop_duration(minutes), do: "#{div(minutes, 60)} hours and #{rem(minutes, 60)} minutes"

  @doc """
  Processes all buttons due for auto-stop.
  Called periodically by the auto-stop worker.
  Returns the count of buttons processed.
  """
  def process_all_auto_stops do
    buttons = list_buttons_due_for_auto_stop()

    results = Enum.map(buttons, fn button ->
      process_auto_stop(button.id)
    end)

    success_count = Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)

    {:ok, success_count}
  end
end
