defmodule ButtonLogWeb.API.ButtonController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Buttons

  def index(conn, _params) do
    user = conn.assigns.current_user
    buttons = Buttons.list_user_buttons(user.id)

    json(conn, %{
      success: true,
      data: buttons,
      meta: %{
        timestamp: DateTime.utc_now(),
        request_id: generate_request_id()
      }
    })
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.get_button(id, user.id) do
      {:ok, button} ->
        json(conn, %{
          success: true,
          data: button,
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FOUND",
            message: "Button not found"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })
    end
  end

  def create(conn, %{"button" => button_params}) do
    user = conn.assigns.current_user

    case Buttons.create_button(button_params, user.id) do
      {:ok, button} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: button,
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid input data",
            details: format_changeset_errors(changeset)
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })
    end
  end

  def update(conn, %{"id" => id, "button" => button_params}) do
    user = conn.assigns.current_user

    case Buttons.update_button(id, button_params, user.id) do
      {:ok, button} ->
        json(conn, %{
          success: true,
          data: button,
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FOUND",
            message: "Button not found"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid input data",
            details: format_changeset_errors(changeset)
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.delete_button(id, user.id) do
      {:ok, _button} ->
        conn
        |> put_status(:no_content)
        |> json(%{
          success: true,
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FOUND",
            message: "Button not found"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "UNAUTHORIZED",
            message: "You don't have permission to delete this button"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })
    end
  end

  def click(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.click_button(id, user.id) do
      {:ok, click} ->
        json(conn, %{
          success: true,
          data: click,
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FOUND",
            message: "Button not found"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "CLICK_ERROR",
            message: "Failed to click button: #{reason}"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })
    end
  end

  defp generate_request_id do
    "req_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      %{
        field: field,
        message: List.first(messages)
      }
    end)
  end
end


