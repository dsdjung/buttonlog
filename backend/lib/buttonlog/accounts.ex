defmodule ButtonLog.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Accounts.User
  alias ButtonLog.Accounts.OAuthCredential

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
  Uses the oauth_credentials table to support multiple providers per user.
  """
  def find_or_create_oauth_user(auth, provider) do
    # First check if user already exists with this OAuth provider (new table)
    case find_oauth_user(auth.uid, provider) do
      user when not is_nil(user) ->
        # Update the OAuth credentials in case token changed
        update_oauth_credentials(user.id, auth, provider)
        {:ok, user}

      nil ->
        # Check legacy users table for backwards compatibility
        case find_oauth_user_legacy(auth.uid, provider) do
          user when not is_nil(user) ->
            # Migrate legacy OAuth data to new table
            migrate_oauth_to_credentials(user, auth, provider)
            {:ok, user}

          nil ->
            # Check if user exists with the same email
            case Repo.get_by(User, email: auth.info.email) do
              existing_user when not is_nil(existing_user) ->
                # User exists with same email, link the OAuth provider
                link_oauth_provider(existing_user.id, auth, provider)

              nil ->
                # No existing user, create new one
                create_oauth_user(auth, provider)
            end
        end
    end
  end

  @doc """
  Finds a user by OAuth provider and UID using the new oauth_credentials table.
  """
  def find_oauth_user(uid, provider) do
    query = from c in OAuthCredential,
      where: c.provider == ^provider and c.provider_uid == ^uid,
      join: u in User, on: u.id == c.user_id,
      select: u

    Repo.one(query)
  end

  @doc """
  Finds a user by OAuth provider and UID using the legacy users table fields.
  For backwards compatibility during migration.
  """
  def find_oauth_user_legacy(uid, provider) do
    Repo.get_by(User, provider: provider, provider_uid: uid)
  end

  @doc """
  Gets all OAuth providers linked to a user.
  """
  def get_user_oauth_providers(user_id) do
    Repo.all(
      from c in OAuthCredential,
      where: c.user_id == ^user_id,
      select: %{provider: c.provider, provider_uid: c.provider_uid}
    )
  end

  @doc """
  Checks if a user has a specific OAuth provider linked.
  """
  def has_oauth_provider?(user_id, provider) do
    query = from c in OAuthCredential,
      where: c.user_id == ^user_id and c.provider == ^provider

    Repo.exists?(query)
  end

  @doc """
  Creates a new OAuth user with credentials in the new table.
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

    # User attributes (without OAuth fields in the user table itself)
    user_attrs = %{
      email: auth.info.email,
      username: username,
      display_name: display_name,
      avatar: auth.info.image,
      email_verified: true,
      # Keep legacy fields for backwards compatibility
      provider: provider,
      provider_uid: auth.uid
    }

    Repo.transaction(fn ->
      # Create the user
      case %User{}
           |> User.oauth_registration_changeset(user_attrs)
           |> Repo.insert() do
        {:ok, user} ->
          # Create the OAuth credential
          case create_oauth_credential(user.id, auth, provider) do
            {:ok, _credential} -> user
            {:error, reason} -> Repo.rollback(reason)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Removes an OAuth provider association from a user.
  Now removes from oauth_credentials table.
  """
  def remove_oauth_provider(user_id, provider) do
    user = get_user!(user_id)

    # Check if removal is allowed
    case can_remove_oauth_provider?(user, provider) do
      true ->
        # Remove from oauth_credentials table
        query = from c in OAuthCredential,
          where: c.user_id == ^user_id and c.provider == ^provider

        case Repo.delete_all(query) do
          {count, _} when count > 0 ->
            # Also clear legacy fields if they match
            if user.provider == provider do
              user
              |> User.changeset(%{
                provider: nil,
                provider_uid: nil,
                provider_token: nil,
                provider_refresh_token: nil,
                provider_expires_at: nil
              })
              |> Repo.update()
            else
              {:ok, user}
            end

          _ ->
            {:error, :provider_not_found}
        end

      false ->
        {:error, :cannot_remove_last_auth_method}
    end
  end

  @doc """
  Links an additional OAuth provider to an existing user.
  Now uses oauth_credentials table to support multiple providers.
  """
  def link_oauth_provider(user_id, auth, provider) do
    user = get_user!(user_id)

    # Check if provider is already linked to ANY user
    case find_oauth_user(auth.uid, provider) do
      nil ->
        # Not linked to anyone, create the credential
        case create_oauth_credential(user_id, auth, provider) do
          {:ok, _credential} -> {:ok, user}
          {:error, changeset} -> {:error, changeset}
        end

      existing_user when existing_user.id == user_id ->
        # Already linked to this user, just update tokens
        update_oauth_credentials(user_id, auth, provider)
        {:ok, user}

      _other_user ->
        {:error, :provider_already_linked_to_another_user}
    end
  end

  @doc """
  Creates an OAuth credential entry.
  """
  def create_oauth_credential(user_id, auth, provider) do
    expires_at = parse_expires_at(auth.credentials.expires_at)

    attrs = %{
      user_id: user_id,
      provider: provider,
      provider_uid: auth.uid,
      provider_token: auth.credentials.token,
      provider_refresh_token: auth.credentials.refresh_token,
      provider_expires_at: expires_at
    }

    %OAuthCredential{}
    |> OAuthCredential.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates OAuth credentials for an existing user-provider link.
  """
  def update_oauth_credentials(user_id, auth, provider) do
    expires_at = parse_expires_at(auth.credentials.expires_at)

    query = from c in OAuthCredential,
      where: c.user_id == ^user_id and c.provider == ^provider

    case Repo.one(query) do
      nil ->
        # Credential doesn't exist, create it
        create_oauth_credential(user_id, auth, provider)

      credential ->
        credential
        |> OAuthCredential.changeset(%{
          provider_token: auth.credentials.token,
          provider_refresh_token: auth.credentials.refresh_token,
          provider_expires_at: expires_at
        })
        |> Repo.update()
    end
  end

  @doc """
  Migrates legacy OAuth data from users table to oauth_credentials.
  """
  def migrate_oauth_to_credentials(user, auth, provider) do
    # Check if credential already exists
    unless has_oauth_provider?(user.id, provider) do
      create_oauth_credential(user.id, auth, provider)
    end
  end

  defp parse_expires_at(nil), do: nil
  defp parse_expires_at(timestamp) when is_integer(timestamp), do: DateTime.from_unix!(timestamp)
  defp parse_expires_at(_), do: nil

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

  defp can_remove_oauth_provider?(user, _provider) do
    # Count how many OAuth providers the user has
    oauth_count = Repo.one(
      from c in OAuthCredential,
      where: c.user_id == ^user.id,
      select: count(c.id)
    )

    # User can remove provider if they have:
    # 1. A password, OR
    # 2. More than one OAuth provider linked
    cond do
      user.password_hash != nil -> true
      oauth_count > 1 -> true
      true -> false
    end
  end
end
