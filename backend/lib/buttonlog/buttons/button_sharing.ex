defmodule ButtonLog.Buttons.ButtonSharing do
  @moduledoc """
  Schema for per-button sharing controls.

  This allows users to control which friends can see specific buttons.
  By default, all buttons are shared with all friends (if friend-level
  can_view_buttons permission is granted). Users can then exclude
  specific buttons from specific friends.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "button_sharing" do
    field :is_shared, :boolean, default: true

    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User

    timestamps()
  end

  @doc """
  Creates a changeset for button sharing.
  """
  def changeset(button_sharing, attrs) do
    button_sharing
    |> cast(attrs, [:button_id, :user_id, :friend_id, :is_shared])
    |> validate_required([:button_id, :user_id, :friend_id])
    |> unique_constraint([:button_id, :friend_id], name: :button_sharing_button_friend_index)
    |> foreign_key_constraint(:button_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:friend_id)
  end
end
