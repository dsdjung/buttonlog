defmodule ButtonLogWeb.DiaryLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Accounts
  alias ButtonLog.Repo
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      # Default to UTC until we get timezone from browser
      # The timezone_offset will be updated by the client-side hook
      timezone_offset = 0
      today = get_local_today(timezone_offset)

      # Get today's activities by default
      activities = get_daily_activities(user_id, today, timezone_offset)
      summary = generate_daily_summary(activities, today, timezone_offset)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:selected_date, today)
       |> assign(:activities, activities)
       |> assign(:summary, summary)
       |> assign(:timezone_offset, timezone_offset)
       |> assign(:page_title, "Diary")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to view your diary")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("set_timezone", %{"offset" => offset}, socket) when is_integer(offset) do
    # offset is in minutes from UTC (e.g., -300 for EST, -240 for EDT)
    # Convert to hours for our calculations (negative because JS gives opposite sign)
    timezone_offset = -div(offset, 60)

    user_id = socket.assigns.current_user.id
    today = get_local_today(timezone_offset)
    activities = get_daily_activities(user_id, today, timezone_offset)
    summary = generate_daily_summary(activities, today, timezone_offset)

    {:noreply,
     socket
     |> assign(:timezone_offset, timezone_offset)
     |> assign(:selected_date, today)
     |> assign(:activities, activities)
     |> assign(:summary, summary)}
  end

  def handle_event("set_timezone", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_date", params, socket) do
    case params do
      %{"date" => date_string} when is_binary(date_string) and date_string != "" ->
        process_date_selection(date_string, socket)

      %{"value" => date_string} when is_binary(date_string) and date_string != "" ->
        process_date_selection(date_string, socket)

      _ ->
        {:noreply, socket |> put_flash(:error, "Invalid date selection")}
    end
  end

  def handle_event("previous_day", _params, socket) do
    current_date = socket.assigns.selected_date
    previous_date = Date.add(current_date, -1)
    timezone_offset = socket.assigns.timezone_offset

    user_id = socket.assigns.current_user.id
    activities = get_daily_activities(user_id, previous_date, timezone_offset)
    summary = generate_daily_summary(activities, previous_date, timezone_offset)

    {:noreply,
     socket
     |> assign(:selected_date, previous_date)
     |> assign(:activities, activities)
     |> assign(:summary, summary)}
  end

  def handle_event("next_day", _params, socket) do
    current_date = socket.assigns.selected_date
    next_date = Date.add(current_date, 1)
    timezone_offset = socket.assigns.timezone_offset

    # Don't allow future dates
    today = get_local_today(timezone_offset)
    if Date.compare(next_date, today) == :gt do
      {:noreply, socket |> put_flash(:error, "Cannot view future dates")}
    else
      user_id = socket.assigns.current_user.id
      activities = get_daily_activities(user_id, next_date, timezone_offset)
      summary = generate_daily_summary(activities, next_date, timezone_offset)

              {:noreply,
         socket
         |> assign(:selected_date, next_date)
         |> assign(:activities, activities)
         |> assign(:summary, summary)}
    end
  end

  def handle_event("go_to_today", _params, socket) do
    timezone_offset = socket.assigns.timezone_offset
    today = get_local_today(timezone_offset)
    user_id = socket.assigns.current_user.id
    activities = get_daily_activities(user_id, today, timezone_offset)
    summary = generate_daily_summary(activities, today, timezone_offset)

    {:noreply,
     socket
       |> assign(:selected_date, today)
       |> assign(:activities, activities)
       |> assign(:summary, summary)}
  end

  def handle_event("refresh_in_progress", _params, socket) do
    # Refresh the current date's activities and summary to get updated durations
    user_id = socket.assigns.current_user.id
    selected_date = socket.assigns.selected_date
    timezone_offset = socket.assigns.timezone_offset
    activities = get_daily_activities(user_id, selected_date, timezone_offset)
    summary = generate_daily_summary(activities, selected_date, timezone_offset)

    {:noreply,
     socket
       |> put_flash(:info, "In-progress activities refreshed")
       |> assign(:activities, activities)
       |> assign(:summary, summary)}
  end



  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # Private helper functions

  # Helper function to process date selection
  defp process_date_selection(date_string, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, selected_date} ->
        user_id = socket.assigns.current_user.id
        timezone_offset = socket.assigns.timezone_offset
        activities = get_daily_activities(user_id, selected_date, timezone_offset)
        summary = generate_daily_summary(activities, selected_date, timezone_offset)

        {:noreply,
         socket
         |> put_flash(:info, "Date changed to #{Calendar.strftime(selected_date, "%B %d, %Y")}")
         |> assign(:selected_date, selected_date)
         |> assign(:activities, activities)
         |> assign(:summary, summary)}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Invalid date format: #{inspect(reason)}")}
    end
  end

  defp get_daily_activities(user_id, date, timezone_offset) do
    # Convert local date to UTC start/end times for database query
    # Since button clicks are stored in UTC, we need to query the UTC range
    # that corresponds to the local date, accounting for timezone offset
    #
    # timezone_offset is hours from UTC (e.g., -5 for EST, -4 for EDT, +1 for CET)
    # To convert local midnight to UTC, we subtract the offset
    # For EST (-5): local midnight = UTC 5:00 AM, so we add abs(-5) = 5 hours
    offset_seconds = -timezone_offset * 3600

    start_of_day = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    |> DateTime.add(offset_seconds, :second)

    end_of_day = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
    |> DateTime.add(offset_seconds, :second)

    # Get all button clicks for the user on the specified date
    clicks = Repo.all(
      from c in ButtonLog.Buttons.ButtonClick,
      join: b in ButtonLog.Buttons.Button, on: c.button_id == b.id,
      where: c.user_id == ^user_id and c.clicked_at >= ^start_of_day and c.clicked_at <= ^end_of_day,
      order_by: [desc: c.clicked_at],
      preload: [button: b]
    )

    # Group clicks by button
    clicks
    |> Enum.group_by(fn click -> click.button_id end)
    |> Enum.map(fn {_button_id, button_clicks} ->
      button = List.first(button_clicks).button

      # For toggle buttons, calculate total active duration including sessions that started before this date
      total_duration = if button.type == "toggle" do
        calculate_toggle_button_duration(button.id, user_id, start_of_day, end_of_day)
      else
        0
      end

      %{
        button: button,
        clicks: button_clicks,
        total_clicks: length(button_clicks),
        first_click: List.first(button_clicks).clicked_at,
        last_click: List.last(button_clicks).clicked_at,
        total_duration: total_duration
      }
    end)
    |> Enum.sort_by(fn activity -> activity.total_clicks end, :desc)
  end

  defp generate_daily_summary(activities, date, timezone_offset) do
    total_buttons_used = length(activities)
    total_clicks = Enum.reduce(activities, 0, fn activity, acc -> acc + activity.total_clicks end)

    # Get most active button
    most_active = if activities != [] do
      List.first(activities)
    else
      nil
    end

    # Get button types used
    button_types = activities
    |> Enum.map(fn activity -> activity.button.type end)
    |> Enum.uniq()
    |> Enum.sort()

    # Get in-progress toggle buttons
    in_progress_toggle_buttons = get_in_progress_toggle_buttons(activities)

    # Calculate total active time from all toggle buttons
    # This includes both completed sessions and currently active sessions
    total_active_time = activities
    |> Enum.filter(fn activity -> activity.button.type == "toggle" end)
    |> Enum.reduce(0, fn activity, acc ->
      # For currently active buttons, add the current session time
      if activity.button.current_state == "active" do
        # Get the current session duration (time since it started)
        current_session_duration = get_current_session_duration(activity)
        acc + activity.total_duration + current_session_duration
      else
        acc + activity.total_duration
      end
    end)

    # Format activities for display
    formatted_activities = Enum.map(activities, fn activity ->
      format_button_activity(activity)
    end)

    %{
      date: date,
      total_buttons_used: total_buttons_used,
      total_clicks: total_clicks,
      most_active_button: most_active,
      button_types_used: button_types,
      formatted_activities: formatted_activities,
      in_progress_toggle_buttons: in_progress_toggle_buttons,
      total_active_time: total_active_time,
      is_today: Date.compare(date, get_local_today(timezone_offset)) == :eq,
      is_empty: activities == []
    }
  end

  # Helper function to format button activity for display
  defp format_button_activity(activity) do
    button = activity.button

    case button.type do
      "instant" ->
        # For instant buttons, show click count
        click_count = activity.total_clicks
        count_text = if click_count == 1, do: "once", else: "#{click_count} times"
        "#{button.name} #{count_text}"

      "toggle" ->
        # For toggle buttons, show session count and total duration
        session_count = count_active_sessions(activity.clicks)
        count_text = if session_count == 1, do: "once", else: "#{session_count} times"

        # Calculate total duration including current session if active
        total_duration = if button.current_state == "active" do
          current_session_duration = get_current_session_duration(activity)
          activity.total_duration + current_session_duration
        else
          activity.total_duration
        end

        duration_text = if total_duration > 0 do
          format_duration(total_duration)
        else
          "0 minutes"
        end
        state_text = if button.current_state == "active", do: " (in progress)", else: ""
        "#{button.name} #{count_text} for #{duration_text}#{state_text}"

      "workflow" ->
        # For workflow buttons, show click count and current state
        click_count = activity.total_clicks
        count_text = if click_count == 1, do: "once", else: "#{click_count} times"
        state_text = if button.current_state == "active", do: " (in progress)", else: ""
        "#{button.name} #{count_text}#{state_text}"

      _ ->
        # Fallback for unknown types
        click_count = activity.total_clicks
        count_text = if click_count == 1, do: "once", else: "#{click_count} times"
        "#{button.name} #{count_text}"
    end
  end



  # Format duration in hours and minutes
  defp format_duration(total_seconds) when is_integer(total_seconds) and total_seconds > 0 do
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)

    cond do
      hours > 0 and minutes > 0 ->
        "#{hours} hour#{if hours == 1, do: "", else: "s"} #{minutes} minute#{if minutes == 1, do: "", else: "s"}"
      hours > 0 ->
        "#{hours} hour#{if hours == 1, do: "", else: "s"}"
      minutes > 0 ->
        "#{minutes} minute#{if minutes == 1, do: "", else: "s"}"
      true ->
        "less than a minute"
    end
  end

  defp format_duration(_), do: "0 minutes"

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp is_today?(date, timezone_offset) do
    Date.compare(date, get_local_today(timezone_offset)) == :eq
  end

  defp is_yesterday?(date, timezone_offset) do
    Date.compare(date, Date.add(get_local_today(timezone_offset), -1)) == :eq
  end

  defp is_tomorrow?(date, timezone_offset) do
    Date.compare(date, Date.add(get_local_today(timezone_offset), 1)) == :eq
  end

  defp get_relative_date_text(date, timezone_offset) do
    cond do
      is_today?(date, timezone_offset) -> "Today"
      is_yesterday?(date, timezone_offset) -> "Yesterday"
      is_tomorrow?(date, timezone_offset) -> "Tomorrow"
      true -> format_date(date)
    end
  end

  # Get today's date in local timezone based on the provided offset
  defp get_local_today(timezone_offset) when is_integer(timezone_offset) do
    utc_now = DateTime.utc_now()
    # timezone_offset is hours from UTC (e.g., -5 for EST, +1 for CET)
    local_now = DateTime.add(utc_now, timezone_offset * 3600, :second)
    DateTime.to_date(local_now)
  end

  defp get_local_today(_), do: Date.utc_today()

    # Calculate total active duration for a toggle button within a date range
  # This handles sessions that started before the date and multiple active periods
  defp calculate_toggle_button_duration(button_id, user_id, start_of_day, end_of_day) do
    # Get all clicks for this button within the date range
    clicks_in_range = Repo.all(
      from c in ButtonLog.Buttons.ButtonClick,
      where: c.button_id == ^button_id and c.user_id == ^user_id and c.clicked_at >= ^start_of_day and c.clicked_at <= ^end_of_day,
      order_by: [asc: c.clicked_at]
    )

    # Get the last click before the start of the day to see if button was already active
    last_click_before = Repo.one(
      from c in ButtonLog.Buttons.ButtonClick,
      where: c.button_id == ^button_id and c.user_id == ^user_id and c.clicked_at < ^start_of_day,
      order_by: [desc: c.clicked_at],
      limit: 1
    )

    # Get the first click after the end of the day to see if button continued after
    first_click_after = Repo.one(
      from c in ButtonLog.Buttons.ButtonClick,
      where: c.button_id == ^button_id and c.user_id == ^user_id and c.clicked_at > ^end_of_day,
      order_by: [asc: c.clicked_at],
      limit: 1
    )

    # Calculate duration from sessions within the date range
    duration_from_range = calculate_duration_from_clicks(clicks_in_range, start_of_day, end_of_day)

    # Add duration from session that started before the date (if still active)
    duration_from_previous = if last_click_before do
      # If the last click before the date was a "start" action, the button was active at the beginning of the day
      if last_click_before.action == "start" do
        # Calculate duration from start of day to first click in range (or end of day if no clicks)
        first_click_in_range = List.first(clicks_in_range)
        end_time = if first_click_in_range, do: first_click_in_range.clicked_at, else: end_of_day
        DateTime.diff(end_time, start_of_day, :second)
      else
        0
      end
    else
      0
    end

    # Add duration from session that continues after the date (if still active)
    duration_from_after = if first_click_after do
      # If the first click after the date is an "end" action, the button was active until then
      if first_click_after.action == "end" do
        # Calculate duration from last click in range to end of day
        last_click_in_range = List.last(clicks_in_range)
        start_time = if last_click_in_range, do: last_click_in_range.clicked_at, else: start_of_day
        DateTime.diff(end_of_day, start_time, :second)
      else
        0
      end
    else
      0
    end

    duration_from_range + duration_from_previous + duration_from_after
  end

  # Calculate duration from a list of clicks within a date range
  defp calculate_duration_from_clicks(clicks, start_of_day, end_of_day) do
    # Sort clicks by time
    sorted_clicks = Enum.sort_by(clicks, & &1.clicked_at, :asc)

    # Process each click to find start/stop pairs using reduce
    {active_periods, current_start} =
      Enum.reduce(sorted_clicks, {[], nil}, fn click, {periods, curr_start} ->
        case click.action do
          "start" ->
            # If we already have a start, end the previous session
            new_periods =
              if curr_start do
                end_time = if DateTime.compare(curr_start, start_of_day) == :lt, do: start_of_day, else: curr_start
                duration = DateTime.diff(click.clicked_at, end_time, :second)
                if duration > 0, do: [{end_time, click.clicked_at} | periods], else: periods
              else
                periods
              end
            {new_periods, click.clicked_at}

          "end" ->
            # End the current session
            if curr_start do
              end_time = if DateTime.compare(curr_start, start_of_day) == :lt, do: start_of_day, else: curr_start
              duration = DateTime.diff(click.clicked_at, end_time, :second)
              new_periods = if duration > 0, do: [{end_time, click.clicked_at} | periods], else: periods
              {new_periods, nil}
            else
              {periods, nil}
            end

          _ ->
            # For regular clicks, no action needed for duration calculation
            {periods, curr_start}
        end
      end)

    # If we still have an active session at the end, calculate its duration
    final_periods =
      if current_start do
        end_time = if DateTime.compare(current_start, start_of_day) == :lt, do: start_of_day, else: current_start
        duration = DateTime.diff(end_of_day, end_time, :second)
        if duration > 0, do: [{end_time, end_of_day} | active_periods], else: active_periods
      else
        active_periods
      end

    # If we have no explicit start/end actions but multiple clicks, treat them as implicit sessions
    # This handles the case where buttons are started/stopped by clicking rather than explicit actions
    if final_periods == [] and length(clicks) > 1 do
      # Group clicks into potential sessions (clicks that are close together)
      implicit_sessions = group_clicks_into_sessions(clicks, start_of_day, end_of_day)
      Enum.reduce(implicit_sessions, 0, fn {session_start, session_end}, acc ->
        acc + DateTime.diff(session_end, session_start, :second)
      end)
    else
      # Sum up all active periods
      Enum.reduce(final_periods, 0, fn {period_start, period_end}, acc ->
        acc + DateTime.diff(period_end, period_start, :second)
      end)
    end
  end

  # Get the duration of the current active session for a button
  defp get_current_session_duration(activity) do
    # Find the most recent start action or the most recent click if no explicit start
    start_time = case Enum.find(activity.clicks, fn click -> click.action == "start" end) do
      nil ->
        # No explicit start action, use the most recent click
        case List.first(activity.clicks) do
          nil -> nil
          click -> click.clicked_at
        end
      start_click -> start_click.clicked_at
    end

    if start_time do
      # Calculate time from start until now
      now = DateTime.utc_now()
      DateTime.diff(now, start_time, :second)
    else
      0
    end
  end

  # Count how many times a toggle button was active (sessions, not clicks)
  def count_active_sessions(clicks) do
    # Sort clicks by time
    sorted_clicks = Enum.sort_by(clicks, & &1.clicked_at, :asc)

    # If we have explicit start/end actions, count those
    start_actions = Enum.count(sorted_clicks, fn click -> click.action == "start" end)
    end_actions = Enum.count(sorted_clicks, fn click -> click.action == "end" end)

    if start_actions > 0 or end_actions > 0 do
      # Use explicit actions to count sessions
      # A session starts with "start" and ends with "end"
      # If we have more starts than ends, the last session is still active
      max(start_actions, end_actions)
    else
      # No explicit actions, count implicit sessions
      # Group clicks into pairs to count sessions
      case length(sorted_clicks) do
        0 -> 0
        1 -> 1  # Single click = 1 session
        _ ->
          # Multiple clicks = multiple sessions (each pair represents start/stop)
          # Round up to handle odd number of clicks
          ceil(length(sorted_clicks) / 2)
      end
    end
  end

  # Group clicks into implicit sessions for buttons without explicit start/end actions
  defp group_clicks_into_sessions(clicks, start_of_day, end_of_day) do
    # Sort clicks by time
    sorted_clicks = Enum.sort_by(clicks, & &1.clicked_at, :asc)

    # If we have 2 or more clicks, treat them as start/stop pairs
    if length(sorted_clicks) >= 2 do
      # Group clicks into pairs (start, stop)
      Enum.chunk_every(sorted_clicks, 2)
      |> Enum.map(fn click_pair ->
        case click_pair do
          [start_click, stop_click] ->
            # Use the actual click times, but ensure they're within the day bounds
            start_time = if start_click.clicked_at < start_of_day, do: start_of_day, else: start_click.clicked_at
            end_time = if stop_click.clicked_at > end_of_day, do: end_of_day, else: stop_click.clicked_at
            {start_time, end_time}

          [single_click] ->
            # Single click - treat as a brief session
            start_time = if single_click.clicked_at < start_of_day, do: start_of_day, else: single_click.clicked_at
            end_time = if single_click.clicked_at > end_of_day, do: end_of_day, else: single_click.clicked_at
            {start_time, end_time}
        end
      end)
    else
      # Single click - treat as a brief session
      [click] = sorted_clicks
      start_time = if click.clicked_at < start_of_day, do: start_of_day, else: click.clicked_at
      end_time = if click.clicked_at > end_of_day, do: end_of_day, else: click.clicked_at
      [{start_time, end_time}]
    end
  end

  # Get in-progress toggle buttons from activities
  defp get_in_progress_toggle_buttons(activities) do
    activities
    |> Enum.filter(fn activity ->
      # Only consider toggle buttons
      activity.button.type == "toggle"
    end)
    |> Enum.filter(fn activity ->
      # Use the same logic as the buttons page: check button.current_state
      # This ensures consistency between buttons page and diary
      case activity.button.current_state do
        "active" -> true
        "idle" -> false
        _ -> false  # Handle any other states
      end
    end)
    |> Enum.map(fn activity ->
      # For buttons with current_state "active", we need to determine when they started
      # We'll use the most recent click as the start time, or fall back to a reasonable default
      start_click = Enum.find(activity.clicks, fn click -> click.action == "start" end)
      recent_click = List.first(activity.clicks)  # Most recent click

      start_time = if start_click, do: start_click.clicked_at, else: recent_click.clicked_at

      # Calculate total duration including current session if active
      total_duration_today = if activity.button.current_state == "active" do
        current_session_duration = get_current_session_duration(activity)
        activity.total_duration + current_session_duration
      else
        activity.total_duration
      end

      %{
        button: activity.button,
        start_time: start_time,
        duration_so_far: calculate_duration_since_start(start_time),
        total_clicks: activity.total_clicks,
        total_duration_today: total_duration_today
      }
    end)
  end

  # Calculate duration since start time
  defp calculate_duration_since_start(start_time) when is_struct(start_time, DateTime) do
    now = DateTime.utc_now()
    DateTime.diff(now, start_time, :second)
  end

  defp calculate_duration_since_start(_), do: 0

  # Format relative time (e.g., "2 hours ago", "30 minutes ago")
  defp format_relative_time(start_time) when is_struct(start_time, DateTime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, start_time, :second)

    cond do
      diff_seconds < 60 ->
        "#{diff_seconds} second#{if diff_seconds == 1, do: "", else: "s"}"
      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes} minute#{if minutes == 1, do: "", else: "s"}"
      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        "#{hours} hour#{if hours == 1, do: "", else: "s"}"
      true ->
        days = div(diff_seconds, 86400)
        "#{days} day#{if days == 1, do: "", else: "s"}"
    end
  end

  defp format_relative_time(_), do: "unknown time"
end
