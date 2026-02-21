defmodule ButtonLogWeb.API.SocialController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Social
  alias ButtonLog.Subscriptions.SubscriptionService

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
        created_at: format_datetime(friend.inserted_at),
        updated_at: format_datetime(friend.updated_at)
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
        created_at: format_datetime(request.inserted_at),
        updated_at: format_datetime(request.inserted_at)
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

    # Invite-only model: only accept email
    # Whether the email is registered or not, the UX is the same - "invite sent"
    case params do
      %{"email" => email} when is_binary(email) and email != "" ->
        send_invite_by_email(conn, user, email)

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: %{
            code: "MISSING_EMAIL",
            message: "Please provide an email address to invite"
          }
        })
    end
  end

  # Private: Handle invite by email (unified flow for both registered and unregistered users)
  defp send_invite_by_email(conn, user, email) do
    # Check if user is trying to invite themselves
    if String.downcase(email) == String.downcase(user.email) do
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
      # Check subscription limit before adding friend
      current_friend_count = Social.count_user_friends(user.id)

      case SubscriptionService.check_action_with_upgrade_info(user.id, :add_friend, %{current_friend_count: current_friend_count}) do
        {:ok, :allowed} ->
          # Check if user exists
          case ButtonLog.Accounts.get_user_by_email(email) do
            nil ->
              # User not registered - send invitation email
              handle_invitation(conn, user, email)

            friend ->
              # User exists - send friend request
              handle_friend_request(conn, user, friend.id, email)
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
            }
          })
      end
    end
  end

  # Private: Send invitation to unregistered user
  defp handle_invitation(conn, user, email) do
    case Social.send_friend_invitation(user.id, email) do
      {:ok, :invitation_sent} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            invite_sent: true,
            email: email,
            message: "Invite sent to #{email}"
          }
        })

      {:error, :email_failed} ->
        # Log error server-side but return success to prevent enumeration
        require Logger
        Logger.error("Failed to send invitation email to #{email}")
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            invite_sent: true,
            email: email,
            message: "Invite sent to #{email}"
          }
        })

      {:error, :inviter_not_found} ->
        # This shouldn't happen in normal use, but handle gracefully
        require Logger
        Logger.error("Inviter not found when sending friend invitation")
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            invite_sent: true,
            email: email,
            message: "Invite sent to #{email}"
          }
        })
    end
  end

  # Private: Send friend request to registered user
  defp handle_friend_request(conn, user, friend_id, email) do
    case Social.send_friend_request(user.id, friend_id) do
      {:ok, _friendship} ->
        # Same response as invitation to prevent enumeration
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            invite_sent: true,
            email: email,
            message: "Invite sent to #{email}"
          }
        })

      {:error, :already_friends} ->
        # Return success to prevent enumeration
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            invite_sent: true,
            email: email,
            message: "Invite sent to #{email}"
          }
        })

      {:error, _} ->
        # Any other error - still return success to prevent enumeration
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            invite_sent: true,
            email: email,
            message: "Invite sent to #{email}"
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

  @doc """
  Gets an aggregated activity feed from all friends.
  Returns activities from all friends who have granted view permission, sorted by most recent.
  """
  def activity_feed(conn, params) do
    user = conn.assigns.current_user
    limit = params |> Map.get("limit", "20") |> String.to_integer() |> min(50)
    cursor = Map.get(params, "cursor")
    cursor_id = Map.get(params, "cursor_id")

    opts = [limit: limit]
    opts = if cursor, do: Keyword.put(opts, :cursor, cursor), else: opts
    opts = if cursor_id, do: Keyword.put(opts, :cursor_id, cursor_id), else: opts

    result = Social.get_friends_activity_feed(user.id, opts)

    conn
    |> json(%{
      success: true,
      data: Enum.map(result.activities, &serialize_feed_activity/1),
      meta: %{
        count: length(result.activities),
        limit: limit,
        has_more: result.has_more,
        next_cursor: serialize_cursor(result.next_cursor)
      }
    })
  end

  defp serialize_feed_activity(activity) do
    %{
      id: activity.id,
      button_id: activity.button_id,
      button_name: activity.button_name,
      button_type: activity.button_type,
      button_icon: activity.button_icon || "star.fill",
      button_color: activity.button_color || "#00BFA5",
      user_id: activity.user_id,
      user_name: activity.user_name,
      clicked_at: format_datetime(activity.clicked_at),
      duration: activity.duration,
      action: activity.action,
      device: activity.device,
      platform: activity.platform,
      created_at: format_datetime(activity.inserted_at)
    }
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

  @doc """
  Accepts a friend invite via invite code.
  This creates a bidirectional friendship automatically.
  """
  def accept_invite(conn, %{"code" => code}) do
    user = conn.assigns.current_user

    # Find the user with this invite code
    case ButtonLog.Accounts.get_user_by_invite_code(code) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "INVALID_INVITE_CODE",
            message: "This invite link is invalid or has expired"
          }
        })

      inviter when inviter.id == user.id ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: %{
            code: "INVALID_REQUEST",
            message: "You cannot accept your own invite"
          }
        })

      inviter ->
        # Check subscription limit
        current_friend_count = Social.count_user_friends(user.id)

        case SubscriptionService.check_action_with_upgrade_info(user.id, :add_friend, %{current_friend_count: current_friend_count}) do
          {:ok, :allowed} ->
            # Check if already friends
            if Social.are_friends?(user.id, inviter.id) do
              conn
              |> json(%{
                success: true,
                data: %{
                  already_friends: true,
                  friend: %{
                    id: inviter.id,
                    username: inviter.username,
                    display_name: inviter.display_name
                  }
                }
              })
            else
              # Create bidirectional friendship
              case create_bidirectional_friendship(user.id, inviter.id) do
                {:ok, _} ->
                  conn
                  |> put_status(:created)
                  |> json(%{
                    success: true,
                    data: %{
                      friend: %{
                        id: inviter.id,
                        username: inviter.username,
                        display_name: inviter.display_name
                      },
                      message: "You are now friends with #{inviter.display_name || inviter.username}!"
                    }
                  })

                {:error, _reason} ->
                  conn
                  |> put_status(:internal_server_error)
                  |> json(%{
                    success: false,
                    error: %{
                      code: "FRIENDSHIP_ERROR",
                      message: "Failed to create friendship. Please try again."
                    }
                  })
              end
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
              }
            })
        end
    end
  end

  # Creates a bidirectional friendship between two users
  defp create_bidirectional_friendship(user_id, friend_id) do
    # Create friendship from user to friend (accepted)
    case Social.create_friendship(%{status: "accepted"}, user_id, friend_id) do
      {:ok, _friendship1} ->
        # Create reverse friendship
        case Social.create_friendship(%{status: "accepted"}, friend_id, user_id) do
          {:ok, _friendship2} ->
            # Create notification permissions for both directions
            ButtonLog.Notifications.upsert_friend_notification_permissions(%{
              can_receive_button_notifications: true,
              can_receive_friend_requests: true,
              can_receive_general_notifications: true,
              notification_frequency: "immediate"
            }, user_id, friend_id)

            ButtonLog.Notifications.upsert_friend_notification_permissions(%{
              can_receive_button_notifications: true,
              can_receive_friend_requests: true,
              can_receive_general_notifications: true,
              notification_frequency: "immediate"
            }, friend_id, user_id)

            {:ok, :friendship_created}

          {:error, reason} -> {:error, reason}
        end

      {:error, reason} -> {:error, reason}
    end
  end
end


