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
    IO.puts "=== GET USER FRIENDS DEBUG ==="
    IO.puts "user_id: #{user_id}"

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

    IO.puts "friends_as_user count: #{length(friends_as_user)}"
    IO.puts "friends_as_friend count: #{length(friends_as_friend)}"

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
          friendship_id: friendship.id  # Include the friendship ID for removal
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
            friendship_id: friendship.id  # Include the friendship ID for removal
          }
        end)
      )

    # Remove duplicates (in case both directions exist)
    unique_friends = all_friends
    |> Enum.uniq_by(& &1.id)

    IO.puts "total unique friends: #{length(unique_friends)}"
    unique_friends
  end

  @doc """
  Creates default notification permissions for existing friendships.
  This is a utility function to set up permissions for users who became friends before the notification system was implemented.
  """
  def create_default_notification_permissions_for_friendships() do
    IO.puts "=== CREATING DEFAULT NOTIFICATION PERMISSIONS ==="

    # Get all accepted friendships
    friendships = Repo.all(
      from f in Friendship,
      where: f.status == "accepted"
    )

    IO.puts "Found #{length(friendships)} accepted friendships"

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

    IO.puts "Default notification permissions created for all friendships"
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
    IO.puts "=== CREATE FRIENDSHIP DEBUG ==="
    IO.puts "attrs: #{inspect(attrs)}"
    IO.puts "user_id: #{user_id}"
    IO.puts "friend_id: #{friend_id}"

    changeset = %Friendship{}
    |> Friendship.create_changeset(attrs, user_id, friend_id)

    IO.puts "changeset valid?: #{changeset.valid?}"
    IO.puts "changeset errors: #{inspect(changeset.errors)}"

    result = Repo.insert(changeset)
    IO.puts "Repo.insert result: #{inspect(result)}"
    result
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
    IO.puts "=== ACCEPT FRIEND REQUEST DEBUG ==="
    IO.puts "friendship_id: #{friendship_id}"
    IO.puts "user_id: #{user_id}"

    case get_friendship!(friendship_id) do
      friendship ->
        IO.puts "Found friendship: #{inspect(friendship)}"

        if friendship.friend_id == user_id do
          IO.puts "User authorized to accept this request"

          # Update the existing friendship to accepted
          case update_friendship(friendship, %{status: "accepted"}) do
            {:ok, updated_friendship} ->
              IO.puts "Updated friendship to accepted: #{inspect(updated_friendship)}"

              # Create the reverse friendship so both users can see each other
              reverse_friendship = %Friendship{}
              |> Friendship.create_changeset(%{}, user_id, friendship.user_id)
              |> put_change(:status, "accepted")

              IO.puts "Creating reverse friendship..."
                                          case Repo.insert(reverse_friendship) do
                              {:ok, reverse} ->
                                IO.puts "Reverse friendship created: #{inspect(reverse)}"

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

                                {:ok, updated_friendship}

                              {:error, reason} ->
                                IO.puts "Failed to create reverse friendship: #{inspect(reason)}"
                                # Even if reverse creation fails, the original friendship is accepted
                                {:ok, updated_friendship}
                            end

            {:error, reason} ->
              IO.puts "Failed to update friendship: #{inspect(reason)}"
              {:error, reason}
          end
        else
          IO.puts "User not authorized to accept this request"
          {:error, :unauthorized}
        end
    end
  rescue
    Ecto.QueryError ->
      IO.puts "Query error: friendship not found"
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
      nil -> false
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
    IO.puts "=== SEND FRIEND REQUEST DEBUG ==="
    IO.puts "user_id: #{user_id}"
    IO.puts "friend_id: #{friend_id}"

    # Check if already friends or request pending in both directions
    existing_forward = Repo.get_by(Friendship, user_id: user_id, friend_id: friend_id)
    existing_reverse = Repo.get_by(Friendship, user_id: friend_id, friend_id: user_id)

    IO.puts "existing_forward: #{inspect(existing_forward)}"
    IO.puts "existing_reverse: #{inspect(existing_reverse)}"

    # Check if either friendship exists (not nil)
    if existing_forward != nil or existing_reverse != nil do
      IO.puts "Already friends or request pending"
      {:error, :already_friends}
    else
      # Check if friend exists
      case ButtonLog.Accounts.get_user(friend_id) do
        nil ->
          IO.puts "User not found"
          {:error, :user_not_found}
        _user ->
          IO.puts "Creating friendship..."
          result = create_friendship(%{}, user_id, friend_id)
          IO.puts "create_friendship result: #{inspect(result)}"
          result
      end
    end
  end

  @doc """
  Removes a friend.
  """
  def remove_friend(friendship_id, user_id) do
    IO.puts "=== REMOVE FRIEND DEBUG ==="
    IO.puts "friendship_id: #{friendship_id}"
    IO.puts "user_id: #{user_id}"

    case get_friendship!(friendship_id) do
      friendship ->
        IO.puts "Found friendship: #{inspect(friendship)}"

        if friendship.user_id == user_id or friendship.friend_id == user_id do
          IO.puts "User authorized to remove friendship"

          # Determine the other user in this friendship
          other_user_id = if friendship.user_id == user_id, do: friendship.friend_id, else: friendship.user_id
          IO.puts "other_user_id: #{other_user_id}"

          # Remove the original friendship
          case Repo.delete(friendship) do
            {:ok, _deleted_friendship} ->
              IO.puts "Original friendship deleted"

              # Find and remove the reverse friendship
              reverse_friendship = Repo.get_by(Friendship,
                user_id: other_user_id,
                friend_id: user_id
              )

              if reverse_friendship do
                IO.puts "Found reverse friendship, deleting it too"
                case Repo.delete(reverse_friendship) do
                  {:ok, _deleted_reverse} ->
                    IO.puts "Reverse friendship deleted"
                    {:ok, :deleted}
                  {:error, reason} ->
                    IO.puts "Failed to delete reverse friendship: #{inspect(reason)}"
                    # Even if reverse deletion fails, the main friendship is gone
                    {:ok, :deleted}
                end
              else
                IO.puts "No reverse friendship found"
                {:ok, :deleted}
              end

            {:error, reason} ->
              IO.puts "Failed to delete original friendship: #{inspect(reason)}"
              {:error, reason}
          end
        else
          IO.puts "User not authorized to remove this friendship"
          {:error, :unauthorized}
        end
    end
  rescue
    Ecto.QueryError ->
      IO.puts "Query error: friendship not found"
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
  """
  def get_shared_buttons(user_id, friend_id) do
    # First check if they are actually friends
    if are_friends?(user_id, friend_id) do
      # Check if the friend has granted the user permission to view their buttons
      # Permission is from friend's perspective: did friend allow user to see their buttons?
      if can_view_buttons?(friend_id, user_id) do
        # Return the friend's buttons with latest click details
        ButtonLog.Buttons.list_user_buttons_with_latest_click(friend_id)
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
  Gets button activity history for a friend.
  Returns the friend's button clicks (activity) that the user has permission to see.
  Requires can_view_history permission to be true.
  """
  def get_friend_activity(user_id, friend_id, limit \\ 50) do
    # First check if they are actually friends
    if are_friends?(user_id, friend_id) do
      # Check if the friend has granted the user permission to view their history
      # Permission is from friend's perspective: did friend allow user to see their history?
      if can_view_history?(friend_id, user_id) do
        # Return the friend's button activity
        ButtonLog.Buttons.list_friend_button_activity(friend_id, limit)
      else
        {:error, :permission_denied}
      end
    else
      {:error, :not_friends}
    end
  end
end
