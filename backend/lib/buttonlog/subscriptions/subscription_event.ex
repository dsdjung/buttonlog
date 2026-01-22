defmodule ButtonLog.Subscriptions.SubscriptionEvent do
  @moduledoc """
  Schema for subscription audit events.

  Tracks all changes to subscriptions for audit and debugging purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @event_types [
    :created,
    :activated,
    :trial_started,
    :trial_ended,
    :plan_changed,
    :renewed,
    :payment_succeeded,
    :payment_failed,
    :canceled,
    :reactivated,
    :paused,
    :resumed,
    :expired
  ]

  schema "subscription_events" do
    field :event_type, Ecto.Enum, values: @event_types
    field :event_data, :map
    field :occurred_at, :utc_datetime

    belongs_to :user_subscription, ButtonLog.Subscriptions.UserSubscription

    timestamps()
  end

  @doc false
  def changeset(subscription_event, attrs) do
    subscription_event
    |> cast(attrs, [:user_subscription_id, :event_type, :event_data, :occurred_at])
    |> validate_required([:user_subscription_id, :event_type, :occurred_at])
    |> validate_inclusion(:event_type, @event_types)
    |> foreign_key_constraint(:user_subscription_id)
  end

  @doc """
  Creates a new subscription event.
  """
  def new(subscription_id, event_type, event_data \\ %{}) do
    %__MODULE__{
      user_subscription_id: subscription_id,
      event_type: event_type,
      event_data: event_data,
      occurred_at: DateTime.utc_now()
    }
  end
end
