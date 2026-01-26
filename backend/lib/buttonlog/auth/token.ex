defmodule ButtonLog.Auth.Token do
  @moduledoc """
  JWT token management for API authentication.

  Supports token creation, verification, and revocation.
  """
  use Joken.Config
  alias ButtonLog.Auth.TokenBlacklist

  def token_config do
    default_claims(
      iss: "buttonlog",
      aud: "buttonlog_users",
      default_ttl: {24, :hour}
    )
  end

  @doc """
  Creates a new JWT token for the given user ID.
  """
  def create_token(user_id) do
    {:ok, token, _claims} = encode_and_sign(%{"user_id" => user_id})
    token
  end

  @doc """
  Verifies a token and returns the user ID if valid.

  Checks both the token signature and whether it has been revoked.
  """
  def verify_token(token) do
    with {:ok, claims} <- verify_and_validate(token),
         false <- TokenBlacklist.revoked?(token) do
      {:ok, claims["user_id"]}
    else
      true -> {:error, :token_revoked}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  @doc """
  Revokes a token, making it invalid for future use.

  Used for logout functionality.
  """
  def revoke_token(token) do
    TokenBlacklist.revoke(token)
  end

  @doc """
  Revokes all tokens for a user.

  Used when a user changes their password or for security reasons.
  """
  def revoke_all_user_tokens(user_id) do
    TokenBlacklist.revoke_all_for_user(user_id)
  end
end
