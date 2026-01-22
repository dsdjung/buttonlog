defmodule ButtonLog.NotificationsWebhook.UserNotificationSettings do
  @moduledoc """
  Schema for account-level webhook notification settings.
  These are the default settings for sending button click data to external endpoints.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_notification_settings" do
    field :default_webhook_url, :string
    field :default_webhook_enabled, :boolean, default: false
    field :webhook_secret, :string
    field :retry_failed, :boolean, default: true
    field :max_retries, :integer, default: 3

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :default_webhook_url,
      :default_webhook_enabled,
      :webhook_secret,
      :retry_failed,
      :max_retries
    ])
    |> validate_url(:default_webhook_url)
    |> validate_number(:max_retries, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
  end

  def create_changeset(settings, attrs, user_id) do
    settings
    |> changeset(attrs)
    |> put_change(:user_id, user_id)
    |> unique_constraint(:user_id)
  end

  # Custom URL validation
  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case url do
        nil ->
          []

        url when is_binary(url) ->
          case URI.parse(url) do
            %URI{scheme: scheme, host: host}
            when scheme in ["http", "https"] and not is_nil(host) ->
              []

            _ ->
              [{field, "must be a valid HTTP or HTTPS URL"}]
          end

        _ ->
          [{field, "must be a string"}]
      end
    end)
  end
end
