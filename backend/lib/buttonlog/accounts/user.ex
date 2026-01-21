defmodule ButtonLog.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :display_name, :string
    field :avatar, :string
    field :timezone, :string
    field :language, :string

    # OAuth provider information
    field :provider, :string
    field :provider_uid, :string
    field :provider_token, :string
    field :provider_refresh_token, :string
    field :provider_expires_at, :utc_datetime

    # Email verification status
    field :email_verified, :boolean, default: false

    # Subscription info
    field :subscription_tier, :string
    field :subscription_expires_at, :utc_datetime

    # Privacy settings
    field :default_history_sharing, :boolean
    field :allow_friend_requests, :boolean
    field :profile_visibility, :string
    field :activity_visibility, :string

    # Virtual fields for password handling
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    # Relationships
    has_many :buttons, ButtonLog.Buttons.Button
    has_many :button_clicks, ButtonLog.Buttons.ButtonClick
    has_many :friendships, ButtonLog.Social.Friendship
    has_many :friend_permissions, ButtonLog.Social.FriendPermission
    has_many :notifications, ButtonLog.Notifications.Notification, foreign_key: :recipient_id
    has_many :mobile_connections, ButtonLog.Mobile.Connection

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :display_name, :avatar, :timezone, :language,
                    :provider, :provider_uid, :provider_token, :provider_refresh_token, :provider_expires_at,
                    :email_verified, :subscription_tier, :subscription_expires_at, :default_history_sharing,
                    :allow_friend_requests, :profile_visibility, :activity_visibility])
    |> validate_required([:username, :display_name])
    |> validate_required([:email], message: "Email is required")
    |> validate_format(:email, ~r/@/)
    |> validate_length(:username, min: 3, max: 30)
    |> validate_length(:display_name, min: 1, max: 100)
    |> validate_inclusion(:profile_visibility, ["public", "friends", "private"])
    |> validate_inclusion(:activity_visibility, ["public", "friends", "private"])
    |> validate_inclusion(:subscription_tier, ["free", "premium", "enterprise"])
    |> unique_constraint(:username)
    |> validate_oauth_constraints()
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_password_for_local_users()
    |> put_password_hash()
  end

  def oauth_registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> put_change(:email_verified, true)
  end

  def update_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> maybe_put_password_hash(attrs)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp maybe_put_password_hash(changeset, %{password: _password} = attrs) do
    changeset
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> put_password_hash()
  end

  defp maybe_put_password_hash(changeset, _attrs), do: changeset

  # OAuth validation helpers
  defp validate_oauth_constraints(changeset) do
    case get_field(changeset, :provider) do
      nil ->
        # Local user - no OAuth constraints
        changeset
      provider when provider in ["google", "facebook", "github", "apple"] ->
        # OAuth user - validate provider_uid is present
        validate_required(changeset, [:provider_uid])
      _ ->
        add_error(changeset, :provider, "Invalid OAuth provider")
    end
  end

  defp validate_password_for_local_users(changeset) do
    case get_field(changeset, :provider) do
      nil ->
        # Local user - password is required
        changeset
        |> validate_required([:password, :password_confirmation])
        |> validate_length(:password, min: 8)
        |> validate_confirmation(:password)
      _ ->
        # OAuth user - password not required
        changeset
    end
  end
end
