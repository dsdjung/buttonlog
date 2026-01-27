defmodule ButtonLog.Repo.Migrations.AddTosAcceptedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tos_accepted_at, :naive_datetime
    end
  end
end
