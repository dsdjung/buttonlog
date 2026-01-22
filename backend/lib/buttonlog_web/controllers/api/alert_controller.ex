defmodule ButtonLogWeb.API.AlertController do
  @moduledoc """
  API controller for managing user alerts (in-app friend alerts).
  This replaces the notification endpoints for friend-to-friend alerts.
  """

  use ButtonLogWeb, :controller
  alias ButtonLog.Alerts

  @doc """
  List all alerts for the current user.
  GET /api/alerts
  """
  def index(conn, params) do
    user = conn.assigns.current_user
    limit = Map.get(params, "limit", "50") |> String.to_integer()
    offset = Map.get(params, "offset", "0") |> String.to_integer()

    {alerts, has_more} = Alerts.get_user_alerts_paginated(user.id, limit, offset)

    conn
    |> json(%{
      success: true,
      data: Enum.map(alerts, &format_alert/1),
      pagination: %{
        has_more: has_more,
        offset: offset,
        limit: limit
      }
    })
  end

  @doc """
  Get unread alerts count for the current user.
  GET /api/alerts/unread/count
  """
  def unread_count(conn, _params) do
    user = conn.assigns.current_user
    count = Alerts.count_unread_alerts(user.id)

    conn
    |> json(%{
      success: true,
      data: %{count: count}
    })
  end

  @doc """
  Get unread alerts for the current user.
  GET /api/alerts/unread
  """
  def unread(conn, _params) do
    user = conn.assigns.current_user
    alerts = Alerts.get_unread_alerts(user.id)

    conn
    |> json(%{
      success: true,
      data: Enum.map(alerts, &format_alert/1)
    })
  end

  @doc """
  Mark a specific alert as read.
  PUT /api/alerts/:id/read
  """
  def mark_read(conn, %{"id" => alert_id}) do
    user = conn.assigns.current_user

    case Alerts.mark_alert_read(alert_id, user.id) do
      {:ok, alert} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: alert.id,
            read: alert.read
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "ALERT_NOT_FOUND",
            message: "Alert not found"
          }
        })
    end
  end

  @doc """
  Mark all alerts as read for the current user.
  PUT /api/alerts/read-all
  """
  def mark_all_read(conn, _params) do
    user = conn.assigns.current_user

    case Alerts.mark_all_alerts_read(user.id) do
      {:ok, count} ->
        conn
        |> json(%{
          success: true,
          data: %{
            marked_count: count
          }
        })
    end
  end

  @doc """
  Get alerts from a specific friend.
  GET /api/alerts/from/:friend_id
  """
  def from_friend(conn, %{"friend_id" => friend_id}) do
    user = conn.assigns.current_user
    alerts = Alerts.get_alerts_from_friend(user.id, friend_id)

    conn
    |> json(%{
      success: true,
      data: Enum.map(alerts, &format_alert/1)
    })
  end

  # Private helper to format alert for JSON response
  defp format_alert(alert) do
    %{
      id: alert.id,
      title: alert.title,
      body: alert.message,
      type: alert.alert_type,
      read: alert.read,
      clicked_at: alert.clicked_at,
      metadata: alert.metadata,
      sender:
        if alert.sender do
          %{
            id: alert.sender.id,
            username: alert.sender.username,
            display_name: alert.sender.display_name
          }
        else
          nil
        end,
      button:
        if alert.button do
          %{
            id: alert.button.id,
            name: alert.button.name
          }
        else
          nil
        end,
      inserted_at: alert.inserted_at
    }
  end
end
