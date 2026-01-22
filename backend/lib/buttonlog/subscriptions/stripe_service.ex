defmodule ButtonLog.Subscriptions.StripeService do
  @moduledoc """
  Service module for interacting with the Stripe API.

  Handles customer creation, payment methods, subscriptions,
  checkout sessions, and webhook processing.
  """

  alias ButtonLog.Subscriptions

  @doc """
  Creates or retrieves a Stripe customer for a user.
  """
  def get_or_create_customer(user) do
    case get_customer_id(user) do
      nil -> create_customer(user)
      customer_id -> {:ok, customer_id}
    end
  end

  defp get_customer_id(user) do
    # Check if user has an existing customer ID in their payment methods
    case Subscriptions.list_payment_methods(user.id) do
      [%{payment_provider_customer_id: customer_id} | _] when not is_nil(customer_id) ->
        customer_id

      _ ->
        nil
    end
  end

  defp create_customer(user) do
    params = %{
      email: user.email,
      name: user.display_name || user.username,
      metadata: %{
        user_id: user.id,
        username: user.username
      }
    }

    case Stripe.Customer.create(params) do
      {:ok, customer} -> {:ok, customer.id}
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Creates a Checkout Session for subscribing to a plan.
  """
  def create_checkout_session(user, plan, billing_cycle, opts \\ []) do
    with {:ok, customer_id} <- get_or_create_customer(user),
         {:ok, price_id} <- get_price_id(plan, billing_cycle) do
      success_url = Keyword.get(opts, :success_url, default_success_url())
      cancel_url = Keyword.get(opts, :cancel_url, default_cancel_url())
      coupon_code = Keyword.get(opts, :coupon_code)

      params = %{
        customer: customer_id,
        mode: "subscription",
        line_items: [
          %{
            price: price_id,
            quantity: 1
          }
        ],
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: %{
          user_id: user.id,
          plan_id: plan.id,
          billing_cycle: to_string(billing_cycle)
        },
        subscription_data: %{
          metadata: %{
            user_id: user.id,
            plan_id: plan.id
          }
        }
      }

      # Add trial period if plan has one and user hasn't had a trial before
      params =
        if plan.trial_days > 0 and not had_trial?(user.id) do
          put_in(params, [:subscription_data, :trial_period_days], plan.trial_days)
        else
          params
        end

      # Add coupon if provided
      params =
        if coupon_code do
          Map.put(params, :discounts, [%{coupon: coupon_code}])
        else
          params
        end

      case Stripe.Checkout.Session.create(params) do
        {:ok, session} -> {:ok, session}
        {:error, error} -> {:error, format_stripe_error(error)}
      end
    end
  end

  @doc """
  Creates a Customer Portal session for managing subscriptions.
  """
  def create_portal_session(user, return_url \\ nil) do
    with {:ok, customer_id} <- get_or_create_customer(user) do
      params = %{
        customer: customer_id,
        return_url: return_url || default_return_url()
      }

      case Stripe.BillingPortal.Session.create(params) do
        {:ok, session} -> {:ok, session}
        {:error, error} -> {:error, format_stripe_error(error)}
      end
    end
  end

  @doc """
  Retrieves a Stripe subscription by ID.
  """
  def get_subscription(subscription_id) do
    case Stripe.Subscription.retrieve(subscription_id) do
      {:ok, subscription} -> {:ok, subscription}
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Cancels a Stripe subscription.
  """
  def cancel_subscription(subscription_id, opts \\ []) do
    at_period_end = Keyword.get(opts, :at_period_end, true)

    if at_period_end do
      # Cancel at end of billing period
      case Stripe.Subscription.update(subscription_id, %{cancel_at_period_end: true}) do
        {:ok, subscription} -> {:ok, subscription}
        {:error, error} -> {:error, format_stripe_error(error)}
      end
    else
      # Cancel immediately
      case Stripe.Subscription.cancel(subscription_id) do
        {:ok, subscription} -> {:ok, subscription}
        {:error, error} -> {:error, format_stripe_error(error)}
      end
    end
  end

  @doc """
  Changes the plan for an existing subscription.
  """
  def change_subscription_plan(subscription_id, new_plan, billing_cycle) do
    with {:ok, subscription} <- get_subscription(subscription_id),
         {:ok, price_id} <- get_price_id(new_plan, billing_cycle) do
      # Get the first subscription item
      item_id = List.first(subscription.items.data).id

      params = %{
        items: [
          %{
            id: item_id,
            price: price_id
          }
        ],
        proration_behavior: "create_prorations"
      }

      case Stripe.Subscription.update(subscription_id, params) do
        {:ok, updated} -> {:ok, updated}
        {:error, error} -> {:error, format_stripe_error(error)}
      end
    end
  end

  @doc """
  Creates a Setup Intent for adding a payment method.
  """
  def create_setup_intent(user) do
    with {:ok, customer_id} <- get_or_create_customer(user) do
      params = %{
        customer: customer_id,
        payment_method_types: ["card"],
        metadata: %{
          user_id: user.id
        }
      }

      case Stripe.SetupIntent.create(params) do
        {:ok, intent} -> {:ok, intent}
        {:error, error} -> {:error, format_stripe_error(error)}
      end
    end
  end

  @doc """
  Attaches a payment method to a customer.
  """
  def attach_payment_method(user, payment_method_id) do
    with {:ok, customer_id} <- get_or_create_customer(user),
         {:ok, payment_method} <- Stripe.PaymentMethod.attach(payment_method_id, %{customer: customer_id}),
         {:ok, _} <- save_payment_method(user.id, customer_id, payment_method) do
      {:ok, payment_method}
    else
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Detaches a payment method from a customer.
  """
  def detach_payment_method(payment_method_id) do
    case Stripe.PaymentMethod.detach(payment_method_id) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Sets the default payment method for a customer's subscription.
  """
  def set_default_payment_method(customer_id, payment_method_id) do
    params = %{
      invoice_settings: %{
        default_payment_method: payment_method_id
      }
    }

    case Stripe.Customer.update(customer_id, params) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Creates a coupon in Stripe.
  """
  def create_coupon(coupon_code) do
    params = %{
      id: coupon_code.code,
      name: coupon_code.name || coupon_code.code
    }

    params =
      case coupon_code.discount_type do
        :percentage ->
          Map.put(params, :percent_off, Decimal.to_float(coupon_code.discount_value))

        :fixed_amount ->
          params
          |> Map.put(:amount_off, Decimal.to_integer(Decimal.mult(coupon_code.discount_value, 100)))
          |> Map.put(:currency, String.downcase(coupon_code.currency))
      end

    params =
      case coupon_code.duration do
        :once -> Map.put(params, :duration, "once")
        :forever -> Map.put(params, :duration, "forever")
        :repeating ->
          params
          |> Map.put(:duration, "repeating")
          |> Map.put(:duration_in_months, coupon_code.duration_months)
      end

    params =
      if coupon_code.max_redemptions do
        Map.put(params, :max_redemptions, coupon_code.max_redemptions)
      else
        params
      end

    case Stripe.Coupon.create(params) do
      {:ok, coupon} -> {:ok, coupon}
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Retrieves upcoming invoice for a subscription.
  """
  def get_upcoming_invoice(customer_id) do
    case Stripe.Invoice.upcoming(%{customer: customer_id}) do
      {:ok, invoice} -> {:ok, invoice}
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  @doc """
  Lists invoices for a customer.
  """
  def list_invoices(customer_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    params = %{
      customer: customer_id,
      limit: limit
    }

    case Stripe.Invoice.list(params) do
      {:ok, %{data: invoices}} -> {:ok, invoices}
      {:error, error} -> {:error, format_stripe_error(error)}
    end
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp get_price_id(plan, billing_cycle) do
    price_id =
      case billing_cycle do
        :monthly -> plan.stripe_price_id_monthly
        :yearly -> plan.stripe_price_id_yearly
        _ -> nil
      end

    case price_id do
      nil -> {:error, :price_not_configured}
      id -> {:ok, id}
    end
  end

  defp save_payment_method(user_id, customer_id, stripe_pm) do
    card = stripe_pm.card

    attrs = %{
      user_id: user_id,
      payment_provider: "stripe",
      payment_provider_method_id: stripe_pm.id,
      payment_provider_customer_id: customer_id,
      card_brand: card.brand,
      card_last_four: card.last4,
      card_exp_month: card.exp_month,
      card_exp_year: card.exp_year,
      is_default: Subscriptions.list_payment_methods(user_id) == []
    }

    Subscriptions.create_payment_method(attrs)
  end

  defp had_trial?(user_id) do
    # Check if user has ever had a trial
    case Subscriptions.get_user_subscription(user_id) do
      %{subscription: %{trial_start: trial_start}} when not is_nil(trial_start) -> true
      _ -> false
    end
  end

  defp format_stripe_error(%Stripe.Error{} = error) do
    error.message || "An error occurred with the payment provider"
  end

  defp format_stripe_error(error) when is_binary(error), do: error
  defp format_stripe_error(_), do: "An unexpected payment error occurred"

  defp default_success_url do
    Application.get_env(:buttonlog, :stripe_success_url, "http://localhost:4000/account?payment=success")
  end

  defp default_cancel_url do
    Application.get_env(:buttonlog, :stripe_cancel_url, "http://localhost:4000/account?payment=cancelled")
  end

  defp default_return_url do
    Application.get_env(:buttonlog, :stripe_return_url, "http://localhost:4000/account")
  end
end
