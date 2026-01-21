defmodule ButtonLog.Repo.Migrations.CreateSubscriptionSystem do
  use Ecto.Migration

  def change do
    # Create subscription_plans table
    create table(:subscription_plans, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :price_monthly, :decimal, precision: 10, scale: 2, null: false
      add :price_yearly, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, default: "USD", null: false
      add :is_active, :boolean, default: true, null: false
      add :sort_order, :integer, default: 0, null: false

      # Feature limits
      add :max_buttons, :integer, null: false
      add :max_friends, :integer, null: false
      add :max_button_clicks_per_month, :integer, null: false
      add :max_analytics_history_days, :integer, null: false
      add :max_export_history_days, :integer, null: false

      # Feature flags
      add :has_advanced_analytics, :boolean, default: false, null: false
      add :has_calendar_sync, :boolean, default: false, null: false
      add :has_api_access, :boolean, default: false, null: false
      add :has_priority_support, :boolean, default: false, null: false
      add :has_custom_themes, :boolean, default: false, null: false
      add :has_team_features, :boolean, default: false, null: false
      add :has_white_label, :boolean, default: false, null: false

      # Trial settings
      add :trial_days, :integer, default: 0, null: false
      add :trial_requires_credit_card, :boolean, default: false, null: false

      timestamps()
    end

    # Create user_subscriptions table
    create table(:user_subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :subscription_plan_id, references(:subscription_plans, type: :uuid, on_delete: :restrict), null: false

      add :status, :string, null: false
      add :current_period_start, :utc_datetime
      add :current_period_end, :utc_datetime
      add :trial_start, :utc_datetime
      add :trial_end, :utc_datetime
      add :canceled_at, :utc_datetime
      add :paused_at, :utc_datetime

      # Billing information
      add :billing_cycle, :string, null: false
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, default: "USD", null: false
      add :next_billing_date, :utc_datetime

      # Payment provider details
      add :payment_provider, :string
      add :payment_provider_subscription_id, :string
      add :payment_provider_customer_id, :string

      # Usage tracking
      add :buttons_used, :integer, default: 0, null: false
      add :friends_used, :integer, default: 0, null: false
      add :clicks_this_month, :integer, default: 0, null: false
      add :last_usage_reset, :utc_datetime

      timestamps()
    end

    # Create subscription_events table for audit trail
    create table(:subscription_events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_subscription_id, references(:user_subscriptions, type: :uuid, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :event_data, :map
      add :occurred_at, :utc_datetime, null: false

      timestamps()
    end

    # Create billing_events table for payment tracking
    create table(:billing_events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_subscription_id, references(:user_subscriptions, type: :uuid, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :amount, :decimal, precision: 10, scale: 2
      add :currency, :string, default: "USD"
      add :payment_provider, :string
      add :payment_provider_event_id, :string
      add :status, :string, null: false
      add :occurred_at, :utc_datetime, null: false
      add :metadata, :map

      timestamps()
    end

    # Create indexes
    create unique_index(:subscription_plans, [:slug])
    create unique_index(:subscription_plans, [:sort_order])
    create index(:subscription_plans, [:is_active])

    create index(:user_subscriptions, [:user_id])
    create index(:user_subscriptions, [:status])
    create index(:user_subscriptions, [:subscription_plan_id])
    create index(:user_subscriptions, [:payment_provider_subscription_id])
    create index(:user_subscriptions, [:current_period_end])
    create index(:user_subscriptions, [:trial_end])

    create index(:subscription_events, [:user_subscription_id])
    create index(:subscription_events, [:event_type])
    create index(:subscription_events, [:occurred_at])

    create index(:billing_events, [:user_subscription_id])
    create index(:billing_events, [:event_type])
    create index(:billing_events, [:status])
    create index(:billing_events, [:occurred_at])

    # Insert default subscription plans
    execute """
    INSERT INTO subscription_plans (
      id, name, slug, description, price_monthly, price_yearly, currency,
      max_buttons, max_friends, max_button_clicks_per_month,
      max_analytics_history_days, max_export_history_days,
      has_advanced_analytics, has_calendar_sync, has_api_access,
      has_priority_support, has_custom_themes, has_team_features, has_white_label,
      trial_days, trial_requires_credit_card, sort_order, inserted_at, updated_at
    ) VALUES
    (
      gen_random_uuid(), 'Free', 'free', 'Perfect for getting started with ButtonLog',
      0.00, 0.00, 'USD', 5, 10, 1000, 30, 30,
      false, false, false, false, false, false, false,
      0, false, 1, NOW(), NOW()
    ),
    (
      gen_random_uuid(), 'Premium', 'premium', 'Advanced features for power users',
      9.99, 99.99, 'USD', 50, 100, 10000, 365, 365,
      true, true, true, false, true, false, false,
      14, true, 2, NOW(), NOW()
    ),
    (
      gen_random_uuid(), 'Enterprise', 'enterprise', 'Full-featured solution for teams and organizations',
      29.99, 299.99, 'USD', -1, -1, -1, -1, -1,
      true, true, true, true, true, true, true,
      30, true, 3, NOW(), NOW()
    );
    """
  end

  def down do
    drop table(:billing_events)
    drop table(:subscription_events)
    drop table(:user_subscriptions)
    drop table(:subscription_plans)
  end
end

