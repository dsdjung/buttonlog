defmodule ButtonLogWeb.API.ExportController do
  use ButtonLogWeb, :controller
  alias ButtonLog.DataExport

  @doc """
  Export user data in the requested format (json or csv)
  """
  def export(conn, params) do
    user = conn.assigns.current_user
    format = Map.get(params, "format", "json")

    case DataExport.export_user_data(user.id, format) do
      {:ok, content, filename, content_type} ->
        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, content)

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "EXPORT_FAILED",
            message: message
          }
        })
    end
  end

  @doc """
  Get export metadata without downloading the file (useful for UI preparation)
  """
  def export_info(conn, _params) do
    user = conn.assigns.current_user

    # Get counts for display
    buttons_count = ButtonLog.Buttons.count_user_buttons(user.id)
    clicks_count = ButtonLog.Buttons.count_user_clicks(user.id)
    friends_count = ButtonLog.Social.count_user_friends(user.id)

    conn
    |> json(%{
      success: true,
      data: %{
        buttons_count: buttons_count,
        clicks_count: clicks_count,
        friends_count: friends_count,
        available_formats: ["json", "csv"],
        estimated_size: estimate_export_size(buttons_count, clicks_count, friends_count)
      }
    })
  end

  defp estimate_export_size(buttons, clicks, friends) do
    # Rough estimate: ~500 bytes per button, ~200 bytes per click, ~100 bytes per friend
    bytes = (buttons * 500) + (clicks * 200) + (friends * 100) + 1000
    format_size(bytes)
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"
end
