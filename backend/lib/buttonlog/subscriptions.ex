defmodule ButtonLog.Subscriptions do
  @moduledoc """
  The Subscriptions context provides a unified interface for managing
  user subscriptions, plans, feature access control, payment methods,
  invoices, and coupon codes.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo

  alias ButtonLog.Subscriptions.{
    SubscriptionPlan,
    UserSubscription,
    SubscriptionService,
    PaymentMethod,
    Invoice,
    CouponCode,
    UserCoupon,
    SubscriptionEvent,
    BillingEvent
  }

  @doc """
  Returns the list of subscription plans.
  """
  def list_subscription_plans do
    Repo.all(SubscriptionPlan)
  end

  @doc """
  Gets a single subscription plan by ID.
  Raises if the plan is not found.
  """
  def get_subscription_plan!(id), do: Repo.get!(SubscriptionPlan, id)

  @doc """
  Gets a single subscription plan by ID.
  Returns nil if the plan is not found.
  """
  def get_subscription_plan(id), do: Repo.get(SubscriptionPlan, id)

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

  # ============================================================================
  # Payment Methods
  # ============================================================================

  @doc """
  Lists all payment methods for a user.
  """
  def list_payment_methods(user_id) do
    from(pm in PaymentMethod,
      where: pm.user_id == ^user_id and pm.is_active == true,
      order_by: [desc: pm.is_default, desc: pm.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single payment method by ID.
  """
  def get_payment_method(id) do
    Repo.get(PaymentMethod, id)
  end

  @doc """
  Gets the default payment method for a user.
  """
  def get_default_payment_method(user_id) do
    from(pm in PaymentMethod,
      where: pm.user_id == ^user_id and pm.is_default == true and pm.is_active == true,
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a payment method.
  """
  def create_payment_method(attrs \\ %{}) do
    %PaymentMethod{}
    |> PaymentMethod.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets a payment method as the default for a user.
  """
  def set_default_payment_method(user_id, payment_method_id) do
    Repo.transaction(fn ->
      # Clear existing default
      from(pm in PaymentMethod,
        where: pm.user_id == ^user_id and pm.is_default == true
      )
      |> Repo.update_all(set: [is_default: false])

      # Set new default
      case Repo.get(PaymentMethod, payment_method_id) do
        nil ->
          Repo.rollback(:not_found)

        payment_method when payment_method.user_id == user_id ->
          payment_method
          |> PaymentMethod.changeset(%{is_default: true})
          |> Repo.update()

        _ ->
          Repo.rollback(:unauthorized)
      end
    end)
  end

  @doc """
  Deletes (deactivates) a payment method.
  """
  def delete_payment_method(user_id, payment_method_id) do
    case get_payment_method(payment_method_id) do
      nil ->
        {:error, :not_found}

      payment_method when payment_method.user_id == user_id ->
        payment_method
        |> PaymentMethod.changeset(%{is_active: false})
        |> Repo.update()

      _ ->
        {:error, :unauthorized}
    end
  end

  # ============================================================================
  # Invoices
  # ============================================================================

  @doc """
  Lists all invoices for a user.
  """
  def list_invoices(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(i in Invoice,
      where: i.user_id == ^user_id,
      order_by: [desc: i.invoice_date],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc """
  Gets a single invoice by ID.
  """
  def get_invoice(id) do
    Repo.get(Invoice, id)
  end

  @doc """
  Gets an invoice by invoice number.
  """
  def get_invoice_by_number(invoice_number) do
    Repo.get_by(Invoice, invoice_number: invoice_number)
  end

  @doc """
  Gets an invoice by Stripe invoice ID.
  """
  def get_invoice_by_stripe_id(stripe_invoice_id) do
    Repo.get_by(Invoice, payment_provider_invoice_id: stripe_invoice_id)
  end

  @doc """
  Creates an invoice.
  """
  def create_invoice(attrs \\ %{}) do
    attrs = Map.put_new(attrs, :invoice_number, Invoice.generate_invoice_number())

    %Invoice{}
    |> Invoice.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an invoice.
  """
  def update_invoice(%Invoice{} = invoice, attrs) do
    invoice
    |> Invoice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks an invoice as paid.
  """
  def mark_invoice_paid(invoice_id, payment_details \\ %{}) do
    case get_invoice(invoice_id) do
      nil ->
        {:error, :not_found}

      invoice ->
        update_invoice(invoice, %{
          status: :paid,
          amount_paid: invoice.amount_due,
          paid_at: DateTime.utc_now(),
          payment_provider_charge_id: Map.get(payment_details, :charge_id)
        })
    end
  end

  # ============================================================================
  # Coupon Codes
  # ============================================================================

  @doc """
  Lists all coupon codes.
  """
  def list_coupon_codes(opts \\ []) do
    active_only = Keyword.get(opts, :active_only, true)

    query = from(c in CouponCode, order_by: [desc: c.inserted_at])

    query =
      if active_only do
        from(c in query, where: c.is_active == true)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a coupon code by code string.
  """
  def get_coupon_code(code) when is_binary(code) do
    Repo.get_by(CouponCode, code: String.upcase(code))
  end

  @doc """
  Gets a coupon code by ID.
  """
  def get_coupon_code_by_id(id) do
    Repo.get(CouponCode, id)
  end

  @doc """
  Creates a coupon code.
  """
  def create_coupon_code(attrs \\ %{}) do
    %CouponCode{}
    |> CouponCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a coupon code.
  """
  def update_coupon_code(%CouponCode{} = coupon, attrs) do
    coupon
    |> CouponCode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Validates and applies a coupon code for a user.
  """
  def apply_coupon_code(user_id, code, subscription_id \\ nil) do
    Repo.transaction(fn ->
      case get_coupon_code(code) do
        nil ->
          Repo.rollback(:invalid_code)

        coupon ->
          cond do
            not CouponCode.valid?(coupon) ->
              Repo.rollback(:coupon_expired)

            already_used_coupon?(user_id, coupon.id) ->
              Repo.rollback(:already_used)

            true ->
              # Create user coupon record
              user_coupon_attrs = %{
                user_id: user_id,
                coupon_code_id: coupon.id,
                user_subscription_id: subscription_id,
                applied_at: DateTime.utc_now(),
                expires_at: calculate_coupon_expiration(coupon),
                remaining_months: coupon.duration_months
              }

              case create_user_coupon(user_coupon_attrs) do
                {:ok, user_coupon} ->
                  # Increment redemption count
                  update_coupon_code(coupon, %{
                    redemptions_count: coupon.redemptions_count + 1
                  })

                  {coupon, user_coupon}

                {:error, _} ->
                  Repo.rollback(:failed_to_apply)
              end
          end
      end
    end)
  end

  @doc """
  Creates a user coupon record.
  """
  def create_user_coupon(attrs) do
    %UserCoupon{}
    |> UserCoupon.changeset(attrs)
    |> Repo.insert()
  end

  defp already_used_coupon?(user_id, coupon_id) do
    from(uc in UserCoupon,
      where: uc.user_id == ^user_id and uc.coupon_code_id == ^coupon_id
    )
    |> Repo.exists?()
  end

  defp calculate_coupon_expiration(%CouponCode{duration: :once}), do: nil
  defp calculate_coupon_expiration(%CouponCode{duration: :forever}), do: nil

  defp calculate_coupon_expiration(%CouponCode{duration: :repeating, duration_months: months}) do
    DateTime.utc_now()
    |> DateTime.add(months * 30, :day)
  end

  # ============================================================================
  # Subscription Events
  # ============================================================================

  @doc """
  Records a subscription event.
  """
  def record_subscription_event(subscription_id, event_type, event_data \\ %{}) do
    %SubscriptionEvent{}
    |> SubscriptionEvent.changeset(%{
      user_subscription_id: subscription_id,
      event_type: event_type,
      event_data: event_data,
      occurred_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  @doc """
  Lists subscription events for a subscription.
  """
  def list_subscription_events(subscription_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(se in SubscriptionEvent,
      where: se.user_subscription_id == ^subscription_id,
      order_by: [desc: se.occurred_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  # ============================================================================
  # Billing Events
  # ============================================================================

  @doc """
  Records a billing event.
  """
  def record_billing_event(subscription_id, event_type, status, attrs \\ %{}) do
    %BillingEvent{}
    |> BillingEvent.changeset(Map.merge(attrs, %{
      user_subscription_id: subscription_id,
      event_type: event_type,
      status: status,
      occurred_at: DateTime.utc_now()
    }))
    |> Repo.insert()
  end

  @doc """
  Lists billing events for a subscription.
  """
  def list_billing_events(subscription_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(be in BillingEvent,
      where: be.user_subscription_id == ^subscription_id,
      order_by: [desc: be.occurred_at],
      limit: ^limit
    )
    |> Repo.all()
  end
end

