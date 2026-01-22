defmodule ButtonLog.Organizations.OrganizationSubscription do
  @moduledoc """
  Schema for organization subscriptions - org-level billing separate from user subscriptions.

  This enables seat-based pricing for enterprise customers where the organization
  pays for a number of seats, and members use those seats.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(active past_due cancelled trialing)
  @billing_cycles ~w(monthly yearly)

  schema "organization_subscriptions" do
    field :status, :string, default: "active"
    field :billing_cycle, :string, default: "monthly"
    field :current_period_start, :utc_datetime
    field :current_period_end, :utc_datetime
    field :trial_ends_at, :utc_datetime

    # Seat-based pricing
    field :seats_purchased, :integer, default: 5
    field :seats_used, :integer, default: 0
    field :price_per_seat, :decimal

    # Payment provider
    field :payment_provider, :string
    field :payment_provider_subscription_id, :string
    field :payment_provider_customer_id, :string

    # Cancellation
    field :cancelled_at, :utc_datetime
    field :cancel_at_period_end, :boolean, default: false

    belongs_to :organization, ButtonLog.Organizations.Organization
    belongs_to :plan, ButtonLog.Subscriptions.SubscriptionPlan

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :status, :billing_cycle,
      :current_period_start, :current_period_end, :trial_ends_at,
      :seats_purchased, :seats_used, :price_per_seat,
      :payment_provider, :payment_provider_subscription_id, :payment_provider_customer_id,
      :cancelled_at, :cancel_at_period_end
    ])
    |> validate_required([:status, :billing_cycle, :seats_purchased])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:billing_cycle, @billing_cycles)
    |> validate_number(:seats_purchased, greater_than: 0)
    |> validate_number(:seats_used, greater_than_or_equal_to: 0)
  end

  @doc false
  def create_changeset(subscription, attrs, organization_id, plan_id) do
    subscription
    |> changeset(attrs)
    |> put_change(:organization_id, organization_id)
    |> put_change(:plan_id, plan_id)
    |> put_change(:current_period_start, DateTime.utc_now() |> DateTime.truncate(:second))
    |> set_period_end()
    |> unique_constraint(:organization_id)
  end

  defp set_period_end(changeset) do
    billing_cycle = get_field(changeset, :billing_cycle)
    start = get_field(changeset, :current_period_start)

    if start do
      period_end = case billing_cycle do
        "yearly" -> DateTime.add(start, 365 * 24 * 60 * 60, :second)
        _ -> DateTime.add(start, 30 * 24 * 60 * 60, :second)
      end
      put_change(changeset, :current_period_end, period_end)
    else
      changeset
    end
  end

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns the list of valid billing cycles.
  """
  def billing_cycles, do: @billing_cycles

  @doc """
  Checks if the subscription is active.
  """
  def active?(%__MODULE__{status: status}), do: status in ["active", "trialing"]

  @doc """
  Checks if seats are available.
  """
  def seats_available?(%__MODULE__{} = sub) do
    sub.seats_used < sub.seats_purchased
  end

  @doc """
  Returns the number of available seats.
  """
  def available_seats(%__MODULE__{} = sub) do
    max(0, sub.seats_purchased - sub.seats_used)
  end
end
