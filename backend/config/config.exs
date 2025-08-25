# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# Configure the database
config :buttonlog, ButtonLog.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "buttonlog_#{config_env()}",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configure Ecto repos
config :buttonlog, ecto_repos: [ButtonLog.Repo]

# Configure the endpoint
config :buttonlog, ButtonLogWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: ButtonLogWeb.ErrorHTML, json: ButtonLogWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ButtonLog.PubSub,
  live_view: [signing_salt: "OpMfVMm+KAaQxZE/1O3FoKPn9i9QCXRLuiK3/JmD5dd1KOfqQfw1+7cPXJksvAk4"],
  secret_key_base: "Kh7LIE0FWdaQ/ThYYCasCt7AUPeIPkfgOp0oPWAfUH7ig2y0ukEFTMIjofcXolgh"



# Configure Swoosh for email
config :swoosh, :api_client, false

# Do not print debug messages in production
config :logger, level: :info

# Runtime configuration
config :buttonlog, :env, config_env()

  # OAuth Configuration
  config :ueberauth, Ueberauth,
    providers: [
      google: {Ueberauth.Strategy.Google, [
        client_id: System.get_env("GOOGLE_CLIENT_ID"),
        client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
      ]},
      facebook: {Ueberauth.Strategy.Facebook, [
        client_id: System.get_env("FACEBOOK_CLIENT_ID"),
        client_secret: System.get_env("FACEBOOK_CLIENT_SECRET")
      ]},
      apple: {Ueberauth.Strategy.Apple, [
        client_id: System.get_env("APPLE_CLIENT_ID"),
        client_secret: System.get_env("APPLE_CLIENT_SECRET")
      ]}
    ]

  # Import environment specific config. This must remain at the bottom
  # of this file so it overrides the configuration defined above.
  import_config "#{config_env()}.exs"
