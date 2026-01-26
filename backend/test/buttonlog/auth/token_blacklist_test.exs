defmodule ButtonLog.Auth.TokenBlacklistTest do
  use ExUnit.Case, async: false
  alias ButtonLog.Auth.{Token, TokenBlacklist}

  setup do
    # Ensure the TokenBlacklist is started for tests
    case GenServer.whereis(TokenBlacklist) do
      nil ->
        {:ok, _pid} = TokenBlacklist.start_link([])
        :ok

      _pid ->
        # Clear the ETS table for a clean test state
        :ets.delete_all_objects(:token_blacklist)
        :ok
    end
  end

  describe "revoke/1" do
    test "revokes a valid token" do
      token = Token.create_token("user-123")
      assert :ok = TokenBlacklist.revoke(token)
    end

    test "returns error for invalid token" do
      assert {:error, _reason} = TokenBlacklist.revoke("invalid-token")
    end
  end

  describe "revoked?/1" do
    test "returns false for non-revoked token" do
      token = Token.create_token("user-123")
      refute TokenBlacklist.revoked?(token)
    end

    test "returns true for revoked token" do
      token = Token.create_token("user-123")
      TokenBlacklist.revoke(token)
      assert TokenBlacklist.revoked?(token)
    end

    test "returns false for invalid token" do
      refute TokenBlacklist.revoked?("invalid-token")
    end
  end

  describe "revoke_all_for_user/1" do
    test "revokes all tokens for a user" do
      user_id = "user-456"
      assert :ok = TokenBlacklist.revoke_all_for_user(user_id)
    end
  end

  describe "token verification with blacklist" do
    test "valid token passes verification" do
      token = Token.create_token("user-789")
      assert {:ok, "user-789"} = Token.verify_token(token)
    end

    test "revoked token fails verification" do
      token = Token.create_token("user-789")
      Token.revoke_token(token)
      assert {:error, :token_revoked} = Token.verify_token(token)
    end
  end
end
