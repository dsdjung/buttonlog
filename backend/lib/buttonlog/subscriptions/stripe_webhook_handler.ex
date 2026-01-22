defmodule ButtonLog.Subscriptions.StripeWebhookHandler do
  @moduledoc """
  Handles incoming Stripe webhook events.

  Processes subscription lifecycle events, payment events,
  and invoice events from Stripe.
  """

  require Logger

  alias ButtonLog.Repo
  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.{
    UserSubscription,
    Invoice
  }

  @doc """
  Main entry point for handling Stripe webhook events.
  """
  def handle_event(event) do
    Logger.info("Handling Stripe webhook: #{event.type}")

    case event.type do
      # Checkout events
      "checkout.session.completed" ->
        handle_checkout_completed(event.data.object)

      # Subscription lifecycle events
      "customer.subscription.created" ->
        handle_subscription_created(event.data.object)

      "customer.subscription.updated" ->
        handle_subscription_updated(event.data.object)

      "customer.subscription.deleted" ->
        handle_subscription_deleted(event.data.object)

      "customer.subscription.trial_will_end" ->
        handle_trial_will_end(event.data.object)

      # Payment events
      "invoice.payment_succeeded" ->
        handle_payment_succeeded(event.data.object)

      "invoice.payment_failed" ->
        handle_payment_failed(event.data.object)

      "invoice.paid" ->
        handle_invoice_paid(event.data.object)

      "invoice.created" ->
        handle_invoice_created(event.data.object)

      "invoice.finalized" ->
        handle_invoice_finalized(event.data.object)

      # Payment method events
      "payment_method.attached" ->
        handle_payment_method_attached(event.data.object)

      "payment_method.detached" ->
        handle_payment_method_detached(event.data.object)

      # Customer events
      "customer.updated" ->
        handle_customer_updated(event.data.object)

      # Unhandled events
      _ ->
        Logger.debug("Unhandled Stripe event: #{event.type}")
        :ok
    end
  end

  # ============================================================================
  # Checkout Events
  # ============================================================================

  defp handle_checkout_completed(session) do
    Logger.info("Checkout completed for session: #{session.id}")

    user_id = session.metadata["user_id"]
    _plan_id = session.metadata["plan_id"]
    _billing_cycle = String.to_atom(session.metadata["billing_cycle"] || "monthly")

    case session.mode do
      "subscription" ->
        # Subscription checkout - the subscription.created event will handle the details
        Logger.info("Subscription checkout completed for user #{user_id}")
        :ok

      "setup" ->
        # Setup mode for adding payment method
        Logger.info("Setup checkout completed for user #{user_id}")
        :ok

      _ ->
        :ok
    end
  end

  # ============================================================================
  # Subscription Lifecycle Events
  # ============================================================================

  defp handle_subscription_created(subscription) do
    Logger.info("Subscription created: #{subscription.id}")

    user_id = subscription.metadata["user_id"]
    plan_id = subscription.metadata["plan_id"]

    with {:ok, user_id} <- parse_uuid(user_id),
         {:ok, plan_id} <- parse_uuid(plan_id),
         plan when not is_nil(plan) <- Subscriptions.get_subscription_plan!(plan_id) do

      # Determine billing cycle from price
      billing_cycle = determine_billing_cycle(subscription)

      # Calculate amount from subscription
      amount = calculate_amount(subscription)

      attrs = %{
        user_id: user_id,
        subscription_plan_id: plan_id,
        status: map_stripe_status(subscription.status),
        billing_cycle: billing_cycle,
        amount: amount,
        currency: String.upcase(subscription.currency || "usd"),
        payment_provider: "stripe",
        payment_provider_subscription_id: subscription.id,
        payment_provider_customer_id: subscription.customer,
        current_period_start: unix_to_datetime(subscription.current_period_start),
        current_period_end: unix_to_datetime(subscription.current_period_end),
        next_billing_date: unix_to_datetime(subscription.current_period_end)
      }

      # Add trial dates if present
      attrs =
        if subscription.trial_start do
          attrs
          |> Map.put(:trial_start, unix_to_datetime(subscription.trial_start))
          |> Map.put(:trial_end, unix_to_datetime(subscription.trial_end))
        else
          attrs
        end

      case Subscriptions.create_user_subscription(attrs) do
        {:ok, user_sub} ->
          Subscriptions.record_subscription_event(user_sub.id, :created, %{
            stripe_subscription_id: subscription.id,
            plan_id: plan_id
          })
          Logger.info("Created user subscription #{user_sub.id}")
          :ok

        {:error, changeset} ->
          Logger.error("Failed to create subscription: #{inspect(changeset.errors)}")
          {:error, :failed_to_create}
      end
    else
      _ ->
        Logger.error("Invalid user_id or plan_id in subscription metadata")
        {:error, :invalid_metadata}
    end
  end

  defp handle_subscription_updated(subscription) do
    Logger.info("Subscription updated: #{subscription.id}")

    case find_user_subscription(subscription.id) do
      nil ->
        Logger.warning("No local subscription found for Stripe subscription #{subscription.id}")
        :ok

      user_sub ->
        attrs = %{
          status: map_stripe_status(subscription.status),
          current_period_start: unix_to_datetime(subscription.current_period_start),
          current_period_end: unix_to_datetime(subscription.current_period_end),
          next_billing_date: unix_to_datetime(subscription.current_period_end)
        }

        # Handle cancellation
        attrs =
          if subscription.cancel_at_period_end do
            Map.put(attrs, :canceled_at, DateTime.utc_now())
          else
            attrs
          end

        case Subscriptions.update_user_subscription(user_sub, attrs) do
          {:ok, updated} ->
            Subscriptions.record_subscription_event(updated.id, :plan_changed, %{
              old_status: user_sub.status,
              new_status: attrs.status
            })
            :ok

          {:error, _} ->
            {:error, :failed_to_update}
        end
    end
  end

  defp handle_subscription_deleted(subscription) do
    Logger.info("Subscription deleted: #{subscription.id}")

    case find_user_subscription(subscription.id) do
      nil ->
        :ok

      user_sub ->
        attrs = %{
          status: :canceled,
          canceled_at: DateTime.utc_now()
        }

        case Subscriptions.update_user_subscription(user_sub, attrs) do
          {:ok, updated} ->
            Subscriptions.record_subscription_event(updated.id, :canceled, %{
              stripe_subscription_id: subscription.id
            })
            :ok

          {:error, _} ->
            {:error, :failed_to_cancel}
        end
    end
  end

  defp handle_trial_will_end(subscription) do
    Logger.info("Trial ending soon for subscription: #{subscription.id}")

    case find_user_subscription(subscription.id) do
      nil -> :ok
      user_sub ->
        # Record event for notification purposes
        Subscriptions.record_subscription_event(user_sub.id, :trial_ended, %{
          trial_end: unix_to_datetime(subscription.trial_end)
        })

        # TODO: Send email notification about trial ending
        :ok
    end
  end

  # ============================================================================
  # Payment Events
  # ============================================================================

  defp handle_payment_succeeded(invoice) do
    Logger.info("Payment succeeded for invoice: #{invoice.id}")

    case find_user_subscription_by_stripe_sub(invoice.subscription) do
      nil ->
        :ok

      user_sub ->
        # Record billing event
        Subscriptions.record_billing_event(
          user_sub.id,
          :payment_succeeded,
          :succeeded,
          %{
            amount: Decimal.new(invoice.amount_paid) |> Decimal.div(100),
            currency: String.upcase(invoice.currency),
            payment_provider: "stripe",
            payment_provider_event_id: invoice.id
          }
        )

        # Update subscription status if it was past_due
        if user_sub.status == :past_due do
          Subscriptions.update_user_subscription(user_sub, %{status: :active})
        end

        :ok
    end
  end

  defp handle_payment_failed(invoice) do
    Logger.info("Payment failed for invoice: #{invoice.id}")

    case find_user_subscription_by_stripe_sub(invoice.subscription) do
      nil ->
        :ok

      user_sub ->
        # Record billing event
        Subscriptions.record_billing_event(
          user_sub.id,
          :payment_failed,
          :failed,
          %{
            amount: Decimal.new(invoice.amount_due) |> Decimal.div(100),
            currency: String.upcase(invoice.currency),
            payment_provider: "stripe",
            payment_provider_event_id: invoice.id,
            metadata: %{
              attempt_count: invoice.attempt_count,
              next_attempt: invoice.next_payment_attempt
            }
          }
        )

        # Update subscription status to past_due
        Subscriptions.update_user_subscription(user_sub, %{status: :past_due})

        # TODO: Send email notification about failed payment

        :ok
    end
  end

  defp handle_invoice_created(invoice) do
    Logger.info("Invoice created: #{invoice.id}")

    case find_user_subscription_by_stripe_sub(invoice.subscription) do
      nil ->
        :ok

      user_sub ->
        attrs = %{
          user_id: user_sub.user_id,
          user_subscription_id: user_sub.id,
          status: :draft,
          amount_due: Decimal.new(invoice.amount_due) |> Decimal.div(100),
          currency: String.upcase(invoice.currency),
          invoice_date: unix_to_datetime(invoice.created),
          due_date: unix_to_datetime(invoice.due_date),
          payment_provider: "stripe",
          payment_provider_invoice_id: invoice.id,
          hosted_invoice_url: invoice.hosted_invoice_url,
          line_items: map_line_items(invoice.lines),
          subtotal: Decimal.new(invoice.subtotal || 0) |> Decimal.div(100),
          tax_amount: Decimal.new(invoice.tax || 0) |> Decimal.div(100)
        }

        Subscriptions.create_invoice(attrs)
        :ok
    end
  end

  defp handle_invoice_finalized(invoice) do
    Logger.info("Invoice finalized: #{invoice.id}")

    case Subscriptions.get_invoice_by_stripe_id(invoice.id) do
      nil -> :ok
      local_invoice ->
        Subscriptions.update_invoice(local_invoice, %{
          status: :open,
          hosted_invoice_url: invoice.hosted_invoice_url,
          pdf_url: invoice.invoice_pdf
        })
    end

    :ok
  end

  defp handle_invoice_paid(invoice) do
    Logger.info("Invoice paid: #{invoice.id}")

    case find_invoice_by_stripe_id(invoice.id) do
      nil -> :ok
      local_invoice ->
        Subscriptions.mark_invoice_paid(local_invoice.id, %{
          charge_id: invoice.charge
        })
    end

    :ok
  end

  # ============================================================================
  # Payment Method Events
  # ============================================================================

  defp handle_payment_method_attached(payment_method) do
    Logger.info("Payment method attached: #{payment_method.id}")
    # Payment method creation is handled by StripeService.attach_payment_method
    :ok
  end

  defp handle_payment_method_detached(payment_method) do
    Logger.info("Payment method detached: #{payment_method.id}")

    # Mark local payment method as inactive
    case find_payment_method(payment_method.id) do
      nil -> :ok
      pm ->
        pm
        |> Ecto.Changeset.change(%{is_active: false})
        |> Repo.update()
    end

    :ok
  end

  # ============================================================================
  # Customer Events
  # ============================================================================

  defp handle_customer_updated(customer) do
    Logger.debug("Customer updated: #{customer.id}")
    # Could sync customer details if needed
    :ok
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp find_user_subscription(stripe_subscription_id) do
    import Ecto.Query

    from(us in UserSubscription,
      where: us.payment_provider_subscription_id == ^stripe_subscription_id,
      limit: 1
    )
    |> Repo.one()
  end

  defp find_user_subscription_by_stripe_sub(nil), do: nil
  defp find_user_subscription_by_stripe_sub(stripe_subscription_id) do
    find_user_subscription(stripe_subscription_id)
  end

  defp find_invoice_by_stripe_id(stripe_invoice_id) do
    import Ecto.Query

    from(i in Invoice,
      where: i.payment_provider_invoice_id == ^stripe_invoice_id,
      limit: 1
    )
    |> Repo.one()
  end

  defp find_payment_method(stripe_payment_method_id) do
    import Ecto.Query

    from(pm in ButtonLog.Subscriptions.PaymentMethod,
      where: pm.payment_provider_method_id == ^stripe_payment_method_id,
      limit: 1
    )
    |> Repo.one()
  end

  defp map_stripe_status(status) do
    case status do
      "active" -> :active
      "past_due" -> :past_due
      "unpaid" -> :unpaid
      "canceled" -> :canceled
      "incomplete" -> :unpaid
      "incomplete_expired" -> :canceled
      "trialing" -> :trialing
      "paused" -> :paused
      _ -> :active
    end
  end

  defp determine_billing_cycle(subscription) do
    # Try to determine from the price interval
    case subscription.items.data do
      [%{price: %{recurring: %{interval: "year"}}} | _] -> :yearly
      [%{price: %{recurring: %{interval: "month"}}} | _] -> :monthly
      _ -> :monthly
    end
  rescue
    _ -> :monthly
  end

  defp calculate_amount(subscription) do
    # Get amount from the subscription items
    case subscription.items.data do
      [%{price: %{unit_amount: amount}} | _] when is_integer(amount) ->
        Decimal.new(amount) |> Decimal.div(100)
      _ ->
        Decimal.new(0)
    end
  rescue
    _ -> Decimal.new(0)
  end

  defp unix_to_datetime(nil), do: nil
  defp unix_to_datetime(unix_timestamp) when is_integer(unix_timestamp) do
    DateTime.from_unix!(unix_timestamp)
  end

  defp parse_uuid(nil), do: {:error, :invalid_uuid}
  defp parse_uuid(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, :invalid_uuid}
    end
  end

  defp map_line_items(%{data: items}) when is_list(items) do
    Enum.map(items, fn item ->
      %{
        description: item.description,
        amount: item.amount,
        quantity: item.quantity,
        period_start: item.period.start,
        period_end: item.period.end
      }
    end)
  end
  defp map_line_items(_), do: []
end
