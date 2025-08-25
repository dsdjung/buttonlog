defmodule ButtonLog.Repo.Migrations.AddActionToButtonClicks do
  use Ecto.Migration

  def change do
    alter table(:button_clicks) do
      add :action, :string, default: "click"
    end

    # Add index for querying by action type
    create index(:button_clicks, [:action])
  end
end
