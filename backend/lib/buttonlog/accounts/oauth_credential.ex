defmodule ButtonLog.Accounts.OAuthCredential do
  @moduledoc """
  Schema for storing OAuth credentials.
  Supports multiple OAuth providers per user (e.g., Google + Facebook + Apple).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_providers ["google", "facebook", "apple", "github"]

  schema "oauth_credentials" do
    field :provider, :string
    field :provider_uid, :string
    field :provider_token, :string
    field :provider_refresh_token, :string
    field :provider_expires_at, :utc_datetime

    belongs_to :user, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id, :provider, :provider_uid, :provider_token, :provider_refresh_token, :provider_expires_at])
    |> validate_required([:user_id, :provider, :provider_uid])
    |> validate_inclusion(:provider, @valid_providers)
    |> unique_constraint([:user_id, :provider], name: :oauth_credentials_user_id_provider_index)
    |> unique_constraint([:provider, :provider_uid], name: :oauth_credentials_provider_provider_uid_index)
  end

  def valid_providers, do: @valid_providers
end
