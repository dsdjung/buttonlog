defmodule ButtonLog.Subscriptions.SubscriptionService do
  @moduledoc """
  Service for managing user subscriptions, checking feature access,
  and tracking usage limits.
  """

  alias ButtonLog.Subscriptions.{SubscriptionPlan, UserSubscription}
  alias ButtonLog.Repo
  import Ecto.Query

  @doc """
  Get the current subscription plan for a user.
  Returns the plan with usage information.
  """
  def get_user_subscription(user_id) do
    query = from us in UserSubscription,
      join: sp in SubscriptionPlan, on: us.subscription_plan_id == sp.id,
      where: us.user_id == ^user_id and us.status in [:active, :trialing],
      order_by: [desc: us.inserted_at],
      limit: 1,
      preload: [subscription_plan: sp]

    case Repo.one(query) do
      nil ->
        # Return free plan for users without subscription
        %{plan: SubscriptionPlan.free_plan(), usage: %{}}
      subscription ->
        # Check if monthly usage should be reset
        subscription = maybe_reset_monthly_usage(subscription)

        %{
          plan: subscription.subscription_plan,
          subscription: subscription,
          usage: %{
            buttons_used: subscription.buttons_used,
            friends_used: subscription.friends_used,
            clicks_this_month: subscription.clicks_this_month,
            days_until_trial_end: UserSubscription.days_until_trial_end(subscription),
            days_until_period_end: UserSubscription.days_until_period_end(subscription)
          }
        }
    end
  end

  @doc """
  Check if a user can perform a specific action based on their subscription.
  """
  def can_perform_action(user_id, action, context \\ %{}) do
    case get_user_subscription(user_id) do
      %{plan: plan, subscription: subscription} when not is_nil(subscription) ->
        check_action_permission(plan, subscription, action, context)
      %{plan: plan} ->
        # Free plan user
        check_action_permission(plan, nil, action, context)
    end
  end

  @doc """
  Check if a user can perform an action, returning detailed info for upgrade prompts.
  Returns {:ok, :allowed} if allowed, or {:error, upgrade_info} with details.
  """
  def check_action_with_upgrade_info(user_id, action, context \\ %{}) do
    subscription_data = get_user_subscription(user_id)
    plan = subscription_data.plan
    subscription = Map.get(subscription_data, :subscription)
    usage = Map.get(subscription_data, :usage, %{})

    allowed = check_action_permission(plan, subscription, action, context)

    if allowed do
      {:ok, :allowed}
    else
      upgrade_info = build_upgrade_info(action, plan, usage, context)
      {:error, upgrade_info}
    end
  end

  defp build_upgrade_info(action, plan, usage, context) do
    base_info = %{
      action: action,
      current_plan: plan.name,
      current_plan_slug: plan.slug,
      upgrade_required: true,
      recommended_plan: recommend_plan_for_action(action)
    }

    case action do
      :create_button ->
        current = context[:current_button_count] || 0
        Map.merge(base_info, %{
          reason: :limit_reached,
          message: "You've reached the maximum of #{plan.max_buttons} buttons on the #{plan.name} plan.",
          current_usage: current,
          limit: plan.max_buttons,
          upgrade_benefit: "Upgrade to Premium for up to 50 buttons, or Enterprise for unlimited buttons."
        })

      :add_friend ->
        current = context[:current_friend_count] || 0
        Map.merge(base_info, %{
          reason: :limit_reached,
          message: "You've reached the maximum of #{plan.max_friends} friends on the #{plan.name} plan.",
          current_usage: current,
          limit: plan.max_friends,
          upgrade_benefit: "Upgrade to Premium for up to 100 friends, or Enterprise for unlimited friends."
        })

      :click_button ->
        current = usage[:clicks_this_month] || context[:current_clicks] || 0
        Map.merge(base_info, %{
          reason: :limit_reached,
          message: "You've reached #{plan.max_button_clicks_per_month} button clicks this month.",
          current_usage: current,
          limit: plan.max_button_clicks_per_month,
          upgrade_benefit: "Upgrade to Premium for 10,000 clicks/month, or Enterprise for unlimited clicks."
        })

      :access_analytics ->
        days = context[:days_back] || 30
        Map.merge(base_info, %{
          reason: :feature_limited,
          message: "Analytics history is limited to #{plan.max_analytics_history_days} days on the #{plan.name} plan.",
          requested_days: days,
          limit: plan.max_analytics_history_days,
          upgrade_benefit: "Upgrade to Premium for 1 year of history, or Enterprise for unlimited history."
        })

      :export_data ->
        days = context[:days_back] || 30
        Map.merge(base_info, %{
          reason: :feature_limited,
          message: "Data export is limited to #{plan.max_export_history_days} days on the #{plan.name} plan.",
          requested_days: days,
          limit: plan.max_export_history_days,
          upgrade_benefit: "Upgrade to Premium for 1 year of export history, or Enterprise for unlimited."
        })

      :use_calendar_sync ->
        Map.merge(base_info, %{
          reason: :feature_unavailable,
          message: "Calendar sync is a Premium feature.",
          upgrade_benefit: "Upgrade to Premium or Enterprise to sync your buttons with your calendar."
        })

      :use_api ->
        Map.merge(base_info, %{
          reason: :feature_unavailable,
          message: "API access is a Premium feature.",
          upgrade_benefit: "Upgrade to Premium or Enterprise to access the ButtonLog API."
        })

      :use_custom_themes ->
        Map.merge(base_info, %{
          reason: :feature_unavailable,
          message: "Custom themes are a Premium feature.",
          upgrade_benefit: "Upgrade to Premium or Enterprise to customize your button themes."
        })

      :use_team_features ->
        Map.merge(base_info, %{
          reason: :feature_unavailable,
          message: "Team features are an Enterprise feature.",
          recommended_plan: "enterprise",
          upgrade_benefit: "Upgrade to Enterprise for team collaboration features."
        })

      :use_white_label ->
        Map.merge(base_info, %{
          reason: :feature_unavailable,
          message: "White-label options are an Enterprise feature.",
          recommended_plan: "enterprise",
          upgrade_benefit: "Upgrade to Enterprise for white-label branding options."
        })

      :send_gift_button ->
        Map.merge(base_info, %{
          reason: :feature_unavailable,
          message: "Gift buttons are a Premium feature.",
          upgrade_benefit: "Upgrade to Premium or Enterprise to send gift buttons to friends."
        })

      _ ->
        Map.merge(base_info, %{
          reason: :unknown,
          message: "This feature requires an upgrade.",
          upgrade_benefit: "Upgrade your plan to access more features."
        })
    end
  end

  defp recommend_plan_for_action(action) do
    case action do
      :use_team_features -> "enterprise"
      :use_white_label -> "enterprise"
      _ -> "premium"
    end
  end

  @doc """
  Track usage for a specific action.
  """
  def track_usage(user_id, action, context \\ %{}) do
    case get_user_subscription(user_id) do
      %{subscription: subscription} when not is_nil(subscription) ->
        update_usage(subscription, action, context)
      _ ->
        # Free user - no usage tracking needed
        {:ok, nil}
    end
  end

  @doc """
  Create a new subscription for a user.
  """
  def create_subscription(user_id, plan_slug, billing_cycle, payment_details) do
    plan = get_plan_by_slug(plan_slug)

    if is_nil(plan) do
      {:error, "Invalid subscription plan"}
    else
      # Cancel any existing active subscription
      cancel_active_subscription(user_id)

      # Create new subscription
      subscription_attrs = %{
        user_id: user_id,
        subscription_plan_id: plan.id,
        status: :active,
        billing_cycle: billing_cycle,
        amount: get_plan_price(plan, billing_cycle),
        currency: plan.currency,
        current_period_start: DateTime.utc_now(),
        current_period_end: calculate_period_end(billing_cycle),
        next_billing_date: calculate_period_end(billing_cycle),
        payment_provider: payment_details.provider,
        payment_provider_subscription_id: payment_details.subscription_id,
        payment_provider_customer_id: payment_details.customer_id
      }

      # Add trial period if available
      subscription_attrs = maybe_add_trial(subscription_attrs, plan)

      %UserSubscription{}
      |> UserSubscription.changeset(subscription_attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Cancel a user's subscription.
  """
  def cancel_subscription(user_id) do
    case get_user_subscription(user_id) do
      %{subscription: subscription} when not is_nil(subscription) ->
        subscription
        |> UserSubscription.changeset(%{
          status: :canceled,
          canceled_at: DateTime.utc_now()
        })
        |> Repo.update()
      _ ->
        {:error, "No active subscription found"}
    end
  end

  @doc """
  Pause a user's subscription.
  """
  def pause_subscription(user_id) do
    case get_user_subscription(user_id) do
      %{subscription: subscription} when not is_nil(subscription) ->
        subscription
        |> UserSubscription.changeset(%{
          status: :paused,
          paused_at: DateTime.utc_now()
        })
        |> Repo.update()
      _ ->
        {:error, "No active subscription found"}
    end
  end

  @doc """
  Resume a paused subscription.
  """
  def resume_subscription(user_id) do
    case get_user_subscription(user_id) do
      %{subscription: subscription} when not is_nil(subscription) ->
        subscription
        |> UserSubscription.changeset(%{
          status: :active,
          paused_at: nil
        })
        |> Repo.update()
      _ ->
        {:error, "No subscription found"}
    end
  end

  @doc """
  Get all available subscription plans.
  """
  def get_available_plans do
    SubscriptionPlan
    |> where([sp], sp.is_active == true)
    |> order_by([sp], sp.sort_order)
    |> Repo.all()
  end

  @doc """
  Get subscription statistics for a user.
  """
  def get_subscription_stats(user_id) do
    case get_user_subscription(user_id) do
      %{plan: plan, subscription: subscription, usage: usage} when not is_nil(subscription) ->
        %{
          current_plan: plan.name,
          status: subscription.status,
          billing_cycle: subscription.billing_cycle,
          next_billing: subscription.next_billing_date,
          usage: usage,
          limits: %{
            max_buttons: plan.max_buttons,
            max_friends: plan.max_friends,
            max_clicks_per_month: plan.max_button_clicks_per_month,
            max_analytics_days: plan.max_analytics_history_days
          },
          features: %{
            advanced_analytics: plan.has_advanced_analytics,
            calendar_sync: plan.has_calendar_sync,
            api_access: plan.has_api_access,
            priority_support: plan.has_priority_support,
            custom_themes: plan.has_custom_themes,
            team_features: plan.has_team_features,
            white_label: plan.has_white_label
          }
        }
      %{plan: plan} ->
        %{
          current_plan: plan.name,
          status: :free,
          usage: %{},
          limits: %{
            max_buttons: plan.max_buttons,
            max_friends: plan.max_friends,
            max_clicks_per_month: plan.max_button_clicks_per_month,
            max_analytics_days: plan.max_analytics_history_days
          },
          features: %{
            advanced_analytics: plan.has_advanced_analytics,
            calendar_sync: plan.has_calendar_sync,
            api_access: plan.has_api_access,
            priority_support: plan.has_priority_support,
            custom_themes: plan.has_custom_themes,
            team_features: plan.has_team_features,
            white_label: plan.has_white_label
          }
        }
    end
  end

  # Private functions

  defp check_action_permission(plan, subscription, action, context) do
    case action do
      :create_button ->
        current_count = context[:current_button_count] || 0
        SubscriptionPlan.can_create_button(plan, current_count)

      :add_friend ->
        current_count = context[:current_friend_count] || 0
        SubscriptionPlan.can_add_friend(plan, current_count)

      :click_button ->
        if is_nil(subscription) do
          # Free user - check monthly limit
          current_month = DateTime.truncate(DateTime.utc_now(), :month)
          start_of_month = DateTime.add(current_month, 0, :second)

          query = from bc in ButtonLog.Buttons.ButtonClick,
            where: bc.user_id == ^context[:user_id] and bc.clicked_at >= ^start_of_month

          current_clicks = Repo.aggregate(query, :count, :id)
          SubscriptionPlan.can_click_button(plan, current_clicks)
        else
          UserSubscription.can_click_button(subscription, plan)
        end

      :access_analytics ->
        days_back = context[:days_back] || 30
        SubscriptionPlan.can_access_analytics(plan, days_back)

      :export_data ->
        days_back = context[:days_back] || 30
        SubscriptionPlan.can_export_data(plan, days_back)

      :use_calendar_sync ->
        plan.has_calendar_sync

      :use_api ->
        plan.has_api_access

      :use_custom_themes ->
        plan.has_custom_themes

      :use_team_features ->
        plan.has_team_features

      :use_white_label ->
        plan.has_white_label

      :send_gift_button ->
        # Gift buttons are a Premium feature
        plan.slug != "free"

      _ ->
        false
    end
  end

  defp update_usage(subscription, action, _context) do
    updates = case action do
      :create_button ->
        %{buttons_used: subscription.buttons_used + 1}

      :add_friend ->
        %{friends_used: subscription.friends_used + 1}

      :click_button ->
        %{clicks_this_month: subscription.clicks_this_month + 1}

      _ ->
        %{}
    end

    if map_size(updates) > 0 do
      subscription
      |> UserSubscription.changeset(updates)
      |> Repo.update()
    else
      {:ok, subscription}
    end
  end

  defp maybe_reset_monthly_usage(subscription) do
    if UserSubscription.should_reset_monthly_usage(subscription) do
      # Update in database
      case Repo.update(UserSubscription.changeset(subscription, %{
        clicks_this_month: 0,
        last_usage_reset: DateTime.utc_now()
      })) do
        {:ok, updated} -> updated
        _ -> subscription
      end
    else
      subscription
    end
  end

  defp get_plan_by_slug(slug) do
    SubscriptionPlan
    |> where([sp], sp.slug == ^slug and sp.is_active == true)
    |> Repo.one()
  end

  defp get_plan_price(plan, :monthly), do: plan.price_monthly
  defp get_plan_price(plan, :yearly), do: plan.price_yearly

  defp calculate_period_end(:monthly) do
    DateTime.utc_now()
    |> DateTime.add(30, :day)
  end

  defp calculate_period_end(:yearly) do
    DateTime.utc_now()
    |> DateTime.add(365, :day)
  end

  defp maybe_add_trial(attrs, plan) do
    if plan.trial_days > 0 do
      now = DateTime.utc_now()
      trial_end = DateTime.add(now, plan.trial_days, :day)

      attrs
      |> Map.put(:status, :trialing)
      |> Map.put(:trial_start, now)
      |> Map.put(:trial_end, trial_end)
      |> Map.put(:current_period_end, trial_end)
    else
      attrs
    end
  end

  defp cancel_active_subscription(user_id) do
    query = from us in UserSubscription,
      where: us.user_id == ^user_id and us.status in [:active, :trialing]

    Repo.update_all(query, set: [status: :canceled, canceled_at: DateTime.utc_now()])
  end
end

