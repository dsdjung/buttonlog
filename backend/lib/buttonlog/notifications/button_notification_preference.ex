defmodule ButtonLog.Notifications.ButtonNotificationPreference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "button_notification_preferences" do
    field :enabled, :boolean, default: true
    field :notification_type, :string, default: "click"

    # Relationships
    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [:enabled, :notification_type])
    |> validate_required([:enabled, :notification_type])
    |> validate_inclusion(:notification_type, ["click", "start", "end", "all"])
    |> unique_constraint([:button_id, :user_id, :friend_id],
                        name: :button_notification_preferences_unique)
  end

  def create_changeset(preference, attrs, button_id, user_id, friend_id) do
    preference
    |> changeset(attrs)
    |> put_change(:button_id, button_id)
    |> put_change(:user_id, user_id)
    |> put_change(:friend_id, friend_id)
  end
end

