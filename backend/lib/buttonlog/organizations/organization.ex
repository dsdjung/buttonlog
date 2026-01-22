defmodule ButtonLog.Organizations.Organization do
  @moduledoc """
  Schema for organizations - top-level enterprise entity that can contain
  multiple teams and have organization-level subscriptions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(active suspended cancelled)

  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :logo_url, :string
    field :website, :string

    # Enterprise features
    field :domain, :string
    field :sso_enabled, :boolean, default: false
    field :require_sso, :boolean, default: false

    # Settings
    field :allow_personal_teams, :boolean, default: true
    field :default_team_role, :string, default: "member"

    # Billing
    field :billing_email, :string
    field :billing_address, :map, default: %{}
    field :tax_id, :string

    # Limits
    field :max_seats, :integer
    field :max_teams, :integer

    # Status
    field :status, :string, default: "active"

    has_many :members, ButtonLog.Organizations.OrganizationMember
    has_many :users, through: [:members, :user]
    has_many :teams, ButtonLog.Teams.Team
    has_many :invitations, ButtonLog.Organizations.OrganizationInvitation
    has_one :subscription, ButtonLog.Organizations.OrganizationSubscription
    has_many :audit_logs, ButtonLog.Organizations.OrganizationAuditLog

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :name, :slug, :description, :logo_url, :website,
      :domain, :sso_enabled, :require_sso,
      :allow_personal_teams, :default_team_role,
      :billing_email, :billing_address, :tax_id,
      :max_seats, :max_teams, :status
    ])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:slug, min: 2, max: 50)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must contain only lowercase letters, numbers, and hyphens")
    |> validate_inclusion(:status, @statuses)
    |> validate_format(:domain, ~r/^[a-z0-9.-]+\.[a-z]{2,}$/i, message: "must be a valid domain")
    |> validate_format(:billing_email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:slug)
    |> unique_constraint(:domain)
  end

  @doc false
  def create_changeset(organization, attrs) do
    # Generate slug before validation if not provided
    attrs = maybe_add_slug(attrs)

    organization
    |> changeset(attrs)
  end

  defp maybe_add_slug(attrs) do
    # Handle both atom and string keys
    slug = Map.get(attrs, :slug) || Map.get(attrs, "slug")
    name = Map.get(attrs, :name) || Map.get(attrs, "name")

    if is_nil(slug) && name do
      generated_slug = name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

      # Return with the same key type as the original
      if is_atom(List.first(Map.keys(attrs) |> Enum.take(1))) do
        Map.put(attrs, :slug, generated_slug)
      else
        Map.put(attrs, "slug", generated_slug)
      end
    else
      attrs
    end
  end

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Checks if the organization is active.
  """
  def active?(%__MODULE__{status: status}), do: status == "active"
end
