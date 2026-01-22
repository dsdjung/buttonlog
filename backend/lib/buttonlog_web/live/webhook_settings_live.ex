defmodule ButtonLogWeb.WebhookSettingsLive do
  @moduledoc """
  LiveView for managing webhook notification settings.
  Users can configure their default webhook URL and settings for external integrations.
  """

  use ButtonLogWeb, :live_view

  alias ButtonLog.Accounts
  alias ButtonLog.NotificationsWebhook

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      {:ok, settings} = NotificationsWebhook.get_or_create_user_settings(user_id)
      deliveries = NotificationsWebhook.list_deliveries(user_id, 10)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:settings, settings)
       |> assign(:deliveries, deliveries)
       |> assign(:form, to_form(settings_to_map(settings)))
       |> assign(:test_result, nil)
       |> assign(:saving, false)
       |> assign(:testing, false)
       |> assign(:page_title, "Webhook Settings")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access webhook settings")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"settings" => params}, socket) do
    form =
      params
      |> normalize_params()
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"settings" => params}, socket) do
    socket = assign(socket, :saving, true)

    normalized_params = normalize_params(params)

    case NotificationsWebhook.update_user_settings(socket.assigns.current_user.id, normalized_params) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> assign(:settings, settings)
         |> assign(:form, to_form(settings_to_map(settings)))
         |> assign(:saving, false)
         |> put_flash(:info, "Webhook settings saved successfully")}

      {:error, changeset} ->
        errors = format_errors(changeset)
        {:noreply,
         socket
         |> assign(:saving, false)
         |> put_flash(:error, "Failed to save: #{errors}")}
    end
  end

  @impl true
  def handle_event("test_webhook", _params, socket) do
    socket = assign(socket, :testing, true)

    case NotificationsWebhook.send_test_webhook(socket.assigns.current_user.id) do
      {:ok, delivery} ->
        # Refresh deliveries list
        deliveries = NotificationsWebhook.list_deliveries(socket.assigns.current_user.id, 10)

        {:noreply,
         socket
         |> assign(:testing, false)
         |> assign(:deliveries, deliveries)
         |> assign(:test_result, %{success: true, message: "Test webhook sent successfully", response_code: delivery.response_code})
         |> put_flash(:info, "Test webhook sent successfully")}

      {:error, :no_webhook_configured} ->
        {:noreply,
         socket
         |> assign(:testing, false)
         |> assign(:test_result, %{success: false, message: "No webhook URL configured"})
         |> put_flash(:error, "Please configure a webhook URL first")}

      {:error, reason, delivery} ->
        # Refresh deliveries list
        deliveries = NotificationsWebhook.list_deliveries(socket.assigns.current_user.id, 10)

        {:noreply,
         socket
         |> assign(:testing, false)
         |> assign(:deliveries, deliveries)
         |> assign(:test_result, %{success: false, message: "Webhook failed: #{reason}", response_code: delivery.response_code})
         |> put_flash(:error, "Test webhook failed: #{reason}")}
    end
  end

  @impl true
  def handle_event("retry_delivery", %{"id" => delivery_id}, socket) do
    case NotificationsWebhook.retry_delivery(delivery_id) do
      {:ok, _delivery} ->
        deliveries = NotificationsWebhook.list_deliveries(socket.assigns.current_user.id, 10)

        {:noreply,
         socket
         |> assign(:deliveries, deliveries)
         |> put_flash(:info, "Delivery retried")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Delivery not found")}

      {:error, :not_failed} ->
        {:noreply, put_flash(socket, :error, "Can only retry failed deliveries")}

      {:error, _reason, _delivery} ->
        deliveries = NotificationsWebhook.list_deliveries(socket.assigns.current_user.id, 10)

        {:noreply,
         socket
         |> assign(:deliveries, deliveries)
         |> put_flash(:error, "Retry failed")}
    end
  end

  @impl true
  def handle_event("generate_secret", _params, socket) do
    secret = :crypto.strong_rand_bytes(32) |> Base.encode64()

    form_data = socket.assigns.form.params || settings_to_map(socket.assigns.settings)
    updated_form_data = Map.put(form_data, "webhook_secret", secret)

    {:noreply, assign(socket, :form, to_form(updated_form_data))}
  end

  # Private functions

  defp settings_to_map(settings) do
    %{
      "default_webhook_url" => settings.default_webhook_url || "",
      "default_webhook_enabled" => settings.default_webhook_enabled || false,
      "webhook_secret" => settings.webhook_secret || "",
      "retry_failed" => settings.retry_failed,
      "max_retries" => settings.max_retries || 3
    }
  end

  defp normalize_params(params) do
    %{
      default_webhook_url: normalize_url(params["default_webhook_url"]),
      default_webhook_enabled: params["default_webhook_enabled"] == "true",
      webhook_secret: normalize_string(params["webhook_secret"]),
      retry_failed: params["retry_failed"] == "true",
      max_retries: parse_int(params["max_retries"], 3)
    }
  end

  defp normalize_url(nil), do: nil
  defp normalize_url(""), do: nil
  defp normalize_url(url), do: String.trim(url)

  defp normalize_string(nil), do: nil
  defp normalize_string(""), do: nil
  defp normalize_string(str), do: String.trim(str)

  defp parse_int(nil, default), do: default
  defp parse_int("", default), do: default
  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {num, _} -> num
      :error -> default
    end
  end
  defp parse_int(num, _default) when is_integer(num), do: num

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  # Helper function for template - must be public for HEEx
  def status_class(status) do
    case status do
      "sent" -> "bg-green-100 text-green-800"
      "failed" -> "bg-red-100 text-red-800"
      "pending" -> "bg-yellow-100 text-yellow-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
