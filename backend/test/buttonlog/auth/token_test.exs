defmodule ButtonLog.Auth.TokenTest do
  use ButtonLog.DataCase

  alias ButtonLog.Auth.Token

  describe "token_config/0" do
    test "returns default claims configuration" do
      config = Token.token_config()
      assert is_list(config) or is_map(config)
    end
  end

  describe "create_token/1" do
    test "creates a valid JWT token for user_id" do
      user_id = Ecto.UUID.generate()
      token = Token.create_token(user_id)

      assert is_binary(token)
      assert String.length(token) > 0
      # JWT tokens have three parts separated by dots
      assert length(String.split(token, ".")) == 3
    end

    test "creates different tokens for different user_ids" do
      user_id1 = Ecto.UUID.generate()
      user_id2 = Ecto.UUID.generate()

      token1 = Token.create_token(user_id1)
      token2 = Token.create_token(user_id2)

      refute token1 == token2
    end

    test "creates consistent tokens for same user_id" do
      user_id = Ecto.UUID.generate()

      token1 = Token.create_token(user_id)
      token2 = Token.create_token(user_id)

      # Without timestamps, tokens for same user_id should be identical
      # This tests the actual implementation behavior
      assert token1 == token2
    end
  end

  describe "verify_token/1" do
    test "verifies a valid token and returns user_id" do
      user_id = Ecto.UUID.generate()
      token = Token.create_token(user_id)

      assert {:ok, returned_user_id} = Token.verify_token(token)
      assert returned_user_id == user_id
    end

    test "returns error for invalid token" do
      assert {:error, _reason} = Token.verify_token("invalid.token.here")
    end

    test "returns error for empty token" do
      assert {:error, _reason} = Token.verify_token("")
    end

    test "returns error for malformed token" do
      assert {:error, _reason} = Token.verify_token("not-a-jwt")
    end

    test "returns error for token with tampered payload" do
      user_id = Ecto.UUID.generate()
      token = Token.create_token(user_id)

      # Split the token and tamper with the payload
      [header, _payload, signature] = String.split(token, ".")
      tampered_token = "#{header}.tampered_payload.#{signature}"

      assert {:error, _reason} = Token.verify_token(tampered_token)
    end

    test "returns error for nil token" do
      assert {:error, _reason} = Token.verify_token(nil)
    end

    test "roundtrip: create and verify returns same user_id" do
      user_id = Ecto.UUID.generate()

      token = Token.create_token(user_id)
      {:ok, verified_user_id} = Token.verify_token(token)

      assert verified_user_id == user_id
    end

    test "works with integer user_id" do
      user_id = 12345
      token = Token.create_token(user_id)

      assert {:ok, returned_user_id} = Token.verify_token(token)
      assert returned_user_id == user_id
    end

    test "works with string user_id" do
      user_id = "user_123"
      token = Token.create_token(user_id)

      assert {:ok, returned_user_id} = Token.verify_token(token)
      assert returned_user_id == user_id
    end
  end

  describe "token structure" do
    test "token contains user_id in claims" do
      user_id = Ecto.UUID.generate()
      token = Token.create_token(user_id)

      # Decode the payload (middle part of JWT)
      [_header, payload, _signature] = String.split(token, ".")
      decoded_payload = Base.url_decode64!(payload, padding: false)
      claims = Jason.decode!(decoded_payload)

      # Verify user_id is in the claims
      assert claims["user_id"] == user_id
    end

    test "token header specifies HS256 algorithm" do
      user_id = Ecto.UUID.generate()
      token = Token.create_token(user_id)

      # Decode the header (first part of JWT)
      [header, _payload, _signature] = String.split(token, ".")
      decoded_header = Base.url_decode64!(header, padding: false)
      header_claims = Jason.decode!(decoded_header)

      assert header_claims["alg"] == "HS256"
      assert header_claims["typ"] == "JWT"
    end
  end
end
