defmodule ButtonLogWeb.API.ConfigController do
  @moduledoc """
  Configuration endpoint for mobile apps.

  Provides version requirements, feature flags, and maintenance status
  to help mobile apps handle backwards compatibility gracefully.
  """
  use ButtonLogWeb, :controller

  @doc """
  Returns app configuration for mobile clients.

  Response includes:
  - min_supported_version: Minimum app version that works with this API
  - latest_version: Latest available app versions per platform
  - features: Feature flags for gradual rollouts
  - maintenance_mode: Whether the service is in maintenance
  - api_version: Current API version
  """
  def index(conn, _params) do
    config = get_app_config()
    json(conn, config)
  end

  defp get_app_config do
    %{
      # Minimum version required to use the API
      # Bump this when making breaking changes
      min_supported_version: %{
        ios: "1.0.0",
        android: "1.0.0"
      },
      # Latest available versions (for update prompts)
      latest_version: %{
        ios: "1.0.0",
        android: "1.0.0"
      },
      # Feature flags for gradual rollouts
      features: %{
        push_notifications: true,
        friend_alerts: true,
        subscriptions: true,
        teams: true,
        organizations: true,
        diary_view: true,
        button_sharing: true,
        gift_buttons: true
      },
      # Maintenance mode
      maintenance_mode: false,
      maintenance_message: nil,
      # API versioning
      api_version: "1",
      # Server timestamp for client sync
      server_time: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
