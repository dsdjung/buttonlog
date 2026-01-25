defmodule ButtonLog.DataExport do
  @moduledoc """
  Handles user data export functionality.
  """

  alias ButtonLog.Repo
  alias ButtonLog.Accounts.User
  alias ButtonLog.Buttons.{Button, ButtonClick}
  alias ButtonLog.Social.Friendship

  import Ecto.Query

  @doc """
  Export all user data in the specified format.
  Returns {:ok, data, filename} or {:error, reason}
  """
  def export_user_data(user_id, format \\ "json") when format in ["json", "csv"] do
    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}

      user ->
        data = gather_user_data(user)

        case format do
          "json" -> export_json(data, user.username)
          "csv" -> export_csv(data, user.username)
        end
    end
  end

  defp gather_user_data(user) do
    buttons = get_user_buttons(user.id)
    button_clicks = get_user_button_clicks(user.id)
    friendships = get_user_friendships(user.id)

    %{
      exported_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      user: %{
        id: user.id,
        email: user.email,
        username: user.username,
        display_name: user.display_name,
        first_name: user.first_name,
        last_name: user.last_name,
        timezone: user.timezone,
        language: user.language,
        profile_visibility: user.profile_visibility,
        activity_visibility: user.activity_visibility,
        subscription_tier: user.subscription_tier,
        created_at: format_datetime(user.inserted_at),
        updated_at: format_datetime(user.updated_at)
      },
      buttons: Enum.map(buttons, &format_button/1),
      button_clicks: Enum.map(button_clicks, &format_click/1),
      friends: Enum.map(friendships, &format_friendship/1),
      statistics: %{
        total_buttons: length(buttons),
        total_clicks: length(button_clicks),
        total_friends: length(friendships)
      }
    }
  end

  defp get_user_buttons(user_id) do
    from(b in Button, where: b.user_id == ^user_id, order_by: [desc: b.inserted_at])
    |> Repo.all()
  end

  defp get_user_button_clicks(user_id) do
    from(bc in ButtonClick,
      where: bc.user_id == ^user_id,
      order_by: [desc: bc.clicked_at],
      preload: [:button]
    )
    |> Repo.all()
  end

  defp get_user_friendships(user_id) do
    from(f in Friendship,
      where: f.user_id == ^user_id and f.status == "accepted",
      preload: [:friend]
    )
    |> Repo.all()
  end

  defp format_button(button) do
    %{
      id: button.id,
      name: button.name,
      description: button.description,
      type: button.type,
      icon: button.icon,
      color: button.color,
      current_state: button.current_state,
      click_count: button.click_count,
      sharing_mode: button.sharing_mode,
      created_at: format_datetime(button.inserted_at),
      updated_at: format_datetime(button.updated_at)
    }
  end

  defp format_click(click) do
    %{
      id: click.id,
      button_name: click.button && click.button.name,
      button_id: click.button_id,
      action: click.action,
      selected_choice: click.selected_choice,
      clicked_at: format_datetime(click.clicked_at)
    }
  end

  defp format_friendship(friendship) do
    %{
      friend_id: friendship.friend_id,
      friend_username: friendship.friend && friendship.friend.username,
      friend_display_name: friendship.friend && friendship.friend.display_name,
      status: friendship.status,
      created_at: format_datetime(friendship.inserted_at)
    }
  end

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_datetime(%NaiveDateTime{} = ndt) do
    ndt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp export_json(data, username) do
    json_content = Jason.encode!(data, pretty: true)
    filename = "buttonlog_export_#{username}_#{Date.utc_today()}.json"
    {:ok, json_content, filename, "application/json"}
  end

  defp export_csv(data, username) do
    # Create CSV with multiple sections
    csv_content = [
      "# ButtonLog Data Export",
      "# Exported at: #{data.exported_at}",
      "# User: #{data.user.username}",
      "",
      "## USER PROFILE",
      "field,value",
      "id,#{data.user.id}",
      "email,#{escape_csv(data.user.email)}",
      "username,#{escape_csv(data.user.username)}",
      "display_name,#{escape_csv(data.user.display_name)}",
      "first_name,#{escape_csv(data.user.first_name)}",
      "last_name,#{escape_csv(data.user.last_name)}",
      "subscription_tier,#{data.user.subscription_tier}",
      "created_at,#{data.user.created_at}",
      "",
      "## BUTTONS (#{data.statistics.total_buttons})",
      "id,name,type,icon,color,click_count,created_at",
      Enum.map(data.buttons, &button_to_csv_row/1),
      "",
      "## BUTTON CLICKS (#{data.statistics.total_clicks})",
      "id,button_name,action,selected_choice,clicked_at",
      Enum.map(data.button_clicks, &click_to_csv_row/1),
      "",
      "## FRIENDS (#{data.statistics.total_friends})",
      "friend_id,username,display_name,status,connected_at",
      Enum.map(data.friends, &friend_to_csv_row/1)
    ]
    |> List.flatten()
    |> Enum.join("\n")

    filename = "buttonlog_export_#{username}_#{Date.utc_today()}.csv"
    {:ok, csv_content, filename, "text/csv"}
  end

  defp button_to_csv_row(button) do
    "#{button.id},#{escape_csv(button.name)},#{button.type},#{button.icon},#{button.color},#{button.click_count},#{button.created_at}"
  end

  defp click_to_csv_row(click) do
    "#{click.id},#{escape_csv(click.button_name)},#{click.action},#{escape_csv(click.selected_choice)},#{click.clicked_at}"
  end

  defp friend_to_csv_row(friend) do
    "#{friend.friend_id},#{escape_csv(friend.friend_username)},#{escape_csv(friend.friend_display_name)},#{friend.status},#{friend.created_at}"
  end

  defp escape_csv(nil), do: ""
  defp escape_csv(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end
  defp escape_csv(value), do: to_string(value)
end
