defmodule ButtonLogWeb.HealthController do
  @moduledoc """
  Health check endpoint for load balancers and monitoring.
  """
  use ButtonLogWeb, :controller

  @doc """
  Returns health status of the application.
  Checks database connectivity and returns appropriate status.
  """
  def check(conn, _params) do
    case check_database() do
      :ok ->
        conn
        |> put_status(:ok)
        |> json(%{
          status: "healthy",
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
          version: Application.spec(:buttonlog, :vsn) |> to_string(),
          checks: %{
            database: "ok"
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          status: "unhealthy",
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
          version: Application.spec(:buttonlog, :vsn) |> to_string(),
          checks: %{
            database: "error: #{inspect(reason)}"
          }
        })
    end
  end

  defp check_database do
    try do
      # Simple query to verify database connectivity
      ButtonLog.Repo.query!("SELECT 1")
      :ok
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
end
