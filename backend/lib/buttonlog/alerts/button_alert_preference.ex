defmodule ButtonLog.Alerts.ButtonAlertPreference do
  @moduledoc """
  Schema for button-specific alert preferences.
  Determines which friends receive alerts when a button is clicked.
  This replaces the old ButtonNotificationPreference schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "button_alert_preferences" do
    field :enabled, :boolean, default: true
    field :alert_type, :string, default: "click"

    # Relationships
    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [:enabled, :alert_type])
    |> validate_required([:enabled, :alert_type])
    |> validate_inclusion(:alert_type, ["click", "start", "end", "all"])
    |> unique_constraint([:button_id, :user_id, :friend_id],
      name: :button_alert_preferences_unique)
  end

  def create_changeset(preference, attrs, button_id, user_id, friend_id) do
    preference
    |> changeset(attrs)
    |> put_change(:button_id, button_id)
    |> put_change(:user_id, user_id)
    |> put_change(:friend_id, friend_id)
  end
end
