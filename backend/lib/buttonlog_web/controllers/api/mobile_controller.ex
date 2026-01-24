defmodule ButtonLogWeb.API.MobileController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Mobile
  alias ButtonLog.PushNotifications

  @doc """
  Registers a device for push notifications.
  """
  def register_device(conn, params) do
    user = conn.assigns.current_user

    IO.puts "=== DEVICE REGISTRATION DEBUG ==="
    IO.puts "params: #{inspect(params)}"

    device_attrs = %{
      device_token: params["device_token"],
      platform: params["platform"],
      app_version: params["app_version"],
      os_version: params["os_version"]
    }

    IO.puts "device_attrs: #{inspect(device_attrs)}"

    case Mobile.register_device(device_attrs, user.id) do
      {:ok, connection} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: %{
            id: connection.id,
            device_token: connection.device_token,
            platform: connection.platform,
            is_active: connection.is_active
          }
        })

      {:error, changeset} ->
        IO.puts "=== DEVICE REGISTRATION ERROR ==="
        IO.puts "changeset errors: #{inspect(changeset.errors)}"
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Failed to register device",
            details: format_changeset_errors(changeset)
          }
        })
    end
  end

  @doc """
  Unregisters a device (deactivates push notifications).
  """
  def unregister_device(conn, %{"device_token" => device_token}) do
    case Mobile.get_connection_by_token(device_token) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "DEVICE_NOT_FOUND",
            message: "Device not found"
          }
        })

      connection ->
        case Mobile.deactivate_connection(connection.id) do
          {:ok, _} ->
            conn
            |> put_status(:ok)
            |> json(%{
              success: true,
              data: %{message: "Device unregistered successfully"}
            })

          {:error, _} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              success: false,
              error: %{
                code: "UNREGISTER_FAILED",
                message: "Failed to unregister device"
              }
            })
        end
    end
  end

  @doc """
  Lists all registered devices for the current user.
  """
  def list_devices(conn, _params) do
    user = conn.assigns.current_user
    connections = Mobile.list_user_connections(user.id)

    conn
    |> json(%{
      success: true,
      data: Enum.map(connections, fn connection ->
        %{
          id: connection.id,
          device_token: connection.device_token,
          platform: connection.platform,
          app_version: connection.app_version,
          os_version: connection.os_version,
          is_active: connection.is_active,
          last_seen_at: connection.last_seen_at
        }
      end)
    })
  end

  @doc """
  Sends a test push notification to the current user's devices.
  Useful for verifying push notification setup.
  """
  def send_test_notification(conn, params) do
    user = conn.assigns.current_user
    title = params["title"] || "Test Notification"
    body = params["body"] || "This is a test push notification from ButtonLog"

    {:ok, result} = PushNotifications.send_to_user(user.id, title, body, %{"type" => "test"})

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      data: %{
        message: "Test notification sent",
        successes: result.successes,
        failures: result.failures,
        total_devices: result.total
      }
    })
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
