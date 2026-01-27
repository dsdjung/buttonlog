defmodule ButtonLog.Social do
  @moduledoc """
  The Social context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_change: 3]
  alias ButtonLog.Repo
  alias ButtonLog.Social.{Friendship, FriendPermission}
  alias ButtonLog.Notifications

  @doc """
  Returns the count of friends for a user (for subscription limit checks).
  """
  def count_user_friends(user_id) do
    # Count friends from both directions
    count_as_user = Repo.aggregate(
      from(f in Friendship,
        where: f.user_id == ^user_id and f.status == "accepted"
      ),
      :count,
      :id
    )

    count_as_friend = Repo.aggregate(
      from(f in Friendship,
        where: f.friend_id == ^user_id and f.status == "accepted"
      ),
      :count,
      :id
    )

    count_as_user + count_as_friend
  end

  @doc """
  Returns the list of friendships for a user.
  """
  def list_user_friendships(user_id) do
    Repo.all(
      from f in Friendship,
      where: f.user_id == ^user_id and f.status == "accepted",
      preload: [:friend]
    )
  end

  @doc """
  Returns the list of friends for a user.
  """
  def get_user_friends(user_id) do
    # Get friends from both directions: where user is user_id and where user is friend_id
    friends_as_user = Repo.all(
      from f in Friendship,
      where: f.user_id == ^user_id and f.status == "accepted",
      preload: [:friend]
    )

    friends_as_friend = Repo.all(
      from f in Friendship,
      where: f.friend_id == ^user_id and f.status == "accepted",
      preload: [:user]
    )

    # Combine both lists and map to consistent format
    all_friends =
      friends_as_user
      |> Enum.map(fn friendship ->
        %{
          id: friendship.friend.id,
          username: friendship.friend.username,
          display_name: friendship.friend.display_name,
          avatar: friendship.friend.avatar,
          friendship_status: friendship.status,
          friendship_id: friendship.id,
          inserted_at: friendship.inserted_at,
          updated_at: friendship.updated_at
        }
      end)
      |> Enum.concat(
        friends_as_friend
        |> Enum.map(fn friendship ->
          %{
            id: friendship.user.id,
            username: friendship.user.username,
            display_name: friendship.user.display_name,
            avatar: friendship.user.avatar,
            friendship_status: friendship.status,
            friendship_id: friendship.id,
            inserted_at: friendship.inserted_at,
            updated_at: friendship.updated_at
          }
        end)
      )

    # Remove duplicates (in case both directions exist)
    all_friends
    |> Enum.uniq_by(& &1.id)
  end

  @doc """
  Returns the list of friend IDs for a user.
  This is an optimized version that only returns IDs for querying purposes.
  """
  def get_user_friend_ids(user_id) do
    # Get friend IDs from both directions
    friend_ids_as_user = Repo.all(
      from f in Friendship,
        where: f.user_id == ^user_id and f.status == "accepted",
        select: f.friend_id
    )

    friend_ids_as_friend = Repo.all(
      from f in Friendship,
        where: f.friend_id == ^user_id and f.status == "accepted",
        select: f.user_id
    )

    # Combine and deduplicate
    (friend_ids_as_user ++ friend_ids_as_friend)
    |> Enum.uniq()
  end

  @doc """
  Creates default notification permissions for existing friendships.
  This is a utility function to set up permissions for users who became friends before the notification system was implemented.
  """
  def create_default_notification_permissions_for_friendships() do
    # Get all accepted friendships
    friendships = Repo.all(
      from f in Friendship,
      where: f.status == "accepted"
    )

    Enum.each(friendships, fn friendship ->
      # Create permissions for both directions
      Notifications.upsert_friend_notification_permissions(%{
        can_receive_button_notifications: true,
        can_receive_friend_requests: true,
        can_receive_general_notifications: true,
        notification_frequency: "immediate"
      }, friendship.user_id, friendship.friend_id)

      Notifications.upsert_friend_notification_permissions(%{
        can_receive_button_notifications: true,
        can_receive_friend_requests: true,
        can_receive_general_notifications: true,
        notification_frequency: "immediate"
      }, friendship.friend_id, friendship.user_id)
    end)

    {:ok, length(friendships)}
  end

  @doc """
  Gets IDs of users who are already friends or have pending requests with the current user.
  """
  def get_existing_friend_ids(user_id) do
    # Get all friendships (accepted, pending, etc.) in both directions
    forward_friendships = Repo.all(
      from f in Friendship,
      where: f.user_id == ^user_id,
      select: f.friend_id
    )

    reverse_friendships = Repo.all(
      from f in Friendship,
      where: f.friend_id == ^user_id,
      select: f.user_id
    )

    # Combine and deduplicate
    (forward_friendships ++ reverse_friendships)
    |> Enum.uniq()
  end

  @doc """
  Gets a single friendship.
  """
  def get_friendship!(id), do: Repo.get!(Friendship, id)

  @doc """
  Creates a friendship request.
  """
  def create_friendship(attrs \\ %{}, user_id, friend_id) do
    %Friendship{}
    |> Friendship.create_changeset(attrs, user_id, friend_id)
    |> Repo.insert()
  end

  @doc """
  Updates a friendship.
  """
  def update_friendship(%Friendship{} = friendship, attrs) do
    friendship
    |> Friendship.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Accepts a friendship request.
  """
  def accept_friendship(friendship_id) do
    case get_friendship!(friendship_id) do
      friendship ->
        friendship
        |> Friendship.changeset(%{status: "accepted"})
        |> Repo.update()
    end
  end

  @doc """
  Accepts a friendship request by the recipient.
  """
  def accept_friend_request(friendship_id, user_id) do
    case get_friendship!(friendship_id) do
      friendship ->
        if friendship.friend_id == user_id do
          # Update the existing friendship to accepted
          case update_friendship(friendship, %{status: "accepted"}) do
            {:ok, updated_friendship} ->
              # Create the reverse friendship so both users can see each other
              reverse_friendship = %Friendship{}
              |> Friendship.create_changeset(%{}, user_id, friendship.user_id)
              |> put_change(:status, "accepted")

              case Repo.insert(reverse_friendship) do
                {:ok, _reverse} ->
                  # Create default notification permissions for both users
                  ButtonLog.Notifications.upsert_friend_notification_permissions(%{
                    can_receive_button_notifications: true,
                    can_receive_friend_requests: true,
                    can_receive_general_notifications: true,
                    notification_frequency: "immediate"
                  }, user_id, friendship.user_id)

                  ButtonLog.Notifications.upsert_friend_notification_permissions(%{
                    can_receive_button_notifications: true,
                    can_receive_friend_requests: true,
                    can_receive_general_notifications: true,
                    notification_frequency: "immediate"
                  }, friendship.user_id, user_id)

                  # Send push notification to the original requester
                  accepter = ButtonLog.Accounts.get_user!(user_id)
                  Task.start(fn ->
                    ButtonLog.PushNotifications.send_friend_accepted_notification(
                      friendship.user_id,
                      accepter.display_name || accepter.username || accepter.email
                    )
                  end)

                  {:ok, updated_friendship}

                {:error, _reason} ->
                  # Even if reverse creation fails, the original friendship is accepted
                  {:ok, updated_friendship}
              end

            {:error, reason} ->
              {:error, reason}
          end
        else
          {:error, :unauthorized}
        end
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}
    Ecto.QueryError ->
      {:error, :not_found}
  end

  @doc """
  Deletes a friendship.
  """
  def delete_friendship(%Friendship{} = friendship) do
    Repo.delete(friendship)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking friendship changes.
  """
  def change_friendship(%Friendship{} = friendship, attrs \\ %{}) do
    Friendship.changeset(friendship, attrs)
  end

  @doc """
  Checks if two users are friends.
  """
  def are_friends?(user_id, friend_id) do
    # Check both directions: user_id -> friend_id and friend_id -> user_id
    case1 = Repo.get_by(Friendship, user_id: user_id, friend_id: friend_id, status: "accepted")
    case2 = Repo.get_by(Friendship, user_id: friend_id, friend_id: user_id, status: "accepted")

    case1 != nil or case2 != nil
  end

  @doc """
  Gets friend permissions for a user-friend pair.
  """
  def get_friend_permissions(user_id, friend_id) do
    Repo.get_by(FriendPermission, user_id: user_id, friend_id: friend_id)
  end

  @doc """
  Creates or updates friend permissions.
  """
  def upsert_friend_permissions(attrs, user_id, friend_id) do
    case get_friend_permissions(user_id, friend_id) do
      nil ->
        %FriendPermission{}
        |> FriendPermission.create_changeset(attrs, user_id, friend_id)
        |> Repo.insert()

      permissions ->
        permissions
        |> FriendPermission.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Checks if a friend can view the user's history.
  """
  def can_view_history?(user_id, friend_id) do
    case get_friend_permissions(user_id, friend_id) do
      nil -> true  # Default to true if no permissions set (matching can_view_buttons behavior)
      permissions -> permissions.can_view_history
    end
  end

  @doc """
  Checks if a friend can receive notifications from the user.
  """
  def can_receive_notifications?(user_id, friend_id) do
    case get_friend_permissions(user_id, friend_id) do
      nil -> true # Default to true if no permissions set
      permissions -> permissions.can_receive_notifications
    end
  end

  @doc """
  Checks if a friend can view the user's buttons.
  """
  def can_view_buttons?(user_id, friend_id) do
    case get_friend_permissions(user_id, friend_id) do
      nil -> true # Default to true if no permissions set
      permissions -> permissions.can_view_buttons
    end
  end

  @doc """
  Sends a friend request.
  """
  def send_friend_request(user_id, friend_id) do
    # Check if already friends or request pending in both directions
    existing_forward = Repo.get_by(Friendship, user_id: user_id, friend_id: friend_id)
    existing_reverse = Repo.get_by(Friendship, user_id: friend_id, friend_id: user_id)

    # Check if either friendship exists (not nil)
    if existing_forward != nil or existing_reverse != nil do
      {:error, :already_friends}
    else
      # Check if friend exists
      case ButtonLog.Accounts.get_user(friend_id) do
        nil ->
          {:error, :user_not_found}
        _user ->
          result = create_friendship(%{}, user_id, friend_id)

          # Send push notification for friend request
          case result do
            {:ok, _friendship} ->
              sender = ButtonLog.Accounts.get_user!(user_id)
              Task.start(fn ->
                ButtonLog.PushNotifications.send_friend_request_notification(
                  friend_id,
                  sender.display_name || sender.username || sender.email
                )
              end)
            _ -> :ok
          end

          result
      end
    end
  end

  @doc """
  Removes a friend.
  """
  def remove_friend(friendship_id, user_id) do
    case get_friendship!(friendship_id) do
      friendship ->
        if friendship.user_id == user_id or friendship.friend_id == user_id do
          # Determine the other user in this friendship
          other_user_id = if friendship.user_id == user_id, do: friendship.friend_id, else: friendship.user_id

          # Remove the original friendship
          case Repo.delete(friendship) do
            {:ok, _deleted_friendship} ->
              # Find and remove the reverse friendship
              reverse_friendship = Repo.get_by(Friendship,
                user_id: other_user_id,
                friend_id: user_id
              )

              if reverse_friendship do
                Repo.delete(reverse_friendship)
              end

              {:ok, :deleted}

            {:error, reason} ->
              {:error, reason}
          end
        else
          {:error, :unauthorized}
        end
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}
    Ecto.QueryError ->
      {:error, :not_found}
  end

  @doc """
  Updates friend permissions.
  """
  def update_friend_permissions(user_id, friend_id, attrs) do
    case get_friend_permissions(user_id, friend_id) do
      nil ->
        %FriendPermission{}
        |> FriendPermission.create_changeset(attrs, user_id, friend_id)
        |> Repo.insert()

      permissions ->
        permissions
        |> FriendPermission.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Gets pending friend requests for a user.
  """
  def get_pending_friend_requests(user_id) do
    Repo.all(
      from f in Friendship,
      where: f.friend_id == ^user_id and f.status == "pending",
      preload: [:user]
    )
    |> Enum.map(fn friendship ->
      %{
        id: friendship.id,
        user: %{
          id: friendship.user.id,
          username: friendship.user.username,
          display_name: friendship.user.display_name,
          avatar: friendship.user.avatar
        },
        status: friendship.status,
        inserted_at: friendship.inserted_at
      }
    end)
  end

  @doc """
  Gets sent friend requests for a user.
  """
  def get_sent_friend_requests(user_id) do
    Repo.all(
      from f in Friendship,
      where: f.user_id == ^user_id and f.status == "pending",
      preload: [:friend]
    )
    |> Enum.map(fn friendship ->
      %{
        id: friendship.id,
        friend: %{
          id: friendship.friend.id,
          username: friendship.friend.username,
          display_name: friendship.friend.display_name,
          avatar: friendship.friend.avatar
        },
        status: friendship.status,
        inserted_at: friendship.inserted_at
      }
    end)
  end

  @doc """
  Declines a friend request.
  """
  def decline_friend_request(friendship_id, user_id) do
    case get_friendship!(friendship_id) do
      friendship ->
        if friendship.friend_id == user_id do
          Repo.delete(friendship)
          {:ok, :declined}
        else
          {:error, :unauthorized}
        end
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
    Ecto.QueryError -> {:error, :not_found}
  end

  @doc """
  Cancels a sent friend request.
  """
  def cancel_friend_request(friendship_id, user_id) do
    case get_friendship!(friendship_id) do
      friendship ->
        if friendship.user_id == user_id and friendship.status == "pending" do
          Repo.delete(friendship)
          {:ok, :deleted}
        else
          {:error, :unauthorized}
        end
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
    Ecto.QueryError -> {:error, :not_found}
  end

  @doc """
  Gets the friendship between two users.
  """
  def get_friendship_between_users(user_id, friend_id) do
    # Try both directions
    case Repo.get_by(Friendship, user_id: user_id, friend_id: friend_id) do
      nil -> Repo.get_by(Friendship, user_id: friend_id, friend_id: user_id)
      friendship -> friendship
    end
  end

  @doc """
  Gets buttons shared between two friends.
  Returns the friend's buttons that the user has permission to see.
  Includes current state, last activity time, and location info.
  Filters out buttons that the friend has explicitly not shared with the user.
  """
  def get_shared_buttons(user_id, friend_id) do
    # First check if they are actually friends
    if are_friends?(user_id, friend_id) do
      # Check if the friend has granted the user permission to view their buttons
      # Permission is from friend's perspective: did friend allow user to see their buttons?
      if can_view_buttons?(friend_id, user_id) do
        # Return the friend's buttons filtered by per-button sharing settings
        ButtonLog.Buttons.list_shared_buttons_for_friend(friend_id, user_id)
      else
        []
      end
    else
      []
    end
  end

  @doc """
  Gets notifications shared between two friends.
  Returns notifications where the friend was the sender (their button clicks).
  """
  def get_shared_notifications(user_id, friend_id) do
    # Check if they are actually friends
    if are_friends?(user_id, friend_id) do
      # Get notifications where friend sent to user (friend's button clicks)
      Notifications.get_notifications_from_friend(user_id, friend_id)
    else
      []
    end
  end

  @doc """
  Gets button activity history for a friend with pagination support.
  Returns the friend's button clicks (activity) that the user has permission to see.
  Requires can_view_history permission to be true.

  Options:
    - :limit - number of items per page (default 20)
    - :cursor - ISO8601 datetime string for pagination
    - :cursor_id - ID for tie-breaking when timestamps match
  """
  def get_friend_activity(user_id, friend_id, opts \\ [])

  # Handle legacy call with integer limit for backward compatibility
  def get_friend_activity(user_id, friend_id, limit) when is_integer(limit) do
    get_friend_activity(user_id, friend_id, limit: limit)
  end

  def get_friend_activity(user_id, friend_id, opts) when is_list(opts) do
    # First check if they are actually friends
    if are_friends?(user_id, friend_id) do
      # Check if the friend has granted the user permission to view their history
      # Permission is from friend's perspective: did friend allow user to see their history?
      if can_view_history?(friend_id, user_id) do
        # Parse cursor if provided as string
        opts = parse_cursor_opts(opts)
        # Return the friend's button activity with pagination
        ButtonLog.Buttons.list_friend_button_activity(friend_id, opts)
      else
        {:error, :permission_denied}
      end
    else
      {:error, :not_friends}
    end
  end

  defp parse_cursor_opts(opts) do
    case Keyword.get(opts, :cursor) do
      nil -> opts
      cursor_str when is_binary(cursor_str) ->
        case DateTime.from_iso8601(cursor_str) do
          {:ok, datetime, _} ->
            Keyword.put(opts, :cursor, datetime)
          _ ->
            # Try NaiveDateTime
            case NaiveDateTime.from_iso8601(cursor_str) do
              {:ok, naive} ->
                Keyword.put(opts, :cursor, DateTime.from_naive!(naive, "Etc/UTC"))
              _ -> opts
            end
        end
      _ -> opts
    end
  end

  @doc """
  Sends an invitation email to someone who isn't registered yet.
  Returns {:ok, :invitation_sent} on success.
  """
  def send_friend_invitation(inviter_id, email) do
    # Use get_user instead of get_user! to handle missing users gracefully
    case ButtonLog.Accounts.get_user(inviter_id) do
      nil ->
        require Logger
        Logger.error("Cannot send friend invitation: inviter user #{inviter_id} not found")
        {:error, :inviter_not_found}

      inviter ->
        inviter_name = inviter.display_name || inviter.username || inviter.email
        email_struct = ButtonLog.Emails.friend_invitation(email, inviter_name)

        case ButtonLog.Mailer.deliver(email_struct) do
          {:ok, _} ->
            {:ok, :invitation_sent}

          {:error, reason} ->
            require Logger
            Logger.error("Failed to send invitation email to #{email}: #{inspect(reason)}")
            {:error, :email_failed}
        end
    end
  end
end
