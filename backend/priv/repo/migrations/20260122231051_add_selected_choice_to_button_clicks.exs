defmodule ButtonLog.Repo.Migrations.AddSelectedChoiceToButtonClicks do
  use Ecto.Migration

  def change do
    alter table(:button_clicks) do
      # The choice selected when clicking a button with multiple choices
      add :selected_choice, :string, default: nil
    end
  end
end
