defmodule ButtonLogWeb.API.ButtonController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Buttons
  alias ButtonLog.Buttons.Button
  alias ButtonLog.Social
  alias ButtonLog.Alerts
  alias ButtonLog.Subscriptions.SubscriptionService

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

    # Check subscription limit before creating
    current_button_count = Buttons.count_user_buttons(user.id)

    case SubscriptionService.check_action_with_upgrade_info(user.id, :create_button, %{current_button_count: current_button_count}) do
      {:ok, :allowed} ->
        # Parse friend_alerts configuration if provided
        friend_alert_config = parse_friend_alert_config(button_params["friend_alerts"])

        case Buttons.create_button(button_params, user.id, friend_alert_config) do
          {:ok, button} ->
            # Track usage after successful creation
            SubscriptionService.track_usage(user.id, :create_button, %{})

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

      {:error, upgrade_info} ->
        conn
        |> put_status(:payment_required)
        |> json(%{
          success: false,
          error: %{
            code: "UPGRADE_REQUIRED",
            message: upgrade_info.message,
            upgrade_info: %{
              reason: upgrade_info.reason,
              current_plan: upgrade_info.current_plan,
              current_usage: upgrade_info[:current_usage],
              limit: upgrade_info[:limit],
              recommended_plan: upgrade_info.recommended_plan,
              upgrade_benefit: upgrade_info.upgrade_benefit
            }
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })
    end
  end

  # Parse friend_alerts configuration from request params
  defp parse_friend_alert_config(nil), do: nil
  defp parse_friend_alert_config(%{"mode" => "none"}), do: %{mode: "none"}
  defp parse_friend_alert_config(%{"mode" => "all_friends"}), do: %{mode: "all_friends"}
  defp parse_friend_alert_config(%{"mode" => "select_specific", "friend_ids" => friend_ids}) when is_list(friend_ids) do
    %{mode: "select_specific", friend_ids: friend_ids}
  end
  defp parse_friend_alert_config(_), do: nil

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

    # Get optional choice for one-time buttons with multiple choices
    selected_choice = params["choice"]

    # Use access-checked click function to allow collaborators
    case Buttons.click_button_with_access_check(id, user.id, click_attrs, selected_choice: selected_choice) do
      {:ok, click} ->
        # Send alerts to friends configured for this button
        Alerts.send_button_click_alerts(id, user.id, %{
          clicked_at: click.clicked_at,
          action: click.action,
          platform: click.platform,
          selected_choice: selected_choice
        })

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

      {:error, :choice_required} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "CHOICE_REQUIRED",
            message: "This button requires selecting a choice"
          },
          meta: %{
            timestamp: DateTime.utc_now(),
            request_id: generate_request_id()
          }
        })

      {:error, :invalid_choice} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "INVALID_CHOICE",
            message: "The selected choice is not valid for this button"
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
      # Multiple choice options for one-time buttons
      choices: button.choices,
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
      # Multiple choice options for one-time buttons
      choices: button[:choices],
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
      selected_choice: click.selected_choice,
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
  Lists all gift buttons created by the current user for their friends.
  GET /api/buttons/created-gifts
  """
  def created_gift_buttons(conn, _params) do
    user = conn.assigns.current_user
    buttons = Buttons.list_created_gift_buttons(user.id)

    json(conn, %{
      success: true,
      data: Enum.map(buttons, &serialize_gift_button/1),
      meta: %{
        timestamp: DateTime.utc_now(),
        request_id: generate_request_id()
      }
    })
  end

  # Serialize a gift button with recipient information
  defp serialize_gift_button(%{} = button) do
    %{
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
      calendar_sync_enabled: button.calendar_sync_enabled,
      user_id: button.user_id,
      created_at: format_datetime(button.inserted_at),
      updated_at: format_datetime(button.updated_at),
      gift_message: button[:gift_message],
      choices: button[:choices],
      # Recipient info (the friend who received this gift)
      recipient: if button[:recipient] && button[:recipient][:id] do
        %{
          id: button.recipient.id,
          username: button.recipient.username,
          display_name: button.recipient.display_name
        }
      else
        nil
      end
    }
  end

  @doc """
  Creates a button for a friend (gift button).
  POST /api/buttons/gift
  """
  def create_for_friend(conn, %{"friend_id" => friend_id, "button" => button_params} = params) do
    user = conn.assigns.current_user
    message = Map.get(params, "message")

    # Check if user can send gift buttons (Premium feature)
    case SubscriptionService.check_action_with_upgrade_info(user.id, :send_gift_button, %{}) do
      {:ok, :allowed} ->
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

      {:error, upgrade_info} ->
        conn
        |> put_status(:payment_required)
        |> json(%{
          success: false,
          error: %{
            code: "UPGRADE_REQUIRED",
            message: upgrade_info.message,
            upgrade_info: %{
              reason: upgrade_info.reason,
              current_plan: upgrade_info.current_plan,
              recommended_plan: upgrade_info.recommended_plan,
              upgrade_benefit: upgrade_info.upgrade_benefit
            }
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

  # =====================
  # Diary / Daily Activity
  # =====================

  @doc """
  Gets diary activity for a specific date.
  GET /api/diary?date=2025-01-22
  If no date provided, returns today's activity.
  """
  def diary(conn, params) do
    user = conn.assigns.current_user

    # Parse date from params, default to today
    date = case params["date"] do
      nil -> get_local_today()
      date_string ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> date
          {:error, _} -> get_local_today()
        end
    end

    # Get daily activities
    activities = get_daily_activities(user.id, date)
    summary = generate_daily_summary(activities, date)

    json(conn, %{
      success: true,
      data: %{
        date: Date.to_iso8601(date),
        summary: serialize_summary(summary),
        activities: Enum.map(activities, &serialize_activity/1)
      },
      meta: %{
        timestamp: DateTime.utc_now(),
        request_id: generate_request_id()
      }
    })
  end

  # Get today's date in local timezone (EST)
  defp get_local_today() do
    utc_now = DateTime.utc_now()
    timezone_offset_hours = -5  # Eastern Time (EST/EDT)
    local_now = DateTime.add(utc_now, timezone_offset_hours * 3600, :second)
    DateTime.to_date(local_now)
  end

  defp get_daily_activities(user_id, date) do
    import Ecto.Query

    # Convert local date to UTC start/end times for database query
    # For EST (-5 hours), local midnight corresponds to UTC 5:00 AM
    timezone_offset_hours = 5  # EST is 5 hours behind UTC

    start_of_day = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    |> DateTime.add(timezone_offset_hours * 3600, :second)

    end_of_day = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
    |> DateTime.add(timezone_offset_hours * 3600, :second)

    # Get all button clicks for the user on the specified date
    clicks = ButtonLog.Repo.all(
      from c in ButtonLog.Buttons.ButtonClick,
      join: b in ButtonLog.Buttons.Button, on: c.button_id == b.id,
      where: c.user_id == ^user_id and c.clicked_at >= ^start_of_day and c.clicked_at <= ^end_of_day,
      order_by: [desc: c.clicked_at],
      preload: [button: b]
    )

    # Group clicks by button
    clicks
    |> Enum.group_by(fn click -> click.button_id end)
    |> Enum.map(fn {_button_id, button_clicks} ->
      button = List.first(button_clicks).button

      %{
        button: button,
        clicks: button_clicks,
        total_clicks: length(button_clicks),
        first_click: List.last(button_clicks).clicked_at,  # Oldest click (last in desc order)
        last_click: List.first(button_clicks).clicked_at   # Newest click (first in desc order)
      }
    end)
    |> Enum.sort_by(fn activity -> activity.total_clicks end, :desc)
  end

  defp generate_daily_summary(activities, date) do
    total_buttons_used = length(activities)
    total_clicks = Enum.reduce(activities, 0, fn activity, acc -> acc + activity.total_clicks end)

    # Get button types used
    button_types = activities
    |> Enum.map(fn activity -> activity.button.type end)
    |> Enum.uniq()
    |> Enum.sort()

    # Get in-progress toggle buttons count
    in_progress_count = activities
    |> Enum.filter(fn activity ->
      activity.button.type == "toggle" && activity.button.current_state == "active"
    end)
    |> length()

    %{
      date: date,
      total_buttons_used: total_buttons_used,
      total_clicks: total_clicks,
      button_types_used: button_types,
      in_progress_count: in_progress_count,
      is_today: Date.compare(date, get_local_today()) == :eq,
      is_empty: activities == []
    }
  end

  defp serialize_summary(summary) do
    %{
      date: Date.to_iso8601(summary.date),
      total_buttons_used: summary.total_buttons_used,
      total_clicks: summary.total_clicks,
      button_types_used: summary.button_types_used,
      in_progress_count: summary.in_progress_count,
      is_today: summary.is_today,
      is_empty: summary.is_empty
    }
  end

  defp serialize_activity(activity) do
    %{
      button: %{
        id: activity.button.id,
        name: activity.button.name,
        type: activity.button.type,
        icon: activity.button.icon,
        color: activity.button.color,
        current_state: activity.button.current_state
      },
      total_clicks: activity.total_clicks,
      first_click_at: format_datetime(activity.first_click),
      last_click_at: format_datetime(activity.last_click),
      clicks: Enum.map(activity.clicks, fn click ->
        %{
          id: click.id,
          clicked_at: format_datetime(click.clicked_at),
          action: click.action,
          selected_choice: click.selected_choice
        }
      end)
    }
  end
end


