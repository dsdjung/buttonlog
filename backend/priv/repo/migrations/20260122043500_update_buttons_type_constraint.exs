defmodule ButtonLog.Repo.Migrations.UpdateButtonsTypeConstraint do
  use Ecto.Migration

  def change do
    # Drop the old constraint
    drop constraint(:buttons, :buttons_type_check)

    # Create new constraint with consolidated types (toggle replaces timed/state, workflow added)
    create constraint(:buttons, :buttons_type_check,
      check: "type IN ('instant', 'toggle', 'one-time', 'workflow')")
  end
end
