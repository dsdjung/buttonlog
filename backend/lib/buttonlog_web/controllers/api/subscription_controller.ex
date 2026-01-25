defmodule ButtonLogWeb.API.SubscriptionController do
  use ButtonLogWeb, :controller

  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.{SubscriptionService, StripeService}

  # Plug to ensure user is authenticated
  # Note: :index is NOT included - subscription plans are public so users can see pricing before signup
  plug :authenticate_user when action in [
    :show, :create, :cancel, :pause, :resume, :stats,
    :create_checkout_session, :create_portal_session,
    :list_payment_methods, :add_payment_method, :remove_payment_method, :set_default_payment_method,
    :list_invoices, :show_invoice,
    :apply_coupon
  ]

  @doc """
  Get all available subscription plans.
  """
  def index(conn, _params) do
    plans = SubscriptionService.get_available_plans()

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      data: Enum.map(plans, &format_plan_for_mobile/1)
    })
  end

  @doc """
  Get current user's subscription details.
  """
  def show(conn, _params) do
    user_id = conn.assigns.current_user.id

    case SubscriptionService.get_user_subscription(user_id) do
      %{plan: _plan, subscription: subscription, usage: usage} when not is_nil(subscription) ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: %{
            id: subscription.id,
            user_id: user_id,
            subscription_plan_id: subscription.subscription_plan_id,
            status: subscription.status,
            billing_cycle: subscription.billing_cycle,
            amount: subscription.amount,
            currency: subscription.currency,
            period_start: subscription.current_period_start,
            period_end: subscription.current_period_end,
            trial_start: subscription.trial_start,
            trial_end: subscription.trial_end,
            payment_provider: subscription.payment_provider,
            provider_subscription_id: subscription.payment_provider_subscription_id,
            usage: format_usage(usage),
            created_at: subscription.inserted_at,
            updated_at: subscription.updated_at
          }
        })

      %{plan: _plan} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: nil
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
          success: true,
          data: %{
            message: "Subscription canceled successfully",
            subscription: %{
              id: subscription.id,
              status: subscription.status,
              canceled_at: subscription.canceled_at
            }
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: message}})
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
          success: true,
          data: %{
            message: "Subscription paused successfully",
            subscription: %{
              id: subscription.id,
              status: subscription.status,
              paused_at: subscription.paused_at
            }
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: message}})
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
          success: true,
          data: %{
            message: "Subscription resumed successfully",
            subscription: %{
              id: subscription.id,
              status: subscription.status
            }
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: message}})
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
    |> json(%{
      success: true,
      data: stats
    })
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
      success: true,
      data: %{
        allowed: can_perform
      }
    })
  end

  # Private functions

  # Format plan for mobile clients (Android/iOS)
  defp format_plan_for_mobile(plan) do
    %{
      id: plan.id,
      name: plan.name,
      slug: plan.slug,
      description: plan.description || "",
      monthly_price: decimal_to_float(plan.price_monthly),
      yearly_price: decimal_to_float(plan.price_yearly),
      features: %{
        analytics: plan.has_advanced_analytics || false,
        calendar_sync: plan.has_calendar_sync || false,
        api_access: plan.has_api_access || false,
        custom_themes: plan.has_custom_themes || false,
        priority_support: plan.has_priority_support || false,
        team_features: plan.has_team_features || false,
        white_label_options: plan.has_white_label || false
      },
      limits: %{
        max_buttons: plan.max_buttons,
        max_friends: plan.max_friends,
        max_clicks_per_month: plan.max_button_clicks_per_month,
        analytics_history_days: plan.max_analytics_history_days,
        export_history_days: plan.max_export_history_days
      },
      trial_days: plan.trial_days,
      is_active: plan.is_active || true,
      created_at: plan.inserted_at,
      updated_at: plan.updated_at
    }
  end

  # Convert Decimal to float for JSON serialization
  defp decimal_to_float(nil), do: 0.0
  defp decimal_to_float(%Decimal{} = decimal), do: Decimal.to_float(decimal)
  defp decimal_to_float(value) when is_float(value), do: value
  defp decimal_to_float(value) when is_integer(value), do: value / 1.0

  defp format_usage(usage) when is_map(usage) do
    %{
      buttons_used: Map.get(usage, :buttons_used, 0),
      friends_used: Map.get(usage, :friends_used, 0),
      clicks_this_month: Map.get(usage, :clicks_this_month, 0),
      last_reset_at: Map.get(usage, :last_reset_at)
    }
  end
  defp format_usage(_), do: %{buttons_used: 0, friends_used: 0, clicks_this_month: 0, last_reset_at: nil}

  # ============================================================================
  # Stripe Checkout & Portal
  # ============================================================================

  @doc """
  Create a Stripe Checkout session for subscribing to a plan.
  """
  def create_checkout_session(conn, %{"plan_id" => plan_id, "billing_cycle" => billing_cycle} = params) do
    user = conn.assigns.current_user
    billing_cycle = String.to_atom(billing_cycle)

    # Use get without ! to avoid raising an exception
    plan = Subscriptions.get_subscription_plan(plan_id)

    if is_nil(plan) do
      conn
      |> put_status(:not_found)
      |> json(%{success: false, error: %{message: "Plan not found"}})
    else
      opts = build_checkout_opts(params)

      case StripeService.create_checkout_session(user, plan, billing_cycle, opts) do
        {:ok, session} ->
          conn
          |> put_status(:ok)
          |> json(%{
            success: true,
            data: %{
              checkout_url: session.url,
              session_id: session.id
            }
          })

        {:error, :price_not_configured} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{success: false, error: %{message: "Stripe pricing is not configured for this plan"}})

        {:error, message} when is_binary(message) ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{success: false, error: %{message: message}})

        {:error, message} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{success: false, error: %{message: to_string(message)}})
      end
    end
  end

  @doc """
  Create a Stripe Customer Portal session for managing subscription.
  """
  def create_portal_session(conn, params) do
    user = conn.assigns.current_user
    return_url = Map.get(params, "return_url")

    case StripeService.create_portal_session(user, return_url) do
      {:ok, session} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: %{
            portal_url: session.url
          }
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: message}})
    end
  end

  # ============================================================================
  # Payment Methods
  # ============================================================================

  @doc """
  List all payment methods for the current user.
  """
  def list_payment_methods(conn, _params) do
    user = conn.assigns.current_user
    payment_methods = Subscriptions.list_payment_methods(user.id)

    conn
    |> put_status(:ok)
    |> json(%{
      payment_methods: Enum.map(payment_methods, &format_payment_method/1)
    })
  end

  @doc """
  Add a new payment method.
  """
  def add_payment_method(conn, %{"payment_method_id" => payment_method_id}) do
    user = conn.assigns.current_user

    case StripeService.attach_payment_method(user, payment_method_id) do
      {:ok, _pm} ->
        payment_methods = Subscriptions.list_payment_methods(user.id)
        conn
        |> put_status(:created)
        |> json(%{
          message: "Payment method added successfully",
          payment_methods: Enum.map(payment_methods, &format_payment_method/1)
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Remove a payment method.
  """
  def remove_payment_method(conn, %{"id" => payment_method_id}) do
    user = conn.assigns.current_user

    with {:ok, pm} <- get_user_payment_method(user.id, payment_method_id),
         :ok <- StripeService.detach_payment_method(pm.payment_provider_method_id),
         {:ok, _} <- Subscriptions.delete_payment_method(user.id, payment_method_id) do
      conn
      |> put_status(:ok)
      |> json(%{message: "Payment method removed successfully"})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Payment method not found"})

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Set a payment method as default.
  """
  def set_default_payment_method(conn, %{"id" => payment_method_id}) do
    user = conn.assigns.current_user

    case Subscriptions.set_default_payment_method(user.id, payment_method_id) do
      {:ok, _} ->
        payment_methods = Subscriptions.list_payment_methods(user.id)
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Default payment method updated",
          payment_methods: Enum.map(payment_methods, &format_payment_method/1)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Payment method not found"})

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  @doc """
  Create a Setup Intent for adding a payment method.
  """
  def create_setup_intent(conn, _params) do
    user = conn.assigns.current_user

    case StripeService.create_setup_intent(user) do
      {:ok, intent} ->
        conn
        |> put_status(:ok)
        |> json(%{
          client_secret: intent.client_secret
        })

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  # ============================================================================
  # Invoices
  # ============================================================================

  @doc """
  List all invoices for the current user.
  """
  def list_invoices(conn, params) do
    user = conn.assigns.current_user
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    offset = Map.get(params, "offset", "0") |> String.to_integer()

    invoices = Subscriptions.list_invoices(user.id, limit: limit, offset: offset)

    conn
    |> put_status(:ok)
    |> json(%{
      invoices: Enum.map(invoices, &format_invoice/1)
    })
  end

  @doc """
  Show a single invoice.
  """
  def show_invoice(conn, %{"id" => invoice_id}) do
    user = conn.assigns.current_user

    case Subscriptions.get_invoice(invoice_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Invoice not found"})

      invoice when invoice.user_id == user.id ->
        conn
        |> put_status(:ok)
        |> json(%{invoice: format_invoice(invoice)})

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Access denied"})
    end
  end

  # ============================================================================
  # Coupon Codes
  # ============================================================================

  @doc """
  Apply a coupon code.
  """
  def apply_coupon(conn, %{"code" => code}) do
    user = conn.assigns.current_user
    subscription = get_user_subscription_id(user.id)

    case Subscriptions.apply_coupon_code(user.id, code, subscription) do
      {:ok, {coupon, _user_coupon}} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Coupon applied successfully",
          coupon: %{
            code: coupon.code,
            discount: ButtonLog.Subscriptions.CouponCode.discount_display(coupon),
            duration: coupon.duration
          }
        })

      {:error, :invalid_code} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Invalid coupon code"})

      {:error, :coupon_expired} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "This coupon has expired"})

      {:error, :already_used} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "You have already used this coupon"})

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to apply coupon"})
    end
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp build_checkout_opts(params) do
    opts = []

    opts =
      if success_url = Map.get(params, "success_url") do
        Keyword.put(opts, :success_url, success_url)
      else
        opts
      end

    opts =
      if cancel_url = Map.get(params, "cancel_url") do
        Keyword.put(opts, :cancel_url, cancel_url)
      else
        opts
      end

    opts =
      if coupon_code = Map.get(params, "coupon_code") do
        Keyword.put(opts, :coupon_code, coupon_code)
      else
        opts
      end

    opts
  end

  defp get_user_payment_method(user_id, payment_method_id) do
    case Subscriptions.get_payment_method(payment_method_id) do
      nil -> {:error, :not_found}
      pm when pm.user_id == user_id -> {:ok, pm}
      _ -> {:error, :not_found}
    end
  end

  defp get_user_subscription_id(user_id) do
    case SubscriptionService.get_user_subscription(user_id) do
      %{subscription: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_payment_method(pm) do
    %{
      id: pm.id,
      card_brand: pm.card_brand,
      card_last_four: pm.card_last_four,
      card_exp_month: pm.card_exp_month,
      card_exp_year: pm.card_exp_year,
      is_default: pm.is_default,
      display: ButtonLog.Subscriptions.PaymentMethod.display_string(pm),
      expiration: ButtonLog.Subscriptions.PaymentMethod.expiration_string(pm)
    }
  end

  defp format_invoice(invoice) do
    %{
      id: invoice.id,
      invoice_number: invoice.invoice_number,
      status: invoice.status,
      amount_due: invoice.amount_due,
      amount_paid: invoice.amount_paid,
      currency: invoice.currency,
      invoice_date: invoice.invoice_date,
      due_date: invoice.due_date,
      paid_at: invoice.paid_at,
      hosted_invoice_url: invoice.hosted_invoice_url,
      pdf_url: invoice.pdf_url,
      line_items: invoice.line_items
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

