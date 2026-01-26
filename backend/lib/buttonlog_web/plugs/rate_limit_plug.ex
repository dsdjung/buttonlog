defmodule ButtonLogWeb.Plugs.RateLimitPlug do
  @moduledoc """
  Rate limiting plug to protect against brute force attacks and API abuse.

  ## Configuration

  This plug can be configured with the following options:

    * `:scale_ms` - Time window in milliseconds (default: 60_000 = 1 minute)
    * `:limit` - Number of allowed requests in the time window (default: 60)
    * `:bucket_prefix` - Prefix for the rate limit bucket key (default: "rate_limit")

  ## Usage in Router

      plug ButtonLogWeb.Plugs.RateLimitPlug, scale_ms: 60_000, limit: 5
  """

  import Plug.Conn
  require Logger

  @default_scale_ms 60_000  # 1 minute
  @default_limit 60         # 60 requests per minute

  def init(opts) do
    %{
      scale_ms: Keyword.get(opts, :scale_ms, @default_scale_ms),
      limit: Keyword.get(opts, :limit, @default_limit),
      bucket_prefix: Keyword.get(opts, :bucket_prefix, "rate_limit")
    }
  end

  def call(conn, opts) do
    # Skip rate limiting in test environment
    # Also skip for localhost in dev mode (for integration testing)
    cond do
      Application.get_env(:buttonlog, :env) == :test ->
        conn
      Application.get_env(:buttonlog, :env) == :dev && is_localhost?(conn) ->
        conn
      true ->
        check_rate_limit(conn, opts)
    end
  end

  defp is_localhost?(conn) do
    ip = get_client_ip(conn)
    ip in ["127.0.0.1", "::1", "localhost"]
  end

  defp check_rate_limit(conn, opts) do
    bucket_key = get_bucket_key(conn, opts.bucket_prefix)

    case Hammer.check_rate(bucket_key, opts.scale_ms, opts.limit) do
      {:allow, count} ->
        conn
        |> put_resp_header("x-ratelimit-limit", Integer.to_string(opts.limit))
        |> put_resp_header("x-ratelimit-remaining", Integer.to_string(max(opts.limit - count, 0)))
        |> put_resp_header("x-ratelimit-reset", get_reset_time(opts.scale_ms))

      {:deny, _limit} ->
        Logger.warning("Rate limit exceeded for #{bucket_key}")

        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("x-ratelimit-limit", Integer.to_string(opts.limit))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> put_resp_header("x-ratelimit-reset", get_reset_time(opts.scale_ms))
        |> put_resp_header("retry-after", Integer.to_string(div(opts.scale_ms, 1000)))
        |> send_resp(429, Jason.encode!(%{
          success: false,
          error: %{
            code: "RATE_LIMIT_EXCEEDED",
            message: "Too many requests. Please try again later.",
            retry_after: div(opts.scale_ms, 1000)
          }
        }))
        |> halt()
    end
  end

  defp get_bucket_key(conn, prefix) do
    # Use IP address as the identifier
    ip = get_client_ip(conn)
    path = conn.request_path
    "#{prefix}:#{ip}:#{path}"
  end

  defp get_client_ip(conn) do
    # Check for forwarded IP (when behind a proxy/load balancer)
    forwarded_for = get_req_header(conn, "x-forwarded-for")

    case forwarded_for do
      [ip_list | _] ->
        ip_list
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end

  defp get_reset_time(scale_ms) do
    reset_at = System.system_time(:second) + div(scale_ms, 1000)
    Integer.to_string(reset_at)
  end
end
