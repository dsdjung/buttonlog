defmodule ButtonLog.Subscriptions do
  @moduledoc """
  The Subscriptions context provides a unified interface for managing
  user subscriptions, plans, and feature access control.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo

  alias ButtonLog.Subscriptions.{
    SubscriptionPlan,
    UserSubscription,
    SubscriptionService
  }

  @doc """
  Returns the list of subscription plans.
  """
  def list_subscription_plans do
    Repo.all(SubscriptionPlan)
  end

  @doc """
  Gets a single subscription plan by ID.
  """
  def get_subscription_plan!(id), do: Repo.get!(SubscriptionPlan, id)

  @doc """
  Gets a single subscription plan by slug.
  """
  def get_subscription_plan_by_slug(slug) do
    Repo.get_by(SubscriptionPlan, slug: slug)
  end

  @doc """
  Creates a subscription plan.
  """
  def create_subscription_plan(attrs \\ %{}) do
    %SubscriptionPlan{}
    |> SubscriptionPlan.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription plan.
  """
  def update_subscription_plan(%SubscriptionPlan{} = subscription_plan, attrs) do
    subscription_plan
    |> SubscriptionPlan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subscription plan.
  """
  def delete_subscription_plan(%SubscriptionPlan{} = subscription_plan) do
    Repo.delete(subscription_plan)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription plan changes.
  """
  def change_subscription_plan(%SubscriptionPlan{} = subscription_plan, attrs \\ %{}) do
    SubscriptionPlan.changeset(subscription_plan, attrs)
  end

  @doc """
  Returns the list of user subscriptions.
  """
  def list_user_subscriptions do
    Repo.all(UserSubscription)
  end

  @doc """
  Gets a single user subscription by ID.
  """
  def get_user_subscription!(id), do: Repo.get!(UserSubscription, id)

  @doc """
  Gets the current active subscription for a user.
  """
  def get_user_subscription(user_id) do
    SubscriptionService.get_user_subscription(user_id)
  end

  @doc """
  Creates a user subscription.
  """
  def create_user_subscription(attrs \\ %{}) do
    %UserSubscription{}
    |> UserSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user subscription.
  """
  def update_user_subscription(%UserSubscription{} = user_subscription, attrs) do
    user_subscription
    |> UserSubscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user subscription.
  """
  def delete_user_subscription(%UserSubscription{} = user_subscription) do
    Repo.delete(user_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user subscription changes.
  """
  def change_user_subscription(%UserSubscription{} = user_subscription, attrs \\ %{}) do
    UserSubscription.changeset(user_subscription, attrs)
  end

  @doc """
  Check if a user can perform a specific action based on their subscription.
  """
  def can_perform_action(user_id, action, context \\ %{}) do
    SubscriptionService.can_perform_action(user_id, action, context)
  end

  @doc """
  Track usage for a specific action.
  """
  def track_usage(user_id, action, context \\ %{}) do
    SubscriptionService.track_usage(user_id, action, context)
  end

  @doc """
  Create a new subscription for a user.
  """
  def create_subscription(user_id, plan_slug, billing_cycle, payment_details) do
    SubscriptionService.create_subscription(user_id, plan_slug, billing_cycle, payment_details)
  end

  @doc """
  Cancel a user's subscription.
  """
  def cancel_subscription(user_id) do
    SubscriptionService.cancel_subscription(user_id)
  end

  @doc """
  Pause a user's subscription.
  """
  def pause_subscription(user_id) do
    SubscriptionService.pause_subscription(user_id)
  end

  @doc """
  Resume a paused subscription.
  """
  def resume_subscription(user_id) do
    SubscriptionService.resume_subscription(user_id)
  end

  @doc """
  Get all available subscription plans.
  """
  def get_available_plans do
    SubscriptionService.get_available_plans()
  end

  @doc """
  Get subscription statistics for a user.
  """
  def get_subscription_stats(user_id) do
    SubscriptionService.get_subscription_stats(user_id)
  end

  @doc """
  Get the default free plan.
  """
  def get_free_plan do
    SubscriptionPlan.free_plan()
  end

  @doc """
  Get the premium plan.
  """
  def get_premium_plan do
    SubscriptionPlan.premium_plan()
  end

  @doc """
  Get the enterprise plan.
  """
  def get_enterprise_plan do
    SubscriptionPlan.enterprise_plan()
  end

  @doc """
  Check if a user has access to a specific feature.
  """
  def has_feature(user_id, feature) do
    case get_user_subscription(user_id) do
      %{plan: plan} ->
        SubscriptionPlan.has_feature(plan, feature)
      _ ->
        false
    end
  end

  @doc """
  Get the user's current plan limits.
  """
  def get_user_limits(user_id) do
    case get_user_subscription(user_id) do
      %{plan: plan} ->
        %{
          max_buttons: plan.max_buttons,
          max_friends: plan.max_friends,
          max_button_clicks_per_month: plan.max_button_clicks_per_month,
          max_analytics_history_days: plan.max_analytics_history_days,
          max_export_history_days: plan.max_export_history_days
        }
      _ ->
        %{
          max_buttons: 5,
          max_friends: 10,
          max_button_clicks_per_month: 1000,
          max_analytics_history_days: 30,
          max_export_history_days: 30
        }
    end
  end

  @doc """
  Get the user's current usage.
  """
  def get_user_usage(user_id) do
    case get_user_subscription(user_id) do
      %{subscription: subscription, usage: usage} when not is_nil(subscription) ->
        usage
      _ ->
        # For free users, calculate usage from database
        %{
          buttons_used: count_user_buttons(user_id),
          friends_used: count_user_friends(user_id),
          clicks_this_month: count_user_clicks_this_month(user_id)
        }
    end
  end

  @doc """
  Check if a user needs to upgrade their subscription.
  """
  def needs_upgrade?(user_id) do
    case get_user_subscription(user_id) do
      %{plan: _plan, subscription: subscription} when not is_nil(subscription) ->
        # Check if user is approaching limits
        usage = get_user_usage(user_id)
        limits = get_user_limits(user_id)

        # Check if any limits are close to being reached (80% threshold)
        Enum.any?([
          {usage.buttons_used, limits.max_buttons},
          {usage.friends_used, limits.max_friends},
          {usage.clicks_this_month, limits.max_button_clicks_per_month}
        ], fn {used, limit} ->
          not SubscriptionPlan.is_unlimited(limit) and used >= limit * 0.8
        end)

      _ ->
        # Free user - check if they're hitting limits
        usage = get_user_usage(user_id)
        limits = get_user_limits(user_id)

        Enum.any?([
          {usage.buttons_used, limits.max_buttons},
          {usage.friends_used, limits.max_friends},
          {usage.clicks_this_month, limits.max_button_clicks_per_month}
        ], fn {used, limit} ->
          used >= limit * 0.8
        end)
    end
  end

  # Private helper functions

  defp count_user_buttons(user_id) do
    from(b in ButtonLog.Buttons.Button, where: b.user_id == ^user_id)
    |> Repo.aggregate(:count, :id)
  end

  defp count_user_friends(user_id) do
    from(f in ButtonLog.Social.Friendship,
      where: f.user_id == ^user_id and f.status == "accepted")
    |> Repo.aggregate(:count, :id)
  end

  defp count_user_clicks_this_month(user_id) do
    current_month = DateTime.truncate(DateTime.utc_now(), :month)
    start_of_month = DateTime.add(current_month, 0, :second)

    from(bc in ButtonLog.Buttons.ButtonClick,
      where: bc.user_id == ^user_id and bc.clicked_at >= ^start_of_month)
    |> Repo.aggregate(:count, :id)
  end
end

