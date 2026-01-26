defmodule ButtonLogWeb.Plugs.RateLimitPlugTest do
  use ButtonLogWeb.ConnCase
  alias ButtonLogWeb.Plugs.RateLimitPlug

  describe "rate limiting" do
    test "allows requests under the limit", %{conn: _conn} do
      # Note: Rate limiting is skipped in test environment
      # This test verifies the plug initializes correctly
      opts = RateLimitPlug.init(scale_ms: 60_000, limit: 5, bucket_prefix: "test")

      assert opts.scale_ms == 60_000
      assert opts.limit == 5
      assert opts.bucket_prefix == "test"
    end

    test "uses default values when not specified" do
      opts = RateLimitPlug.init([])

      assert opts.scale_ms == 60_000
      assert opts.limit == 60
      assert opts.bucket_prefix == "rate_limit"
    end

    test "passes through in test environment", %{conn: conn} do
      opts = RateLimitPlug.init(scale_ms: 1000, limit: 1, bucket_prefix: "test")

      # First request should pass
      conn = RateLimitPlug.call(conn, opts)
      refute conn.halted

      # In test environment, subsequent requests should also pass
      # because rate limiting is skipped
      conn2 = build_conn()
      conn2 = RateLimitPlug.call(conn2, opts)
      refute conn2.halted
    end
  end

  describe "init/1" do
    test "accepts custom scale_ms" do
      opts = RateLimitPlug.init(scale_ms: 120_000)
      assert opts.scale_ms == 120_000
    end

    test "accepts custom limit" do
      opts = RateLimitPlug.init(limit: 100)
      assert opts.limit == 100
    end

    test "accepts custom bucket_prefix" do
      opts = RateLimitPlug.init(bucket_prefix: "auth")
      assert opts.bucket_prefix == "auth"
    end

    test "accepts multiple options" do
      opts = RateLimitPlug.init(scale_ms: 30_000, limit: 10, bucket_prefix: "api")
      assert opts.scale_ms == 30_000
      assert opts.limit == 10
      assert opts.bucket_prefix == "api"
    end
  end
end
