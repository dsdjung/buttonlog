import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in this file, as it won't be applied.

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :buttonlog, ButtonLog.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :buttonlog, ButtonLogWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for forcing IPv6 only.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :buttonlog, ButtonLogWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SSL_KEYFILE"),
  #         certfile: System.get_env("SSL_CERTFILE")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This ensures old browsers
  # and clients are unable to connect to newer Phoenix applications.
  # For more information, see https://www.owasp.org/index.php/SSL/TLS_Implementation_Cheat_Sheet#Rule_-_Only_Support_Strong_Encryption_Ciphers
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :buttonlog, ButtonLogWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :buttonlog, ButtonLog.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For more information, see the Swoosh documentation for your chosen adapter.
  #
  # config :buttonlog, ButtonLog.Mailer,
  #   adapter: Swoosh.Adapters.SendGrid,
  #   api_key: System.get_env("SENDGRID_API_KEY")
end

# Push notification configuration (all environments)
# FCM (Firebase Cloud Messaging) for Android
if fcm_project_id = System.get_env("FCM_PROJECT_ID") do
  config :buttonlog, :fcm,
    project_id: fcm_project_id,
    service_account_json: System.get_env("FCM_SERVICE_ACCOUNT_JSON")
end

# APNs (Apple Push Notification Service) for iOS
if apns_key_id = System.get_env("APNS_KEY_ID") do
  # Support both APNS_KEY_PATH (file path) and APNS_KEY_CONTENT (inline PEM)
  key_path =
    cond do
      key_content = System.get_env("APNS_KEY_CONTENT") ->
        # Inline key content (replace literal \n with actual newlines)
        String.replace(key_content, "\\n", "\n")

      key_path = System.get_env("APNS_KEY_PATH") ->
        key_path

      true ->
        nil
    end

  environment =
    case System.get_env("APNS_ENVIRONMENT", "sandbox") do
      "production" -> :production
      _ -> :sandbox
    end

  config :buttonlog, :apns,
    key_id: apns_key_id,
    team_id: System.get_env("APNS_TEAM_ID"),
    key_path: key_path,
    topic: System.get_env("APNS_BUNDLE_ID", "com.buttonlog.app"),
    environment: environment
end
