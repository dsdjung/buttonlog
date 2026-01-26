defmodule ButtonLog.Auth.TokenBlacklist do
  @moduledoc """
  Manages revoked JWT tokens using ETS for fast lookup.

  Tokens are stored with their expiration time and automatically
  cleaned up periodically to prevent memory growth.
  """
  use GenServer
  require Logger

  @table_name :token_blacklist
  @cleanup_interval :timer.minutes(15)

  # Client API

  @doc """
  Starts the token blacklist GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Revokes a token by adding it to the blacklist.

  The token is stored with its JTI (JWT ID) and expiration time.
  Once the token's natural expiration passes, it will be cleaned up.
  """
  def revoke(token) when is_binary(token) do
    case extract_token_info(token) do
      {:ok, jti, exp} ->
        :ets.insert(@table_name, {jti, exp})
        :ok

      {:error, reason} ->
        Logger.warning("Failed to revoke token: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Checks if a token has been revoked.

  Returns true if the token is in the blacklist and hasn't expired,
  false otherwise.
  """
  def revoked?(token) when is_binary(token) do
    case extract_jti(token) do
      {:ok, jti} ->
        case :ets.lookup(@table_name, jti) do
          [{^jti, _exp}] -> true
          [] -> false
        end

      {:error, _reason} ->
        false
    end
  end

  @doc """
  Revokes all tokens for a specific user by storing their user_id.

  This is useful when a user changes their password or when an
  admin needs to force logout all sessions for a user.
  """
  def revoke_all_for_user(user_id) when is_binary(user_id) do
    # Store user revocation with a far-future expiration (24 hours from now)
    # All tokens issued before this time for this user will be invalid
    exp = System.system_time(:second) + 86400
    :ets.insert(@table_name, {"user:#{user_id}", exp})
    :ok
  end

  @doc """
  Checks if all tokens for a user have been revoked.
  """
  def user_tokens_revoked?(user_id, issued_at) when is_binary(user_id) do
    case :ets.lookup(@table_name, "user:#{user_id}") do
      [{"user:" <> ^user_id, revoked_at}] ->
        # Token is invalid if it was issued before the revocation
        issued_at < revoked_at

      [] ->
        false
    end
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for storing revoked tokens
    :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])

    # Schedule periodic cleanup
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_tokens()
    schedule_cleanup()
    {:noreply, state}
  end

  # Private functions

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_expired_tokens do
    now = System.system_time(:second)
    # Delete all entries where the expiration time has passed
    match_spec = [{{:"$1", :"$2"}, [{:<, :"$2", now}], [true]}]
    count = :ets.select_delete(@table_name, match_spec)

    if count > 0 do
      Logger.debug("Cleaned up #{count} expired tokens from blacklist")
    end
  end

  defp extract_token_info(token) do
    case Joken.peek_claims(token) do
      {:ok, claims} ->
        jti = claims["jti"] || hash_token(token)
        exp = claims["exp"] || System.system_time(:second) + 86400
        {:ok, jti, exp}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_jti(token) do
    case Joken.peek_claims(token) do
      {:ok, claims} ->
        jti = claims["jti"] || hash_token(token)
        {:ok, jti}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fallback for tokens without JTI - use a hash of the token
  defp hash_token(token) do
    :crypto.hash(:sha256, token)
    |> Base.encode16(case: :lower)
    |> String.slice(0, 32)
  end
end
