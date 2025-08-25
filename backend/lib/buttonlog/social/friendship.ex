defmodule ButtonLog.Social.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "friendships" do
    field :status, :string

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:status, :user_id, :friend_id])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["pending", "accepted", "blocked"])
    |> unique_constraint([:user_id, :friend_id], name: :friendships_user_friend_index)
    |> check_constraint(:friend_id, name: :friendships_cannot_friend_self,
                       message: "Cannot friend yourself")
  end

  def create_changeset(friendship, attrs, user_id, friend_id) do
    friendship
    |> cast(attrs, [:status])
    |> put_change(:user_id, user_id)
    |> put_change(:friend_id, friend_id)
    |> put_change(:status, "pending")
    |> validate_required([:user_id, :friend_id, :status])
    |> validate_inclusion(:status, ["pending", "accepted", "blocked"])
    |> unique_constraint([:user_id, :friend_id], name: :friendships_user_friend_index)
    |> check_constraint(:friend_id, name: :friendships_cannot_friend_self,
                       message: "Cannot friend yourself")
  end
end
