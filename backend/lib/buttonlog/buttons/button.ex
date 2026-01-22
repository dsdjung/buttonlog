defmodule ButtonLog.Buttons.Button do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "buttons" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :icon, :string
    field :color, :string
    field :is_active, :boolean
    field :current_state, :string
    field :state_changed_at, :utc_datetime

    # Settings
    field :alerts_enabled, :boolean
    field :auto_stop_enabled, :boolean
    field :auto_stop_minutes, :integer  # Duration in minutes (15, 30, 60, 120, 240, 480)
    field :scheduled_stop_at, :utc_datetime  # When the button should auto-stop
    field :calendar_sync_enabled, :boolean

    # Archival (for one-time buttons)
    field :archived, :boolean, default: false
    field :archived_at, :utc_datetime

    # Multiple choice options (for one-time buttons)
    field :choices, {:array, :string}

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :created_by_friend, ButtonLog.Accounts.User
    has_many :button_clicks, ButtonLog.Buttons.ButtonClick
    has_many :collaborators, ButtonLog.Buttons.ButtonCollaborator

    # Gift button fields
    field :gift_message, :string

    # Sharing fields
    field :sharing_mode, :string, default: "private"
    field :share_token, :string
    field :share_token_expires_at, :utc_datetime

    timestamps()
  end

  def changeset(button, attrs) do
    button
    |> cast(attrs, [:name, :description, :type, :icon, :color, :is_active,
                    :alerts_enabled, :auto_stop_enabled, :auto_stop_minutes,
                    :scheduled_stop_at, :calendar_sync_enabled,
                    :current_state, :state_changed_at, :user_id, :archived, :archived_at,
                    :choices])
    |> validate_required([:name, :type])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_inclusion(:type, ["instant", "toggle", "one-time", "workflow"])
    |> validate_inclusion(:current_state, ["idle", "active"], allow_blank: true)
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color")
    |> validate_auto_stop_minutes()
    |> validate_choices()
  end

  defp validate_auto_stop_minutes(changeset) do
    case get_change(changeset, :auto_stop_minutes) do
      nil -> changeset
      minutes when minutes in [15, 30, 60, 120, 240, 480] -> changeset
      _ -> add_error(changeset, :auto_stop_minutes, "must be 15, 30, 60, 120, 240, or 480 minutes")
    end
  end

  defp validate_choices(changeset) do
    type = get_field(changeset, :type)
    choices = get_change(changeset, :choices)

    cond do
      # No choices provided - OK
      is_nil(choices) ->
        changeset

      # Choices can only be set for one-time buttons
      choices != nil and type != "one-time" ->
        add_error(changeset, :choices, "can only be set for one-time buttons")

      # If choices exist, must have at least 2 options
      is_list(choices) and length(choices) < 2 ->
        add_error(changeset, :choices, "must have at least 2 options")

      # Limit to reasonable number of choices
      is_list(choices) and length(choices) > 10 ->
        add_error(changeset, :choices, "cannot exceed 10 options")

      # Choices must not be empty strings
      is_list(choices) and Enum.any?(choices, &(String.trim(&1) == "")) ->
        add_error(changeset, :choices, "cannot contain empty options")

      true ->
        changeset
    end
  end

  def create_changeset(button, attrs, user_id) do
    button
    |> changeset(attrs)
    |> put_change(:user_id, user_id)
    |> put_change(:is_active, true)
    |> put_change(:current_state, "idle")
    |> put_change(:alerts_enabled, true)
    |> put_change(:auto_stop_enabled, false)
    |> put_change(:calendar_sync_enabled, false)
  end

  @doc """
  Creates a changeset for a gift button (created by a friend for the user).
  """
  def create_gift_changeset(button, attrs, owner_id, gifter_id, message) do
    button
    |> create_changeset(attrs, owner_id)
    |> put_change(:created_by_friend_id, gifter_id)
    |> put_change(:gift_message, message)
  end

  @doc """
  Creates a changeset for updating button sharing settings.
  """
  def sharing_changeset(button, attrs) do
    button
    |> cast(attrs, [:sharing_mode, :share_token, :share_token_expires_at])
    |> validate_inclusion(:sharing_mode, ["private", "friends", "invite_only", "public"])
  end
end
