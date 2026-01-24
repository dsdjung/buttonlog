defmodule ButtonLog.Repo.Migrations.AddScalabilityIndexes do
  use Ecto.Migration

  @moduledoc """
  Adds composite indexes for common query patterns to improve performance at scale.
  These indexes support the most frequent access patterns without requiring
  table restructuring.
  """

  def change do
    # Button clicks - most frequently queried table
    # Supports: "Show me clicks for this button, newest first"
    create_if_not_exists index(:button_clicks, [:button_id, :clicked_at],
      name: :button_clicks_button_id_clicked_at_idx)

    # Supports: "Show me all clicks by this user, newest first"
    create_if_not_exists index(:button_clicks, [:user_id, :clicked_at],
      name: :button_clicks_user_id_clicked_at_idx)

    # Alerts - for notification feed
    # Supports: "Show me unread alerts for this user, newest first"
    # Partial index only on unread alerts for efficiency
    create_if_not_exists index(:alerts, [:recipient_id, :inserted_at],
      where: "read = false",
      name: :alerts_recipient_unread_idx)

    # Supports: "Show me all alerts for this user, newest first"
    create_if_not_exists index(:alerts, [:recipient_id, :inserted_at],
      name: :alerts_recipient_time_idx)

    # Friendships - for friend list queries
    # Supports: "Show me accepted friends for this user"
    create_if_not_exists index(:friendships, [:user_id, :status],
      where: "status = 'accepted'",
      name: :friendships_user_accepted_idx)

    create_if_not_exists index(:friendships, [:friend_id, :status],
      where: "status = 'accepted'",
      name: :friendships_friend_accepted_idx)

    # Buttons - for user's button list
    # Supports: "Show me active buttons for this user"
    create_if_not_exists index(:buttons, [:user_id, :is_active],
      where: "is_active = true",
      name: :buttons_user_active_idx)

    # Mobile connections - for push notifications
    # Supports: "Find active devices for this user"
    create_if_not_exists index(:mobile_connections, [:user_id, :is_active],
      where: "is_active = true",
      name: :mobile_connections_user_active_idx)
  end
end
