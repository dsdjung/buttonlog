defmodule ButtonLog.Auth.Token do
  use Joken.Config

  def token_config do
    default_claims(
      iss: "buttonlog",
      aud: "buttonlog_users",
      default_ttl: {24, :hour}
    )
  end

  def create_token(user_id) do
    {:ok, token, _claims} = encode_and_sign(%{"user_id" => user_id})
    token
  end

  def verify_token(token) do
    case verify_and_validate(token) do
      {:ok, claims} -> {:ok, claims["user_id"]}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :invalid_token}
  end
end
