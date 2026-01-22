defmodule ButtonLogWeb.API.StripeWebhookController do
  @moduledoc """
  Controller for handling Stripe webhook events.

  Verifies webhook signatures and delegates to the webhook handler.
  """
  use ButtonLogWeb, :controller

  require Logger

  alias ButtonLog.Subscriptions.StripeWebhookHandler

  @doc """
  Handles incoming Stripe webhook events.
  """
  def handle(conn, _params) do
    with {:ok, payload} <- get_raw_body(conn),
         {:ok, event} <- verify_webhook(payload, conn) do

      case StripeWebhookHandler.handle_event(event) do
        :ok ->
          json(conn, %{received: true})

        {:error, reason} ->
          Logger.error("Webhook handler error: #{inspect(reason)}")
          json(conn, %{received: true, warning: "Event processed with errors"})
      end
    else
      {:error, :missing_signature} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing Stripe signature"})

      {:error, :invalid_signature} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid signature"})

      {:error, reason} ->
        Logger.error("Webhook verification failed: #{inspect(reason)}")
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Webhook verification failed"})
    end
  end

  defp get_raw_body(conn) do
    # The raw body should be cached by a plug
    case conn.assigns[:raw_body] do
      nil ->
        # Fallback: read from conn
        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        {:ok, body}

      body ->
        {:ok, body}
    end
  end

  defp verify_webhook(payload, conn) do
    signature = get_req_header(conn, "stripe-signature") |> List.first()
    webhook_secret = get_webhook_secret()

    cond do
      is_nil(signature) ->
        {:error, :missing_signature}

      is_nil(webhook_secret) or webhook_secret == "" ->
        # In development without webhook secret, parse without verification
        if Application.get_env(:buttonlog, :env) == :dev do
          Logger.warning("Stripe webhook secret not configured - skipping signature verification")
          case Jason.decode(payload) do
            {:ok, event_map} ->
              {:ok, struct_from_map(event_map)}
            error ->
              error
          end
        else
          {:error, :webhook_secret_not_configured}
        end

      true ->
        case Stripe.Webhook.construct_event(payload, signature, webhook_secret) do
          {:ok, event} -> {:ok, event}
          {:error, _} -> {:error, :invalid_signature}
        end
    end
  end

  defp get_webhook_secret do
    Application.get_env(:stripity_stripe, :webhook_secret)
  end

  # Convert map to a struct-like map for event handling
  defp struct_from_map(map) do
    %{
      id: map["id"],
      type: map["type"],
      data: %{
        object: atomize_keys(map["data"]["object"])
      }
    }
  end

  defp atomize_keys(nil), do: nil
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) ->
        {String.to_atom(key), atomize_keys(value)}
      {key, value} ->
        {key, atomize_keys(value)}
    end)
  end
  defp atomize_keys(list) when is_list(list), do: Enum.map(list, &atomize_keys/1)
  defp atomize_keys(value), do: value
end
