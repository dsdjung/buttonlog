defmodule ButtonLog.Subscriptions.SubscriptionPlan do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscription_plans" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :price_monthly, :decimal
    field :price_yearly, :decimal
    field :currency, :string, default: "USD"
    field :is_active, :boolean, default: true
    field :sort_order, :integer, default: 0

    # Feature limits
    field :max_buttons, :integer
    field :max_friends, :integer
    field :max_button_clicks_per_month, :integer
    field :max_analytics_history_days, :integer
    field :max_export_history_days, :integer

    # Feature flags
    field :has_advanced_analytics, :boolean, default: false
    field :has_calendar_sync, :boolean, default: false
    field :has_api_access, :boolean, default: false
    field :has_priority_support, :boolean, default: false
    field :has_custom_themes, :boolean, default: false
    field :has_team_features, :boolean, default: false
    field :has_white_label, :boolean, default: false

    # Trial settings
    field :trial_days, :integer, default: 0
    field :trial_requires_credit_card, :boolean, default: false

    timestamps()
  end

  def changeset(subscription_plan, attrs) do
    subscription_plan
    |> cast(attrs, [:name, :slug, :description, :price_monthly, :price_yearly, :currency,
                    :is_active, :sort_order, :max_buttons, :max_friends,
                    :max_button_clicks_per_month, :max_analytics_history_days, :max_export_history_days,
                    :has_advanced_analytics, :has_calendar_sync, :has_api_access,
                    :has_priority_support, :has_custom_themes, :has_team_features, :has_white_label,
                    :trial_days, :trial_requires_credit_card])
    |> validate_required([:name, :slug, :price_monthly, :price_yearly])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:slug, min: 1, max: 50)
    |> validate_length(:description, max: 500)
    |> validate_number(:price_monthly, greater_than_or_equal_to: 0)
    |> validate_number(:price_yearly, greater_than_or_equal_to: 0)
    |> validate_number(:max_buttons, greater_than: 0)
    |> validate_number(:max_friends, greater_than_or_equal_to: 0)
    |> validate_number(:max_button_clicks_per_month, greater_than: 0)
    |> validate_number(:max_analytics_history_days, greater_than: 0)
    |> validate_number(:max_export_history_days, greater_than: 0)
    |> validate_number(:trial_days, greater_than_or_equal_to: 0)
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP", "CAD", "AUD"])
    |> unique_constraint(:slug)
    |> unique_constraint(:sort_order)
  end

  # Predefined subscription plans
  def free_plan do
    %__MODULE__{
      name: "Free",
      slug: "free",
      description: "Perfect for getting started with ButtonLog",
      price_monthly: Decimal.new(0),
      price_yearly: Decimal.new(0),
      max_buttons: 5,
      max_friends: 10,
      max_button_clicks_per_month: 1000,
      max_analytics_history_days: 30,
      max_export_history_days: 30,
      has_advanced_analytics: false,
      has_calendar_sync: false,
      has_api_access: false,
      has_priority_support: false,
      has_custom_themes: false,
      has_team_features: false,
      has_white_label: false,
      trial_days: 0,
      trial_requires_credit_card: false,
      sort_order: 1
    }
  end

  def premium_plan do
    %__MODULE__{
      name: "Premium",
      slug: "premium",
      description: "Advanced features for power users",
      price_monthly: Decimal.new("9.99"),
      price_yearly: Decimal.new("99.99"),
      max_buttons: 50,
      max_friends: 100,
      max_button_clicks_per_month: 10000,
      max_analytics_history_days: 365,
      max_export_history_days: 365,
      has_advanced_analytics: true,
      has_calendar_sync: true,
      has_api_access: true,
      has_priority_support: false,
      has_custom_themes: true,
      has_team_features: false,
      has_white_label: false,
      trial_days: 14,
      trial_requires_credit_card: true,
      sort_order: 2
    }
  end

  def enterprise_plan do
    %__MODULE__{
      name: "Enterprise",
      slug: "enterprise",
      description: "Full-featured solution for teams and organizations",
      price_monthly: Decimal.new("29.99"),
      price_yearly: Decimal.new("299.99"),
      max_buttons: -1, # Unlimited
      max_friends: -1, # Unlimited
      max_button_clicks_per_month: -1, # Unlimited
      max_analytics_history_days: -1, # Unlimited
      max_export_history_days: -1, # Unlimited
      has_advanced_analytics: true,
      has_calendar_sync: true,
      has_api_access: true,
      has_priority_support: true,
      has_custom_themes: true,
      has_team_features: true,
      has_white_label: true,
      trial_days: 30,
      trial_requires_credit_card: true,
      sort_order: 3
    }
  end

  # Helper functions
  def is_unlimited(value) when is_integer(value), do: value == -1
  def is_unlimited(_), do: false

  def has_feature(plan, feature) do
    case feature do
      :advanced_analytics -> plan.has_advanced_analytics
      :calendar_sync -> plan.has_calendar_sync
      :api_access -> plan.has_api_access
      :priority_support -> plan.has_priority_support
      :custom_themes -> plan.has_custom_themes
      :team_features -> plan.has_team_features
      :white_label -> plan.has_white_label
      _ -> false
    end
  end

  def can_create_button(plan, current_button_count) do
    is_unlimited(plan.max_buttons) or current_button_count < plan.max_buttons
  end

  def can_add_friend(plan, current_friend_count) do
    is_unlimited(plan.max_friends) or current_friend_count < plan.max_friends
  end

  def can_click_button(plan, current_monthly_clicks) do
    is_unlimited(plan.max_button_clicks_per_month) or current_monthly_clicks < plan.max_button_clicks_per_month
  end

  def can_access_analytics(plan, days_back) do
    is_unlimited(plan.max_analytics_history_days) or days_back <= plan.max_analytics_history_days
  end

  def can_export_data(plan, days_back) do
    is_unlimited(plan.max_export_history_days) or days_back <= plan.max_export_history_days
  end
end

