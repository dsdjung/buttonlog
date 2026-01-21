defmodule ButtonLog.Subscriptions.UserSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_subscriptions" do
    field :status, Ecto.Enum, values: [:active, :canceled, :past_due, :unpaid, :trialing, :paused]
    field :current_period_start, :utc_datetime
    field :current_period_end, :utc_datetime
    field :trial_start, :utc_datetime
    field :trial_end, :utc_datetime
    field :canceled_at, :utc_datetime
    field :paused_at, :utc_datetime

    # Billing information
    field :billing_cycle, Ecto.Enum, values: [:monthly, :yearly]
    field :amount, :decimal
    field :currency, :string, default: "USD"
    field :next_billing_date, :utc_datetime

    # Payment provider details
    field :payment_provider, :string # "stripe", "paypal", etc.
    field :payment_provider_subscription_id, :string
    field :payment_provider_customer_id, :string

    # Usage tracking
    field :buttons_used, :integer, default: 0
    field :friends_used, :integer, default: 0
    field :clicks_this_month, :integer, default: 0
    field :last_usage_reset, :utc_datetime

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :subscription_plan, ButtonLog.Subscriptions.SubscriptionPlan

    # Subscription history
    has_many :subscription_events, ButtonLog.Subscriptions.SubscriptionEvent
    has_many :billing_events, ButtonLog.Subscriptions.BillingEvent

    timestamps()
  end

  def changeset(user_subscription, attrs) do
    user_subscription
    |> cast(attrs, [:status, :current_period_start, :current_period_end, :trial_start, :trial_end,
                    :canceled_at, :paused_at, :billing_cycle, :amount, :currency, :next_billing_date,
                    :payment_provider, :payment_provider_subscription_id, :payment_provider_customer_id,
                    :buttons_used, :friends_used, :clicks_this_month, :last_usage_reset, :user_id, :subscription_plan_id])
    |> validate_required([:status, :billing_cycle, :amount, :user_id, :subscription_plan_id])
    |> validate_inclusion(:status, [:active, :canceled, :past_due, :unpaid, :trialing, :paused])
    |> validate_inclusion(:billing_cycle, [:monthly, :yearly])
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP", "CAD", "AUD"])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:buttons_used, greater_than_or_equal_to: 0)
    |> validate_number(:friends_used, greater_than_or_equal_to: 0)
    |> validate_number(:clicks_this_month, greater_than_or_equal_to: 0)
    |> validate_dates()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:subscription_plan_id)
  end

  defp validate_dates(changeset) do
    changeset
    |> validate_trial_dates()
    |> validate_period_dates()
  end

  defp validate_trial_dates(changeset) do
    case {get_field(changeset, :trial_start), get_field(changeset, :trial_end)} do
      {trial_start, trial_end} when not is_nil(trial_start) and not is_nil(trial_end) ->
        if DateTime.compare(trial_start, trial_end) == :gt do
          add_error(changeset, :trial_end, "Trial end must be after trial start")
        else
          changeset
        end
      _ ->
        changeset
    end
  end

  defp validate_period_dates(changeset) do
    case {get_field(changeset, :current_period_start), get_field(changeset, :current_period_end)} do
      {period_start, period_end} when not is_nil(period_start) and not is_nil(period_end) ->
        if DateTime.compare(period_start, period_end) == :gt do
          add_error(changeset, :current_period_end, "Period end must be after period start")
        else
          changeset
        end
      _ ->
        changeset
    end
  end

  # Helper functions
  def is_active?(subscription) do
    subscription.status in [:active, :trialing]
  end

  def is_trialing?(subscription) do
    subscription.status == :trialing
  end

  def is_canceled?(subscription) do
    subscription.status == :canceled
  end

  def is_paused?(subscription) do
    subscription.status == :paused
  end

  def days_until_trial_end(subscription) do
    case subscription.trial_end do
      nil -> nil
      trial_end ->
        now = DateTime.utc_now()
        case DateTime.compare(now, trial_end) do
          :gt -> 0
          _ ->
            diff = DateTime.diff(trial_end, now, :day)
            max(0, diff)
        end
    end
  end

  def days_until_period_end(subscription) do
    case subscription.current_period_end do
      nil -> nil
      period_end ->
        now = DateTime.utc_now()
        case DateTime.compare(now, period_end) do
          :gt -> 0
          _ ->
            diff = DateTime.diff(period_end, now, :day)
            max(0, diff)
        end
    end
  end

  def should_reset_monthly_usage(subscription) do
    case subscription.last_usage_reset do
      nil -> true
      last_reset ->
        now = DateTime.utc_now()
        last_reset_month = DateTime.truncate(last_reset, :month)
        current_month = DateTime.truncate(now, :month)
        DateTime.compare(last_reset_month, current_month) == :lt
    end
  end

  def reset_monthly_usage(subscription) do
    %{subscription |
      clicks_this_month: 0,
      last_usage_reset: DateTime.utc_now()
    }
  end

  def increment_button_usage(subscription) do
    %{subscription | buttons_used: subscription.buttons_used + 1}
  end

  def increment_friend_usage(subscription) do
    %{subscription | friends_used: subscription.friends_used + 1}
  end

  def increment_click_usage(subscription) do
    %{subscription | clicks_this_month: subscription.clicks_this_month + 1}
  end

  def can_create_button(subscription, plan) do
    is_active?(subscription) and
    (plan.max_buttons == -1 or subscription.buttons_used < plan.max_buttons)
  end

  def can_add_friend(subscription, plan) do
    is_active?(subscription) and
    (plan.max_friends == -1 or subscription.friends_used < plan.max_friends)
  end

  def can_click_button(subscription, plan) do
    is_active?(subscription) and
    (plan.max_button_clicks_per_month == -1 or subscription.clicks_this_month < plan.max_button_clicks_per_month)
  end
end

