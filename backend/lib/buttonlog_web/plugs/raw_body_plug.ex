defmodule ButtonLogWeb.Plugs.RawBodyPlug do
  @moduledoc """
  Plug to cache the raw request body for webhook signature verification.

  This is needed because Stripe webhook verification requires access to
  the raw, unparsed request body to verify the signature.
  """

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        conn
        |> Plug.Conn.assign(:raw_body, body)
        |> Plug.Conn.put_private(:raw_body, body)

      {:more, _partial, conn} ->
        conn

      {:error, _reason} ->
        conn
    end
  end
end
