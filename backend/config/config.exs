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



# Configure Joken for JWT tokens
config :joken, default_signer: "Kh7LIE0FWdaQ/ThYYCasCt7AUPeIPkfgOp0oPWAfUH7ig2y0ukEFTMIjofcXolgh"

# Configure Swoosh for email
# In dev/test, we use the Local adapter (no actual emails sent)
# In production, this is overridden to use the Finch API client
config :swoosh, :api_client, false

# Configure Swoosh mailer - defaults to Local adapter for dev/test
# Production uses AWS SES via runtime.exs configuration
config :buttonlog, ButtonLog.Mailer,
  adapter: Swoosh.Adapters.Local

# ExAws configuration for AWS services (SES email)
# AWS credentials are loaded from environment variables in runtime.exs
config :ex_aws,
  json_codec: Jason

# Do not print debug messages in production
config :logger, level: :info

# Runtime configuration
config :buttonlog, :env, config_env()

# Push notification configuration (APNs for iOS, FCM for Android)
# These will be loaded from environment variables in runtime.exs
config :buttonlog, :apns,
  topic: System.get_env("APNS_TOPIC", "com.buttonlog.app")

config :buttonlog, :fcm, []

# Stripe Configuration
# API keys are loaded from environment variables in runtime.exs
# Default values here are just placeholders; actual keys come from runtime config
config :stripity_stripe,
  api_key: "sk_test_placeholder"

# Stripe URLs (overridden in runtime.exs with actual host/port)
config :buttonlog,
  stripe_success_url: "http://localhost:14015/account?payment=success",
  stripe_cancel_url: "http://localhost:14015/account?payment=cancelled",
  stripe_return_url: "http://localhost:14015/account"

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
