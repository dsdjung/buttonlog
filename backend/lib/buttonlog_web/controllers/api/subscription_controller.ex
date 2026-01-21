defmodule ButtonLogWeb.API.SubscriptionController do
  use ButtonLogWeb, :controller

  alias ButtonLog.Subscriptions.SubscriptionService
  alias ButtonLog.Accounts.User

  # Plug to ensure user is authenticated
  plug :authenticate_user when action in [:index, :show, :create, :cancel, :pause, :resume, :stats]

  @doc """
  Get all available subscription plans.
  """
  def index(conn, _params) do
    plans = SubscriptionService.get_available_plans()

    conn
    |> put_status(:ok)
    |> json(%{
      plans: Enum.map(plans, &format_plan/1)
    })
  end

  @doc """
  Get current user's subscription details.
  """
  def show(conn, _params) do
    user_id = conn.assigns.current_user.id

    case SubscriptionService.get_user_subscription(user_id) do
      %{plan: plan, subscription: subscription, usage: usage} when not is_nil(subscription) ->
        conn
        |> put_status(:ok)
        |> json(%{
          subscription: %{
            id: subscription.id,
            status: subscription.status,
            plan: format_plan(plan),
            billing_cycle: subscription.billing_cycle,
            amount: subscription.amount,
            currency: subscription.currency,
            current_period_start: subscription.current_period_start,
            current_period_end: subscription.current_period_end,
            trial_start: subscription.trial_start,
            trial_end: subscription.trial_end,
            next_billing_date: subscription.next_billing_date,
            usage: usage
          }
        })

      %{plan: plan} ->
        conn
        |> put_status(:ok)
        |> json(%{
          subscription: nil,
          plan: format_plan(plan),
          usage: %{}
        })
    end
  end

  @doc """
  Create a new subscription for the current user.
  """
  def create(conn, %{"plan_slug" => plan_slug, "billing_cycle" => billing_cycle, "payment_details" => payment_details}) do
    user_id = conn.assigns.current_user.id

    case SubscriptionService.create_subscription(user_id, plan_slug, billing_cycle, payment_details) do
      {:ok, subscription} ->
        conn
        |> put_status(:created)
        |> json(%{
          message: "Subscription created successfully",
          subscription: %{
            id: subscription.id,
            status: subscription.status,
            plan_slug: plan_slug,
            billing_cycle: subscription.billing_cycle,
            amount: subscription.amount,
            currency: subscription.currency
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Cancel the current user's subscription.
  """
  def cancel(conn, _params) do
    user_id = conn.assigns.current_user.id

    case SubscriptionService.cancel_subscription(user_id) do
      {:ok, subscription} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Subscription canceled successfully",
          subscription: %{
            id: subscription.id,
            status: subscription.status,
            canceled_at: subscription.canceled_at
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Pause the current user's subscription.
  """
  def pause(conn, _params) do
    user_id = conn.assigns.current_user.id

    case SubscriptionService.pause_subscription(user_id) do
      {:ok, subscription} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Subscription paused successfully",
          subscription: %{
            id: subscription.id,
            status: subscription.status,
            paused_at: subscription.paused_at
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Resume a paused subscription.
  """
  def resume(conn, _params) do
    user_id = conn.assigns.current_user.id

    case SubscriptionService.resume_subscription(user_id) do
      {:ok, subscription} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Subscription resumed successfully",
          subscription: %{
            id: subscription.id,
            status: subscription.status
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Get subscription statistics for the current user.
  """
  def stats(conn, _params) do
    user_id = conn.assigns.current_user.id
    stats = SubscriptionService.get_subscription_stats(user_id)

    conn
    |> put_status(:ok)
    |> json(stats)
  end

  @doc """
  Check if user can perform a specific action.
  """
  def check_permission(conn, %{"action" => action, "context" => context}) do
    user_id = conn.assigns.current_user.id

    can_perform = SubscriptionService.can_perform_action(user_id, String.to_atom(action), context)

    conn
    |> put_status(:ok)
    |> json(%{
      action: action,
      can_perform: can_perform
    })
  end

  # Private functions

  defp format_plan(plan) do
    %{
      id: plan.id,
      name: plan.name,
      slug: plan.slug,
      description: plan.description,
      pricing: %{
        monthly: plan.price_monthly,
        yearly: plan.price_yearly,
        currency: plan.currency
      },
      features: %{
        max_buttons: plan.max_buttons,
        max_friends: plan.max_friends,
        max_button_clicks_per_month: plan.max_button_clicks_per_month,
        max_analytics_history_days: plan.max_analytics_history_days,
        max_export_history_days: plan.max_export_history_days,
        has_advanced_analytics: plan.has_advanced_analytics,
        has_calendar_sync: plan.has_calendar_sync,
        has_api_access: plan.has_api_access,
        has_priority_support: plan.has_priority_support,
        has_custom_themes: plan.has_custom_themes,
        has_team_features: plan.has_team_features,
        has_white_label: plan.has_white_label
      },
      trial: %{
        days: plan.trial_days,
        requires_credit_card: plan.trial_requires_credit_card
      }
    }
  end

  defp authenticate_user(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()
      _user ->
        conn
    end
  end
end

