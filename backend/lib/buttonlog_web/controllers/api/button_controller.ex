defmodule ButtonLogWeb.API.ButtonController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Buttons
  alias ButtonLog.Buttons.Button
  alias ButtonLog.Social

  def index(conn, _params) do
    user = conn.assigns.current_user
    buttons = Buttons.list_accessible_buttons(user.id)

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

  def click(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    # Build click attributes from params
    click_attrs = %{
      device: params["device"] || "web",
      platform: params["platform"] || "web"
    }

    # Use access-checked click function to allow collaborators
    case Buttons.click_button_with_access_check(id, user.id, click_attrs) do
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

      {:error, :not_authorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_AUTHORIZED",
            message: "You don't have permission to click this button"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :owner_only_action} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "OWNER_ONLY",
            message: "Only the button owner can perform this action"
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

  defp serialize_button(%Button{} = button) do
    base = %{
      id: button.id,
      name: button.name,
      description: button.description,
      type: button.type,
      icon: button.icon || "star.fill",
      color: button.color || "#00BFA5",
      is_active: button.is_active,
      current_state: button.current_state || "idle",
      state_changed_at: format_datetime(button.state_changed_at),
      alerts_enabled: button.alerts_enabled,
      auto_stop_enabled: button.auto_stop_enabled,
      auto_stop_minutes: button.auto_stop_minutes,
      scheduled_stop_at: format_datetime(button.scheduled_stop_at),
      calendar_sync_enabled: button.calendar_sync_enabled,
      user_id: button.user_id,
      created_at: format_datetime(button.inserted_at),
      updated_at: format_datetime(button.updated_at),
      created_by_friend_id: button.created_by_friend_id,
      gift_message: button.gift_message,
      # Sharing fields
      sharing_mode: button.sharing_mode || "private",
      share_token: button.share_token,
      is_shared_with_me: false,
      owner_id: button.user_id,
      owner_name: nil
    }

    # Add created_by_friend info if preloaded and present
    if button.created_by_friend_id && Ecto.assoc_loaded?(button.created_by_friend) && button.created_by_friend do
      Map.put(base, :created_by_friend, %{
        id: button.created_by_friend.id,
        username: button.created_by_friend.username,
        display_name: button.created_by_friend.display_name
      })
    else
      base
    end
  end

  # Handle maps from list_user_buttons query (returns map with embedded gift info)
  defp serialize_button(%{} = button) do
    base = %{
      id: button.id,
      name: button.name,
      description: button.description,
      type: button.type,
      icon: button[:icon] || "star.fill",
      color: button[:color] || "#00BFA5",
      is_active: button.is_active,
      current_state: button[:current_state] || "idle",
      state_changed_at: format_datetime(button[:state_changed_at]),
      alerts_enabled: button.alerts_enabled,
      auto_stop_enabled: button.auto_stop_enabled,
      auto_stop_minutes: button[:auto_stop_minutes],
      scheduled_stop_at: format_datetime(button[:scheduled_stop_at]),
      calendar_sync_enabled: button.calendar_sync_enabled,
      user_id: button.user_id,
      created_at: format_datetime(button.inserted_at),
      updated_at: format_datetime(button.updated_at),
      created_by_friend_id: button[:created_by_friend_id],
      gift_message: button[:gift_message],
      # Sharing fields
      sharing_mode: button[:sharing_mode] || "private",
      share_token: button[:share_token],
      is_shared_with_me: button[:is_shared_with_me] || false,
      owner_id: button[:owner_id] || button.user_id,
      owner_name: button[:owner_name]
    }

    # Add created_by_friend info if present (from the query join)
    created_by_friend = button[:created_by_friend]
    if button[:created_by_friend_id] && created_by_friend && created_by_friend[:id] do
      Map.put(base, :created_by_friend, %{
        id: created_by_friend.id,
        username: created_by_friend.username,
        display_name: created_by_friend.display_name
      })
    else
      base
    end
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

  @doc """
  Creates a button for a friend (gift button).
  POST /api/buttons/gift
  """
  def create_for_friend(conn, %{"friend_id" => friend_id, "button" => button_params} = params) do
    user = conn.assigns.current_user
    message = Map.get(params, "message")

    case Buttons.create_button_for_friend(button_params, friend_id, user.id, message) do
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

      {:error, :not_friends} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FRIENDS",
            message: "You can only create buttons for your friends"
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

  # =============================================================================
  # Shared Button Endpoints
  # =============================================================================

  @doc """
  Updates the sharing mode for a button.
  PUT /api/buttons/:id/sharing-mode
  """
  def update_sharing_mode(conn, %{"id" => id, "mode" => mode} = params) do
    user = conn.assigns.current_user
    collaborator_ids = Map.get(params, "collaborator_ids", [])

    case Buttons.update_sharing_mode(id, user.id, mode) do
      {:ok, button} ->
        # If invite_only mode and collaborators provided, add them
        if mode == "invite_only" and length(collaborator_ids) > 0 do
          Enum.each(collaborator_ids, fn collab_id ->
            Buttons.add_collaborator(id, user.id, collab_id)
          end)
        end

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
          error: %{code: "NOT_FOUND", message: "Button not found"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid sharing mode",
            details: format_changeset_errors(changeset)
          },
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  @doc """
  Generates a share link for public sharing.
  POST /api/buttons/:id/share-link
  """
  def generate_share_link(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.generate_share_token(id, user.id) do
      {:ok, button} ->
        # Build the share URL
        base_url = ButtonLogWeb.Endpoint.url()
        share_url = "#{base_url}/join/#{button.share_token}"

        json(conn, %{
          success: true,
          data: %{
            share_token: button.share_token,
            share_url: share_url,
            expires_at: format_datetime(button.share_token_expires_at)
          },
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Button not found"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  @doc """
  Revokes a share link.
  DELETE /api/buttons/:id/share-link
  """
  def revoke_share_link(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.revoke_share_token(id, user.id) do
      {:ok, _button} ->
        json(conn, %{
          success: true,
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Button not found"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  @doc """
  Lists collaborators for a button.
  GET /api/buttons/:id/collaborators
  """
  def list_collaborators(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Buttons.list_collaborators(id, user.id) do
      {:ok, collaborators} ->
        json(conn, %{
          success: true,
          data: Enum.map(collaborators, &serialize_collaborator/1),
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Button not found"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_authorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{code: "NOT_AUTHORIZED", message: "You don't have permission to view collaborators"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  @doc """
  Adds a collaborator to a button.
  POST /api/buttons/:id/collaborators
  """
  def add_collaborator(conn, %{"id" => id, "user_id" => collaborator_id}) do
    user = conn.assigns.current_user

    case Buttons.add_collaborator(id, user.id, collaborator_id) do
      {:ok, collaborator} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: serialize_collaborator(collaborator),
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Button not found"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_friends} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{code: "NOT_FRIENDS", message: "You can only add friends as collaborators"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{code: "ALREADY_COLLABORATOR", message: "User is already a collaborator"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  @doc """
  Removes a collaborator from a button.
  DELETE /api/buttons/:id/collaborators/:user_id
  """
  def remove_collaborator(conn, %{"id" => id, "user_id" => collaborator_id}) do
    user = conn.assigns.current_user

    case Buttons.remove_collaborator(id, user.id, collaborator_id) do
      {:ok, _} ->
        json(conn, %{
          success: true,
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Button or collaborator not found"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  @doc """
  Joins a button via share token.
  POST /api/buttons/join/:token
  """
  def join_by_token(conn, %{"token" => token}) do
    user = conn.assigns.current_user

    case Buttons.join_by_share_token(token, user.id) do
      {:ok, button} ->
        json(conn, %{
          success: true,
          data: serialize_button(button),
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{code: "NOT_FOUND", message: "Invalid or expired share link"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })

      {:error, :not_public} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{code: "NOT_PUBLIC", message: "This button is not publicly shared"},
          meta: %{timestamp: DateTime.utc_now(), request_id: generate_request_id()}
        })
    end
  end

  defp serialize_collaborator(%{} = collaborator) do
    %{
      id: collaborator.id,
      user_id: collaborator.user_id,
      user_name: collaborator[:user_name] || collaborator[:username],
      permission: collaborator.permission,
      accepted_at: format_datetime(collaborator.accepted_at)
    }
  end

  defp serialize_collaborator(collaborator) do
    %{
      id: collaborator.id,
      user_id: collaborator.user_id,
      permission: collaborator.permission,
      accepted_at: format_datetime(collaborator.accepted_at)
    }
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

  # =====================
  # Alert Preferences
  # =====================

  @doc """
  Gets alert preferences for a button - which friends should receive alerts.
  GET /api/buttons/:id/alerts
  """
  def alert_preferences(conn, %{"id" => button_id}) do
    user = conn.assigns.current_user

    case Buttons.get_button(button_id, user.id) do
      {:ok, button} ->
        if button.user_id == user.id do
          # Get all friends
          friends = Social.get_user_friends(user.id)

          # Get current alert preferences for this button
          preferences = ButtonLog.Alerts.get_button_alert_preferences(button_id, user.id)
          preferences_map = Map.new(preferences, fn p -> {p.friend_id, p} end)

          # Build list with friend info and alert enabled status
          alert_settings = Enum.map(friends, fn friend ->
            pref = Map.get(preferences_map, friend.id)
            %{
              friend_id: friend.id,
              friend_username: friend.username,
              friend_display_name: friend.display_name,
              enabled: if(pref, do: pref.enabled, else: false),
              alert_type: if(pref, do: pref.alert_type, else: "click")
            }
          end)

          json(conn, %{
            success: true,
            data: alert_settings,
            meta: %{
              timestamp: DateTime.utc_now(),
              request_id: generate_request_id()
            }
          })
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            success: false,
            error: %{
              code: "FORBIDDEN",
              message: "Only the button owner can manage alert preferences"
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
          }
        })
    end
  end

  @doc """
  Toggles alert preference for a specific friend on a button.
  POST /api/buttons/:id/alerts/:friend_id/toggle
  """
  def toggle_alert_preference(conn, %{"id" => button_id, "friend_id" => friend_id}) do
    user = conn.assigns.current_user

    case Buttons.get_button(button_id, user.id) do
      {:ok, button} ->
        if button.user_id == user.id do
          case ButtonLog.Alerts.toggle_button_friend_alert(button_id, user.id, friend_id) do
            {:ok, preference} ->
              json(conn, %{
                success: true,
                data: %{
                  friend_id: friend_id,
                  enabled: preference.enabled,
                  alert_type: preference.alert_type
                }
              })

            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{
                success: false,
                error: %{
                  code: "UPDATE_FAILED",
                  message: "Failed to update alert preference: #{inspect(reason)}"
                }
              })
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            success: false,
            error: %{
              code: "FORBIDDEN",
              message: "Only the button owner can manage alert preferences"
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
          }
        })
    end
  end

  @doc """
  Sets alert preference for a specific friend on a button.
  PUT /api/buttons/:id/alerts/:friend_id
  """
  def set_alert_preference(conn, %{"id" => button_id, "friend_id" => friend_id} = params) do
    user = conn.assigns.current_user
    enabled = Map.get(params, "enabled", true)
    alert_type = Map.get(params, "alert_type", "click")

    case Buttons.get_button(button_id, user.id) do
      {:ok, button} ->
        if button.user_id == user.id do
          case ButtonLog.Alerts.set_button_friend_alert(button_id, user.id, friend_id, enabled, alert_type) do
            {:ok, preference} ->
              json(conn, %{
                success: true,
                data: %{
                  friend_id: friend_id,
                  enabled: preference.enabled,
                  alert_type: preference.alert_type
                }
              })

            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{
                success: false,
                error: %{
                  code: "UPDATE_FAILED",
                  message: "Failed to update alert preference: #{inspect(reason)}"
                }
              })
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            success: false,
            error: %{
              code: "FORBIDDEN",
              message: "Only the button owner can manage alert preferences"
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
          }
        })
    end
  end

  @doc """
  Enable alerts for all friends on a button.
  POST /api/buttons/:id/alerts/select-all
  """
  def select_all_alerts(conn, %{"id" => button_id}) do
    user = conn.assigns.current_user

    case Buttons.get_button(button_id, user.id) do
      {:ok, button} ->
        if button.user_id == user.id do
          friends = Social.get_user_friends(user.id)

          Enum.each(friends, fn friend ->
            ButtonLog.Alerts.set_button_friend_alert(button_id, user.id, friend.id, true)
          end)

          json(conn, %{
            success: true,
            data: %{
              message: "All friends selected for alerts",
              count: length(friends)
            }
          })
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            success: false,
            error: %{
              code: "FORBIDDEN",
              message: "Only the button owner can manage alert preferences"
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
          }
        })
    end
  end

  @doc """
  Disable alerts for all friends on a button.
  POST /api/buttons/:id/alerts/deselect-all
  """
  def deselect_all_alerts(conn, %{"id" => button_id}) do
    user = conn.assigns.current_user

    case Buttons.get_button(button_id, user.id) do
      {:ok, button} ->
        if button.user_id == user.id do
          friends = Social.get_user_friends(user.id)

          Enum.each(friends, fn friend ->
            ButtonLog.Alerts.set_button_friend_alert(button_id, user.id, friend.id, false)
          end)

          json(conn, %{
            success: true,
            data: %{
              message: "All friends deselected for alerts",
              count: length(friends)
            }
          })
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            success: false,
            error: %{
              code: "FORBIDDEN",
              message: "Only the button owner can manage alert preferences"
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
          }
        })
    end
  end
end


