import Config

# Configure your database
config :buttonlog, ButtonLog.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "buttonlog_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :buttonlog, ButtonLogWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4102],
  secret_key_base: "test-secret-key-base-here",
  server: false

# In test we don't send emails.
config :buttonlog, ButtonLog.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
