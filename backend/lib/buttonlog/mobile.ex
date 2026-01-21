defmodule ButtonLog.Mobile do
  @moduledoc """
  The Mobile context.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo
  alias ButtonLog.Mobile.Connection

  @doc """
  Returns the list of mobile connections for a user.
  """
  def list_user_connections(user_id) do
    Repo.all(
      from c in Connection,
      where: c.user_id == ^user_id and c.is_active == true,
      order_by: [desc: c.last_seen_at]
    )
  end

  @doc """
  Gets a single mobile connection.
  """
  def get_connection!(id), do: Repo.get!(Connection, id)

  @doc """
  Gets a connection by device token.
  """
  def get_connection_by_token(device_token) do
    Repo.get_by(Connection, device_token: device_token)
  end

  @doc """
  Creates a mobile connection.
  """
  def create_connection(attrs \\ %{}, user_id) do
    %Connection{}
    |> Connection.create_changeset(attrs, user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a mobile connection.
  """
  def update_connection(%Connection{} = connection, attrs) do
    connection
    |> Connection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the last seen timestamp for a connection.
  """
  def update_connection_last_seen(connection_id) do
    case get_connection!(connection_id) do
      connection ->
        connection
        |> Connection.update_last_seen_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Deactivates a mobile connection.
  """
  def deactivate_connection(connection_id) do
    case get_connection!(connection_id) do
      connection ->
        connection
        |> Connection.changeset(%{is_active: false})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a mobile connection.
  """
  def delete_connection(%Connection{} = connection) do
    Repo.delete(connection)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking connection changes.
  """
  def change_connection(%Connection{} = connection, attrs \\ %{}) do
    Connection.changeset(connection, attrs)
  end

  @doc """
  Registers a new mobile device.
  """
  def register_device(attrs, user_id) do
    # Check if device token already exists
    case get_connection_by_token(attrs.device_token) do
      nil ->
        # Create new connection
        create_connection(attrs, user_id)

      existing_connection ->
        # Update existing connection
        existing_connection
        |> Connection.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Gets all active connections for a user.
  """
  def get_active_connections(user_id) do
    Repo.all(
      from c in Connection,
      where: c.user_id == ^user_id and c.is_active == true
    )
  end

  @doc """
  Gets connections by platform.
  """
  def get_connections_by_platform(user_id, platform) do
    Repo.all(
      from c in Connection,
      where: c.user_id == ^user_id and c.platform == ^platform and c.is_active == true
    )
  end
end


