defmodule ButtonLog.Mobile.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mobile_connections" do
    field :device_token, :string
    field :platform, :string
    field :app_version, :string
    field :os_version, :string
    field :is_active, :boolean
    field :last_seen_at, :utc_datetime

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:device_token, :platform, :app_version, :os_version, :is_active, :last_seen_at])
    |> validate_inclusion(:platform, ["android", "iphone"])
    |> unique_constraint(:device_token)
  end

  def create_changeset(connection, attrs, user_id) do
    connection
    |> cast(attrs, [:device_token, :platform, :app_version, :os_version, :is_active, :last_seen_at])
    |> put_change(:user_id, user_id)
    |> put_change(:is_active, true)
    |> put_change(:last_seen_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_required([:device_token, :platform, :user_id])
    |> validate_inclusion(:platform, ["android", "iphone"])
    |> unique_constraint(:device_token)
  end

  def update_last_seen_changeset(connection) do
    connection
    |> change(%{last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end
end


