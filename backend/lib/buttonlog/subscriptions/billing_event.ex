defmodule ButtonLog.Subscriptions.BillingEvent do
  @moduledoc """
  Schema for billing/payment events.

  Tracks all payment-related events from Stripe and other providers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @event_types [
    :payment_created,
    :payment_pending,
    :payment_succeeded,
    :payment_failed,
    :payment_refunded,
    :payment_disputed,
    :invoice_created,
    :invoice_paid,
    :invoice_payment_failed,
    :invoice_voided
  ]

  @statuses [:pending, :succeeded, :failed, :refunded, :disputed]

  schema "billing_events" do
    field :event_type, Ecto.Enum, values: @event_types
    field :amount, :decimal
    field :currency, :string, default: "USD"
    field :payment_provider, :string
    field :payment_provider_event_id, :string
    field :status, Ecto.Enum, values: @statuses
    field :occurred_at, :utc_datetime
    field :metadata, :map

    belongs_to :user_subscription, ButtonLog.Subscriptions.UserSubscription

    timestamps()
  end

  @doc false
  def changeset(billing_event, attrs) do
    billing_event
    |> cast(attrs, [
      :user_subscription_id, :event_type, :amount, :currency,
      :payment_provider, :payment_provider_event_id, :status,
      :occurred_at, :metadata
    ])
    |> validate_required([:user_subscription_id, :event_type, :status, :occurred_at])
    |> validate_inclusion(:event_type, @event_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP", "CAD", "AUD"])
    |> foreign_key_constraint(:user_subscription_id)
  end

  @doc """
  Creates a new billing event.
  """
  def new(subscription_id, event_type, status, attrs \\ %{}) do
    %__MODULE__{
      user_subscription_id: subscription_id,
      event_type: event_type,
      status: status,
      occurred_at: DateTime.utc_now()
    }
    |> Map.merge(Map.take(attrs, [:amount, :currency, :payment_provider, :payment_provider_event_id, :metadata]))
  end
end
