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
      # Start the PubSub system
      {Phoenix.PubSub, name: ButtonLog.PubSub},
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
