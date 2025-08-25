defmodule ButtonLog.Buttons.ButtonClick do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "button_clicks" do
    field :clicked_at, :utc_datetime
    field :duration, :integer
    field :location_lat, :decimal
    field :location_lng, :decimal
    field :device, :string
    field :platform, :string
    field :action, :string

    # Relationships
    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :user, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(button_click, attrs) do
    button_click
    |> cast(attrs, [:clicked_at, :duration, :location_lat, :location_lng, :device, :platform, :action])
    |> validate_required([:device, :platform])
    |> validate_inclusion(:platform, ["web", "android", "iphone"])
    |> validate_inclusion(:action, ["click", "start", "end"], allow_blank: true)
    |> validate_number(:duration, greater_than: 0)
    |> validate_number(:location_lat, greater_than: -90, less_than: 90)
    |> validate_number(:location_lng, greater_than: -180, less_than: 180)
  end

  def create_changeset(button_click, attrs, button_id, user_id) do
    button_click
    |> changeset(attrs)
    |> put_change(:button_id, button_id)
    |> put_change(:user_id, user_id)
    |> put_change(:clicked_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_required([:button_id, :user_id, :clicked_at])
  end
end

