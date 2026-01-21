defmodule ButtonLog.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Accounts.User

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user by username.
  """
  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a new user.
  """
  def register_user(attrs \\ %{}) do
    # Auto-generate username and display_name from email if not provided
    attrs = maybe_generate_defaults(attrs)

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  defp maybe_generate_defaults(attrs) do
    attrs = stringify_keys(attrs)

    email = attrs["email"] || ""
    base_name = email |> String.split("@") |> List.first() || "user"

    # Use existing generate_unique_username function (defined below)
    username = if Map.has_key?(attrs, "username"), do: attrs["username"], else: generate_unique_username(base_name)
    display_name = if Map.has_key?(attrs, "display_name"), do: attrs["display_name"], else: base_name

    attrs
    |> Map.put("username", username)
    |> Map.put("display_name", display_name)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's status.
  """
  def update_user_status(user_id, status) do
    user = get_user!(user_id)
    user
    |> change_user(%{status: status})
    |> Repo.update()
    |> case do
      {:ok, updated_user} -> {:ok, updated_user}
      {:error, _changeset} -> {:error, :validation_error}
    end
  rescue
    Ecto.QueryError -> {:error, :user_not_found}
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Authenticates a user with email and password.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    case user do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Gets a user's public profile.
  """
  def get_public_profile(user_id) do
    case get_user!(user_id) do
      user ->
        # Only return public information
        %{
          id: user.id,
          username: user.username,
          display_name: user.display_name,
          avatar: user.avatar,
          profile_visibility: user.profile_visibility
        }
    end
  rescue
    Ecto.QueryError -> {:error, :not_found}
  end

  # OAuth User Management
  @doc """
  Finds or creates an OAuth user.
  """
  def find_or_create_oauth_user(auth, provider) do
    IO.puts "=== FIND OR CREATE OAUTH USER DEBUG ==="
    IO.puts "Provider: #{provider}"
    IO.puts "Auth UID: #{auth.uid}"
    IO.puts "Auth email: #{auth.info.email}"
    IO.puts "================================"

        # First check if user already exists with this OAuth provider
    case find_oauth_user(auth.uid, provider) do
      user when not is_nil(user) ->
        IO.puts "=== EXISTING OAUTH USER FOUND ==="
        IO.puts "User: #{inspect(user)}"
        IO.puts "================================"
        {:ok, user}
      nil ->
        IO.puts "=== NO EXISTING OAUTH USER, CHECKING EMAIL ==="
        # Check if user exists with the same email
        case Repo.get_by(User, email: auth.info.email) do
          existing_user when not is_nil(existing_user) ->
            IO.puts "=== EXISTING USER WITH EMAIL FOUND ==="
            IO.puts "User: #{inspect(existing_user)}"
            IO.puts "Linking OAuth provider..."
            IO.puts "================================"
            # User exists with same email, link the OAuth provider
            link_oauth_provider(existing_user.id, auth, provider)
          nil ->
            IO.puts "=== NO EXISTING USER, CREATING NEW ==="
            IO.puts "Email: #{auth.info.email}"
            IO.puts "================================"
            # No existing user, create new one
            create_oauth_user(auth, provider)
        end
    end
  end

  @doc """
  Finds a user by OAuth provider and UID.
  """
  def find_oauth_user(uid, provider) do
    IO.puts "=== FIND OAUTH USER DEBUG ==="
    IO.puts "Looking for provider: #{provider} (type: #{inspect(provider)})"
    IO.puts "Looking for UID: #{uid} (type: #{inspect(uid)})"

    # Let's also check what's actually in the database
    all_users = Repo.all(User)
    IO.puts "Total users in database: #{length(all_users)}"
    Enum.each(all_users, fn user ->
      IO.puts "User: #{user.username} - provider: #{inspect(user.provider)} - provider_uid: #{inspect(user.provider_uid)}"
    end)

    result = Repo.get_by(User, provider: provider, provider_uid: uid)
    IO.puts "Query result: #{inspect(result)}"
    IO.puts "================================"
    result
  end

  @doc """
  Creates a new OAuth user.
  """
  def create_oauth_user(auth, provider) do
    # Generate username from name or email
    username = generate_unique_username(auth.info.name || auth.info.email)

    # Use name if available, otherwise use email prefix
    display_name = case auth.info.name do
      nil ->
        email_prefix = auth.info.email |> String.split("@") |> List.first()
        email_prefix || "User"
      name -> name
    end

    # Convert Unix timestamp to DateTime if it exists
    expires_at = case auth.credentials.expires_at do
      nil -> nil
      timestamp when is_integer(timestamp) ->
        DateTime.from_unix!(timestamp)
      _ -> nil
    end

    attrs = %{
      email: auth.info.email,
      username: username,
      display_name: display_name,
      avatar: auth.info.image,
      provider: provider,
      provider_uid: auth.uid,
      provider_token: auth.credentials.token,
      provider_refresh_token: auth.credentials.refresh_token,
      provider_expires_at: expires_at,
      email_verified: true
    }

    %User{}
    |> User.oauth_registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Removes an OAuth provider association from a user.
  """
  def remove_oauth_provider(user_id, provider) do
    user = get_user!(user_id)

    # Only allow removal if user has password or other OAuth providers
    case can_remove_oauth_provider?(user, provider) do
      true ->
        attrs = %{
          provider: nil,
          provider_uid: nil,
          provider_token: nil,
          provider_refresh_token: nil,
          provider_expires_at: nil
        }

        case user
             |> User.changeset(attrs)
             |> Repo.update() do
          {:ok, updated_user} -> {:ok, updated_user}
          {:error, changeset} -> {:error, changeset}
        end

      false ->
        {:error, :cannot_remove_last_auth_method}
    end
  end

  @doc """
  Links an additional OAuth provider to an existing user.
  """
  def link_oauth_provider(user_id, auth, provider) do
    user = get_user!(user_id)

    # Check if provider is already linked
    case find_oauth_user(auth.uid, provider) do
      nil ->
        # Link the provider
        # Convert Unix timestamp to DateTime if it exists
        expires_at = case auth.credentials.expires_at do
          nil -> nil
          timestamp when is_integer(timestamp) ->
            DateTime.from_unix!(timestamp)
          _ -> nil
        end

        attrs = %{
          provider: provider,
          provider_uid: auth.uid,
          provider_token: auth.credentials.token,
          provider_refresh_token: auth.credentials.refresh_token,
          provider_expires_at: expires_at
        }

        case user
             |> User.changeset(attrs)
             |> Repo.update() do
          {:ok, updated_user} -> {:ok, updated_user}
          {:error, changeset} -> {:error, changeset}
        end

      _existing_user ->
        {:error, :provider_already_linked}
    end
  end

  @doc """
  Searches for users by username or display name.
  """
  def search_users(query, current_user_id) do
    search_term = "%#{query}%"

    # Get all matching users
    matching_users = Repo.all(
      from u in User,
      where: (ilike(u.username, ^search_term) or ilike(u.display_name, ^search_term)) and u.id != ^current_user_id,
      select: %{
        id: u.id,
        username: u.username,
        display_name: u.display_name,
        avatar: u.avatar
      },
      limit: 20
    )

    # Filter out users who are already friends
    existing_friend_ids = ButtonLog.Social.get_existing_friend_ids(current_user_id)

    matching_users
    |> Enum.reject(fn user -> user.id in existing_friend_ids end)
    |> Enum.take(10)
  end

  # Private helper functions
  defp generate_unique_username(name) do
    # Handle nil name by using email prefix or generating a default
    base_username = case name do
      nil -> "user"
      name when is_binary(name) -> name
      _ -> "user"
    end

    base_username = base_username
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
    |> String.slice(0, 20)

    # Ensure we have at least some username
    base_username = if String.length(base_username) == 0, do: "user", else: base_username

    case find_username(base_username) do
      nil -> base_username
      _ -> generate_unique_username_with_suffix(base_username)
    end
  end

  defp generate_unique_username_with_suffix(base_username) do
    suffix = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower) |> binary_part(0, 4)
    username = "#{base_username}_#{suffix}"

    case find_username(username) do
      nil -> username
      _ -> generate_unique_username_with_suffix(base_username)
    end
  end

  defp find_username(username) do
    Repo.get_by(User, username: username)
  end

  defp can_remove_oauth_provider?(user, provider) do
    # Check if this is the user's current provider
    if user.provider == provider do
      # Only allow removal if user has password or other OAuth providers
      user.password_hash != nil
    else
      true
    end
  end
end
