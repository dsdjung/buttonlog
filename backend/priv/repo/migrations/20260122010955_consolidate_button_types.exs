defmodule ButtonLog.Repo.Migrations.ConsolidateButtonTypes do
  use Ecto.Migration

  @doc """
  Consolidates button types:
  - "timed" -> "toggle"
  - "state" -> "toggle"
  - Adds "workflow" as new type

  New types: instant, toggle, one-time, workflow
  """

  def up do
    # First, drop the old constraint to allow data migration
    execute "ALTER TABLE buttons DROP CONSTRAINT IF EXISTS buttons_type_check"

    # Migrate existing "timed" and "state" buttons to "toggle"
    execute "UPDATE buttons SET type = 'toggle' WHERE type IN ('timed', 'state')"

    # Add new constraint with updated types
    execute """
    ALTER TABLE buttons
    ADD CONSTRAINT buttons_type_check
    CHECK (type IN ('instant', 'toggle', 'one-time', 'workflow'))
    """
  end

  def down do
    # Drop the new constraint
    execute "ALTER TABLE buttons DROP CONSTRAINT IF EXISTS buttons_type_check"

    # Restore old constraint (note: can't un-migrate toggle back to timed/state)
    execute """
    ALTER TABLE buttons
    ADD CONSTRAINT buttons_type_check
    CHECK (type IN ('instant', 'timed', 'state', 'one-time'))
    """
  end
end
