defmodule ButtonLogWeb.API.SocialController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Social

  def friends(conn, _params) do
    user = conn.assigns.current_user

    # Get accepted friends
    accepted_friends = Social.get_user_friends(user.id)

    # Get pending friend requests (where current user is the recipient)
    pending_requests = Social.get_pending_friend_requests(user.id)

    # Combine both lists
    all_friends = Enum.map(accepted_friends, fn friend ->
      %{
        id: friend.friendship_id,
        friend_id: friend.id,
        friend_user: %{
          id: friend.id,
          username: friend.username,
          display_name: friend.display_name,
          first_name: nil,
          last_name: nil,
          profile_visibility: "public"
        },
        status: friend.friendship_status,
        permissions: %{
          can_see_buttons: true,
          can_see_activity: true,
          receive_notifications: true,
          can_comment: true
        },
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    end) ++ Enum.map(pending_requests, fn request ->
      %{
        id: request.id,
        friend_id: request.user.id,
        friend_user: %{
          id: request.user.id,
          username: request.user.username,
          display_name: request.user.display_name,
          first_name: nil,
          last_name: nil,
          profile_visibility: "public"
        },
        status: "pending",
        permissions: %{
          can_see_buttons: false,
          can_see_activity: false,
          receive_notifications: false,
          can_comment: false
        },
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    end)

    conn
    |> json(%{
      success: true,
      data: all_friends
    })
  end

  def send_friend_request(conn, params) do
    user = conn.assigns.current_user

    # Support lookup by friend_id, email, or username
    friend_result = cond do
      Map.has_key?(params, "friend_id") ->
        {:ok, params["friend_id"]}

      Map.has_key?(params, "email") ->
        case ButtonLog.Accounts.get_user_by_email(params["email"]) do
          nil ->
            # User not found - send invitation email
            {:invitation, params["email"]}
          friend ->
            # User found - send friend request
            # Response format is identical to invitation to prevent email enumeration
            {:existing_user, friend.id, params["email"]}
        end

      Map.has_key?(params, "username") ->
        case ButtonLog.Accounts.get_user_by_username(params["username"]) do
          nil -> {:error, :user_not_found}
          friend -> {:ok, friend.id}
        end

      true ->
        {:error, :missing_identifier}
    end

    case friend_result do
      {:ok, friend_id} ->
        # Friend request by friend_id (not email) - return detailed response
        if friend_id == user.id do
          conn
          |> put_status(:bad_request)
          |> json(%{
            success: false,
            error: %{
              code: "INVALID_REQUEST",
              message: "Cannot send friend request to yourself"
            }
          })
        else
          case Social.send_friend_request(user.id, friend_id) do
            {:ok, friendship} ->
              conn
              |> put_status(:created)
              |> json(%{
                success: true,
                data: %{
                  id: friendship.id,
                  status: friendship.status,
                  friend_id: friendship.friend_id
                }
              })

            {:error, :already_friends} ->
              conn
              |> put_status(:conflict)
              |> json(%{
                success: false,
                error: %{
                  code: "ALREADY_FRIENDS",
                  message: "Friend request already exists"
                }
              })

            {:error, :user_not_found} ->
              conn
              |> put_status(:not_found)
              |> json(%{
                success: false,
                error: %{
                  code: "USER_NOT_FOUND",
                  message: "User not found"
                }
              })
          end
        end

      {:existing_user, friend_id, email} ->
        # Friend request by email - user exists
        # Return unified response (same as invitation) to prevent email enumeration
        if friend_id == user.id do
          conn
          |> put_status(:bad_request)
          |> json(%{
            success: false,
            error: %{
              code: "INVALID_REQUEST",
              message: "Cannot send friend request to yourself"
            }
          })
        else
          case Social.send_friend_request(user.id, friend_id) do
            {:ok, _friendship} ->
              # Return same format as invitation to prevent enumeration
              conn
              |> put_status(:created)
              |> json(%{
                success: true,
                data: %{
                  request_sent: true,
                  email: email,
                  message: "Friend request sent to #{email}"
                }
              })

            {:error, :already_friends} ->
              # Still return success to prevent enumeration
              conn
              |> put_status(:created)
              |> json(%{
                success: true,
                data: %{
                  request_sent: true,
                  email: email,
                  message: "Friend request sent to #{email}"
                }
              })

            {:error, :user_not_found} ->
              # Shouldn't happen, but handle gracefully
              conn
              |> put_status(:created)
              |> json(%{
                success: true,
                data: %{
                  request_sent: true,
                  email: email,
                  message: "Friend request sent to #{email}"
                }
              })
          end
        end

      {:invitation, email} ->
        # Send invitation email to unregistered user
        # Response format matches existing user to prevent email enumeration
        case Social.send_friend_invitation(user.id, email) do
          {:ok, :invitation_sent} ->
            conn
            |> put_status(:created)
            |> json(%{
              success: true,
              data: %{
                request_sent: true,
                email: email,
                message: "Friend request sent to #{email}"
              }
            })

          {:error, :email_failed} ->
            # Even on email failure, return success to prevent enumeration
            # Log the error server-side instead
            require Logger
            Logger.error("Failed to send invitation email to #{email}")
            conn
            |> put_status(:created)
            |> json(%{
              success: true,
              data: %{
                request_sent: true,
                email: email,
                message: "Friend request sent to #{email}"
              }
            })
        end

      {:error, :user_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "USER_NOT_FOUND",
            message: "User not found"
          }
        })

      {:error, :missing_identifier} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: %{
            code: "MISSING_IDENTIFIER",
            message: "Please provide friend_id, email, or username"
          }
        })
    end
  end

  def accept_friend_request(conn, %{"id" => friendship_id}) do
    user = conn.assigns.current_user

    case Social.accept_friend_request(friendship_id, user.id) do
      {:ok, friendship} ->
        conn
        |> json(%{
          success: true,
          data: %{
            id: friendship.id,
            status: friendship.status
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "FRIENDSHIP_NOT_FOUND",
            message: "Friend request not found"
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "UNAUTHORIZED",
            message: "Not authorized to accept this request"
          }
        })
    end
  end

  def remove_friend(conn, %{"id" => friendship_id}) do
    user = conn.assigns.current_user

    case Social.remove_friend(friendship_id, user.id) do
      {:ok, _} ->
        conn
        |> json(%{
          success: true,
          data: %{message: "Friend removed successfully"}
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "FRIENDSHIP_NOT_FOUND",
            message: "Friendship not found"
          }
        })
    end
  end

  def get_permissions(conn, %{"friend_id" => friend_id}) do
    user = conn.assigns.current_user

    case Social.get_friend_permissions(user.id, friend_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "PERMISSIONS_NOT_FOUND",
            message: "Permissions not found"
          }
        })

      permissions ->
        conn
        |> json(%{
          success: true,
          data: %{
            can_view_history: permissions.can_view_history,
            can_receive_notifications: permissions.can_receive_notifications,
            can_view_buttons: permissions.can_view_buttons
          }
        })
    end
  end

  def update_permissions(conn, %{"friend_id" => friend_id, "permissions" => permission_params}) do
    user = conn.assigns.current_user

    case Social.update_friend_permissions(user.id, friend_id, permission_params) do
      {:ok, permissions} ->
        conn
        |> json(%{
          success: true,
          data: %{
            can_view_history: permissions.can_view_history,
            can_receive_notifications: permissions.can_receive_notifications,
            can_view_buttons: permissions.can_view_buttons
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid permission data",
            details: format_changeset_errors(changeset)
          }
        })
    end
  end

  def friend_buttons(conn, %{"friend_id" => friend_id}) do
    user = conn.assigns.current_user

    # Check if they are friends first
    if Social.are_friends?(user.id, friend_id) do
      buttons = Social.get_shared_buttons(user.id, friend_id)

      conn
      |> json(%{
        success: true,
        data: Enum.map(buttons, &serialize_button/1)
      })
    else
      conn
      |> put_status(:forbidden)
      |> json(%{
        success: false,
        error: %{
          code: "NOT_FRIENDS",
          message: "You are not friends with this user"
        }
      })
    end
  end

  def friend_activity(conn, %{"friend_id" => friend_id} = params) do
    user = conn.assigns.current_user
    limit = params |> Map.get("limit", "20") |> String.to_integer() |> min(100)
    cursor = Map.get(params, "cursor")
    cursor_id = Map.get(params, "cursor_id")

    opts = [limit: limit]
    opts = if cursor, do: Keyword.put(opts, :cursor, cursor), else: opts
    opts = if cursor_id, do: Keyword.put(opts, :cursor_id, cursor_id), else: opts

    case Social.get_friend_activity(user.id, friend_id, opts) do
      {:error, :not_friends} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FRIENDS",
            message: "You are not friends with this user"
          }
        })

      {:error, :permission_denied} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          success: false,
          error: %{
            code: "PERMISSION_DENIED",
            message: "This friend has not granted you permission to view their activity history"
          }
        })

      {activities, next_cursor, has_more} ->
        conn
        |> json(%{
          success: true,
          data: Enum.map(activities, &serialize_activity/1),
          meta: %{
            count: length(activities),
            limit: limit,
            has_more: has_more,
            next_cursor: serialize_cursor(next_cursor)
          }
        })
    end
  end

  defp serialize_cursor(nil), do: nil
  defp serialize_cursor(%{clicked_at: clicked_at, id: id}) do
    %{
      clicked_at: format_datetime(clicked_at),
      id: id
    }
  end

  defp serialize_button(button) do
    %{
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
      calendar_sync_enabled: button.calendar_sync_enabled,
      user_id: button.user_id,
      created_at: format_datetime(button.inserted_at),
      updated_at: format_datetime(button.updated_at),
      latest_click_at: format_datetime(Map.get(button, :latest_click_at)),
      latest_click_action: Map.get(button, :latest_click_action),
      latest_click_location: serialize_location(
        Map.get(button, :latest_click_location_lat),
        Map.get(button, :latest_click_location_lng)
      ),
      latest_click_device: Map.get(button, :latest_click_device),
      latest_click_platform: Map.get(button, :latest_click_platform)
    }
  end

  defp serialize_location(nil, _), do: nil
  defp serialize_location(_, nil), do: nil
  defp serialize_location(lat, lng) do
    %{
      lat: Decimal.to_float(lat),
      lng: Decimal.to_float(lng)
    }
  end

  defp serialize_activity(activity) do
    %{
      id: activity.id,
      button_id: activity.button_id,
      button_name: activity.button_name,
      button_type: activity.button_type,
      button_icon: activity.button_icon || "star.fill",
      button_color: activity.button_color || "#00BFA5",
      user_id: activity.user_id,
      clicked_at: format_datetime(activity.clicked_at),
      duration: activity.duration,
      action: activity.action,
      device: activity.device,
      platform: activity.platform,
      created_at: format_datetime(activity.inserted_at)
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

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      %{field: field, message: List.first(errors)}
    end)
  end
end


