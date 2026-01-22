defmodule ButtonLog.NotificationsWebhook.ButtonNotificationSettings do
  @moduledoc """
  Schema for per-button webhook notification settings.
  These settings override the account-level defaults for a specific button.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "button_notification_settings" do
    field :webhook_url, :string
    field :webhook_enabled, :boolean
    field :include_metadata, :boolean, default: true

    # Relationships
    belongs_to :button, ButtonLog.Buttons.Button

    timestamps()
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:webhook_url, :webhook_enabled, :include_metadata])
    |> validate_url(:webhook_url)
  end

  def create_changeset(settings, attrs, button_id) do
    settings
    |> changeset(attrs)
    |> put_change(:button_id, button_id)
    |> unique_constraint(:button_id)
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
