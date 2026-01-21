defmodule ButtonLog.Buttons do
  @moduledoc """
  The Buttons context.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Buttons.{Button, ButtonClick}

  @doc """
  Returns the list of buttons for a user with latest click time.
  """
  def list_user_buttons(user_id) do
    # Get buttons with their latest click time
    Repo.all(
      from b in Button,
      left_join: bc in ButtonClick, on: b.id == bc.button_id,
      where: b.user_id == ^user_id,
      group_by: [b.id, b.name, b.description, b.type, b.icon, b.color, b.is_active, b.current_state, b.state_changed_at, b.notifications_enabled, b.auto_stop_enabled, b.calendar_sync_enabled, b.user_id, b.inserted_at, b.updated_at],
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
        latest_click_at: max(bc.clicked_at)
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
    %Button{}
    |> Button.create_changeset(attrs, user_id)
    |> Repo.insert()
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
        case button.type do
          "timed" ->
            handle_timed_button_click(button, user_id)

          "state" ->
            handle_state_button_click(button, user_id)

          _other_type ->
            # For instant buttons, just record a click
            %ButtonClick{}
            |> ButtonClick.create_changeset(%{
              device: "web",
              platform: "web",
              action: "click"
            }, button_id, user_id)
            |> Repo.insert()
        end

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

    Repo.transaction(fn ->
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
    Repo.transaction(fn ->
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
  """
  def list_friend_button_activity(friend_id, limit \\ 50) do
    Repo.all(
      from bc in ButtonClick,
      join: b in Button, on: b.id == bc.button_id,
      where: b.user_id == ^friend_id,
      order_by: [desc: bc.clicked_at],
      limit: ^limit,
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
    )
  end
end
