defmodule ButtonLog.Repo do
  use Ecto.Repo,
    otp_app: :buttonlog,
    adapter: Ecto.Adapters.Postgres
end
