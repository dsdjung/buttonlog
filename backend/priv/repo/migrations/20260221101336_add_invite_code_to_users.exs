defmodule ButtonLog.Repo.Migrations.AddInviteCodeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :invite_code, :string
    end

    # Create unique index for invite codes
    create unique_index(:users, [:invite_code])
  end
end
