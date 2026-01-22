defmodule ButtonLogWeb.API.ButtonController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Buttons
  alias ButtonLog.Social

  def index(conn, _params) do
    user = conn.assigns.current_user
    buttons = Buttons.list_user_buttons(user.id)

    json(conn, %{
      success: true,
      data: Enum.map(buttons, &serialize_button/1),
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
          data: serialize_button(button),
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
          data: serialize_button(button),
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
          data: serialize_button(button),
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
          data: serialize_click(click),
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

  def history(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    limit = Map.get(params, "limit", "50") |> String.to_integer()

    case Buttons.list_button_clicks(id, user.id, limit) do
      {:ok, clicks} ->
        json(conn, %{
          success: true,
          data: Enum.map(clicks, &serialize_click/1),
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id(),
            count: length(clicks)
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

  defp serialize_button(button) do
    %{
      id: button.id,
      name: button.name,
      description: button.description,
      type: button.type,
      icon: button.icon || "star.fill",
      color: button.color || "#007AFF",
      is_active: button.is_active,
      current_state: button.current_state || "idle",
      state_changed_at: format_datetime(button.state_changed_at),
      notifications_enabled: button.notifications_enabled,
      auto_stop_enabled: button.auto_stop_enabled,
      calendar_sync_enabled: button.calendar_sync_enabled,
      user_id: button.user_id,
      created_at: format_datetime(button.inserted_at),
      updated_at: format_datetime(button.updated_at)
    }
  end

  defp serialize_click(click) do
    %{
      id: click.id,
      button_id: click.button_id,
      user_id: click.user_id,
      clicked_at: format_datetime(click.clicked_at),
      duration: click.duration,
      location_lat: click.location_lat && Decimal.to_float(click.location_lat),
      location_lng: click.location_lng && Decimal.to_float(click.location_lng),
      device: click.device,
      platform: click.platform,
      action: click.action,
      created_at: format_datetime(click.inserted_at)
    }
  end

  @doc """
  Gets the sharing settings for a button.
  Returns a list of friends and whether the button is shared with each.
  """
  def sharing(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.get_button(id, user.id) do
      {:ok, _button} ->
        # Get all accepted friends (bidirectional)
        friends = Social.get_user_friends(user.id)

        # Get sharing settings for this button
        sharing_settings = Enum.map(friends, fn friend ->
          is_shared = Buttons.is_button_shared_with_friend?(id, friend.id)
          %{
            friend_id: friend.id,
            friend_username: friend.username,
            friend_display_name: friend.display_name,
            is_shared: is_shared
          }
        end)

        json(conn, %{
          success: true,
          data: sharing_settings,
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

  @doc """
  Updates the sharing settings for a button.
  Expects a list of {friend_id, is_shared} pairs.
  """
  def update_sharing(conn, %{"id" => id, "sharing" => sharing_params}) do
    user = conn.assigns.current_user

    case Buttons.get_button(id, user.id) do
      {:ok, _button} ->
        # Convert params to the expected format
        friend_settings = Enum.map(sharing_params, fn setting ->
          %{
            friend_id: setting["friend_id"],
            is_shared: setting["is_shared"]
          }
        end)

        case Buttons.update_button_sharing_bulk(id, user.id, friend_settings) do
          {:ok, _sharing} ->
            # Return updated sharing settings
            sharing(conn, %{"id" => id})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              success: false,
              error: %{
                code: "VALIDATION_ERROR",
                message: "Failed to update sharing settings",
                details: format_changeset_errors(changeset)
              },
              meta: %{
                timestamp: DateTime.utc_now(),
                request_id: generate_request_id()
              }
            })
        end

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

  defp format_datetime(nil), do: nil
  defp format_datetime(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end
  defp format_datetime(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end
end


