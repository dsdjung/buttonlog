defmodule ButtonLog.Repo.Migrations.UpdateButtonsTypeConstraint do
  use Ecto.Migration

  def change do
    # Drop the old constraint
    drop constraint(:buttons, :buttons_type_check)

    # Create new constraint with one-time type
    create constraint(:buttons, :buttons_type_check,
      check: "type IN ('instant', 'timed', 'state', 'one-time')")
  end
end
