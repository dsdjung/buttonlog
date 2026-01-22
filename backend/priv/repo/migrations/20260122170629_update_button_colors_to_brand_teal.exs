defmodule ButtonLog.Repo.Migrations.UpdateButtonColorsToBrandTeal do
  use Ecto.Migration

  def up do
    # Update all buttons with the old blue color to the new brand teal
    execute """
    UPDATE buttons
    SET color = '#00BFA5'
    WHERE color = '#007AFF'
    """
  end

  def down do
    # Revert back to old blue color
    execute """
    UPDATE buttons
    SET color = '#007AFF'
    WHERE color = '#00BFA5'
    """
  end
end
