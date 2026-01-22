defmodule ButtonLogWeb.API.WebhookNotificationController do
  @moduledoc """
  API controller for managing webhook notification settings.
  This is the new notification system for external integrations (webhooks).
  """

  use ButtonLogWeb, :controller
  alias ButtonLog.NotificationsWebhook

  @doc """
  Get account-level notification settings.
  GET /api/notifications/settings
  """
  def show_settings(conn, _params) do
    user = conn.assigns.current_user

    case NotificationsWebhook.get_or_create_user_settings(user.id) do
      {:ok, settings} ->
        conn
        |> json(%{
          success: true,
          data: format_user_settings(settings)
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "SETTINGS_ERROR",
            message: format_changeset_errors(changeset)
          }
        })
    end
  end

  @doc """
  Update account-level notification settings.
  PUT /api/notifications/settings
  """
  def update_settings(conn, params) do
    user = conn.assigns.current_user

    attrs = %{
      default_webhook_url: params["default_webhook_url"],
      default_webhook_enabled: params["default_webhook_enabled"],
      webhook_secret: params["webhook_secret"],
      retry_failed: params["retry_failed"],
      max_retries: params["max_retries"]
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    case NotificationsWebhook.update_user_settings(user.id, attrs) do
      {:ok, settings} ->
        conn
        |> json(%{
          success: true,
          data: format_user_settings(settings)
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: format_changeset_errors(changeset)
          }
        })
    end
  end

  @doc """
  Get notification settings for a specific button.
  GET /api/buttons/:id/notifications
  """
  def show_button_settings(conn, %{"id" => button_id}) do
    user = conn.assigns.current_user

    # Verify button ownership
    case ButtonLog.Buttons.get_button(button_id, user.id) do
      {:ok, _button} ->
        settings = NotificationsWebhook.get_button_settings(button_id)

        conn
        |> json(%{
          success: true,
          data: format_button_settings(settings)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "BUTTON_NOT_FOUND",
            message: "Button not found"
          }
        })
    end
  end

  @doc """
  Update notification settings for a specific button.
  PUT /api/buttons/:id/notifications
  """
  def update_button_settings(conn, %{"id" => button_id} = params) do
    user = conn.assigns.current_user

    # Verify button ownership
    case ButtonLog.Buttons.get_button(button_id, user.id) do
      {:ok, button} ->
        # Check if user is owner (not just collaborator)
        if button.user_id == user.id do
          attrs = %{
            webhook_url: params["webhook_url"],
            webhook_enabled: params["webhook_enabled"],
            include_metadata: params["include_metadata"]
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()

          case NotificationsWebhook.update_button_settings(button_id, attrs) do
            {:ok, settings} ->
              conn
              |> json(%{
                success: true,
                data: format_button_settings(settings)
              })

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{
                success: false,
                error: %{
                  code: "VALIDATION_ERROR",
                  message: format_changeset_errors(changeset)
                }
              })
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            success: false,
            error: %{
              code: "NOT_OWNER",
              message: "Only the button owner can modify notification settings"
            }
          })
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "BUTTON_NOT_FOUND",
            message: "Button not found"
          }
        })
    end
  end

  @doc """
  List delivery history.
  GET /api/notifications/deliveries
  """
  def list_deliveries(conn, params) do
    user = conn.assigns.current_user
    limit = Map.get(params, "limit", "50") |> String.to_integer()
    offset = Map.get(params, "offset", "0") |> String.to_integer()

    deliveries = NotificationsWebhook.list_deliveries(user.id, limit, offset)

    conn
    |> json(%{
      success: true,
      data: Enum.map(deliveries, &format_delivery/1)
    })
  end

  @doc """
  Retry a failed delivery.
  POST /api/notifications/deliveries/:id/retry
  """
  def retry_delivery(conn, %{"id" => delivery_id}) do
    user = conn.assigns.current_user

    # Verify ownership
    case NotificationsWebhook.get_delivery(delivery_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "DELIVERY_NOT_FOUND",
            message: "Delivery not found"
          }
        })

      delivery when delivery.user_id != user.id ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_OWNER",
            message: "Not authorized to retry this delivery"
          }
        })

      delivery ->
        case NotificationsWebhook.retry_delivery(delivery.id) do
          {:ok, updated_delivery} ->
            conn
            |> json(%{
              success: true,
              data: format_delivery(updated_delivery)
            })

          {:error, :not_failed} ->
            conn
            |> put_status(:bad_request)
            |> json(%{
              success: false,
              error: %{
                code: "NOT_FAILED",
                message: "Only failed deliveries can be retried"
              }
            })

          {:error, reason, _delivery} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              success: false,
              error: %{
                code: "RETRY_FAILED",
                message: reason
              }
            })
        end
    end
  end

  @doc """
  Send a test webhook.
  POST /api/notifications/test
  """
  def test_webhook(conn, params) do
    user = conn.assigns.current_user
    button_id = params["button_id"]

    case NotificationsWebhook.send_test_webhook(user.id, button_id) do
      {:ok, delivery} ->
        conn
        |> json(%{
          success: true,
          data: format_delivery(delivery)
        })

      {:error, :no_webhook_configured} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: %{
            code: "NO_WEBHOOK",
            message: "No webhook URL configured"
          }
        })

      {:error, reason, delivery} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "WEBHOOK_FAILED",
            message: reason
          },
          data: format_delivery(delivery)
        })
    end
  end

  # Private formatters

  defp format_user_settings(nil) do
    %{
      default_webhook_url: nil,
      default_webhook_enabled: false,
      webhook_secret: nil,
      retry_failed: true,
      max_retries: 3
    }
  end

  defp format_user_settings(settings) do
    %{
      default_webhook_url: settings.default_webhook_url,
      default_webhook_enabled: settings.default_webhook_enabled,
      webhook_secret: if(settings.webhook_secret, do: "***configured***", else: nil),
      retry_failed: settings.retry_failed,
      max_retries: settings.max_retries
    }
  end

  defp format_button_settings(nil) do
    %{
      webhook_url: nil,
      webhook_enabled: nil,
      include_metadata: true
    }
  end

  defp format_button_settings(settings) do
    %{
      webhook_url: settings.webhook_url,
      webhook_enabled: settings.webhook_enabled,
      include_metadata: settings.include_metadata
    }
  end

  defp format_delivery(delivery) do
    %{
      id: delivery.id,
      channel: delivery.channel,
      destination: delivery.destination,
      status: delivery.status,
      response_code: delivery.response_code,
      error_message: delivery.error_message,
      attempts: delivery.attempts,
      delivered_at: delivery.delivered_at,
      button:
        if delivery.button do
          %{id: delivery.button.id, name: delivery.button.name}
        else
          nil
        end,
      inserted_at: delivery.inserted_at
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
