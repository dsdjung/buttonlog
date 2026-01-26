defmodule ButtonLog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ButtonLogWeb.Telemetry,
      # Start the Ecto repository
      ButtonLog.Repo,
      # Start rate limiter (Hammer with ETS backend)
      {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]},
      # Start JWT token blacklist for token revocation
      ButtonLog.Auth.TokenBlacklist,
      # Start the PubSub system
      {Phoenix.PubSub, name: ButtonLog.PubSub},
      # Start Finch for HTTP/2 requests (APNs push notifications)
      {Finch,
       name: ButtonLog.Finch,
       pools: %{
         # APNs sandbox (HTTP/2)
         "https://api.sandbox.push.apple.com" => [
           size: 5,
           count: 1,
           protocol: :http2
         ],
         # APNs production (HTTP/2)
         "https://api.push.apple.com" => [
           size: 5,
           count: 1,
           protocol: :http2
         ],
         # Default HTTP/1.1 pool for other requests
         :default => [size: 10, count: 1]
       }},
      # Start the Endpoint (http/https)
      ButtonLogWeb.Endpoint,
      # Start the Auto-Stop worker for toggle buttons
      ButtonLog.Buttons.AutoStopWorker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ButtonLog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ButtonLogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
