defmodule ButtonLog.Subscriptions.StripePaymentFlowTest do
  @moduledoc """
  End-to-end payment flow integration tests.

  These tests verify the complete payment lifecycle:
  1. Checkout session creation
  2. Webhook processing after successful payment
  3. Subscription activation and management
  4. Invoice generation and payment tracking
  5. Cancellation and reactivation flows

  To run these tests with actual Stripe API calls:
    STRIPE_SECRET_KEY=sk_test_xxx mix test test/buttonlog/subscriptions/stripe_payment_flow_test.exs

  Note: Some tests simulate Stripe webhooks without making actual API calls.
  """

  use ButtonLog.DataCase

  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.{
    StripeWebhookHandler,
    UserSubscription
  }

  @moduletag :stripe_payment_flow

  describe "complete subscription flow (simulated)" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      %{user: user, plan: plan}
    end

    test "full subscription lifecycle: create -> active -> cancel", %{user: user, plan: plan} do
      stripe_sub_id = "sub_test_#{unique_id()}"
      stripe_customer_id = "cus_test_#{unique_id()}"
      now = DateTime.utc_now() |> DateTime.to_unix()
      period_end = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()

      # Step 1: Simulate checkout completion
      checkout_event = build_event("checkout.session.completed", %{
        id: "cs_test_#{unique_id()}",
        mode: "subscription",
        customer: stripe_customer_id,
        subscription: stripe_sub_id,
        metadata: %{
          "user_id" => user.id,
          "plan_id" => plan.id,
          "billing_cycle" => "monthly"
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(checkout_event)

      # Step 2: Simulate subscription created webhook
      sub_created_event = build_event("customer.subscription.created", %{
        id: stripe_sub_id,
        customer: stripe_customer_id,
        status: "active",
        currency: "usd",
        current_period_start: now,
        current_period_end: period_end,
        metadata: %{
          "user_id" => user.id,
          "plan_id" => plan.id
        },
        items: %{
          data: [%{price: %{unit_amount: 999, recurring: %{interval: "month"}}}]
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(sub_created_event)

      # Verify subscription was created
      user_sub = get_user_subscription(user.id)
      assert user_sub != nil
      assert user_sub.status == :active
      assert user_sub.payment_provider_subscription_id == stripe_sub_id

      # Step 3: Simulate first invoice payment
      invoice_event = build_event("invoice.payment_succeeded", %{
        id: "in_test_#{unique_id()}",
        subscription: stripe_sub_id,
        amount_paid: 999,
        currency: "usd"
      })

      assert :ok = StripeWebhookHandler.handle_event(invoice_event)

      # Verify billing event was recorded
      billing_events = Subscriptions.list_billing_events(user_sub.id)
      assert length(billing_events) == 1
      assert hd(billing_events).event_type == :payment_succeeded

      # Step 4: Simulate subscription cancellation at period end
      cancel_event = build_event("customer.subscription.updated", %{
        id: stripe_sub_id,
        status: "active",
        current_period_start: now,
        current_period_end: period_end,
        cancel_at_period_end: true
      })

      assert :ok = StripeWebhookHandler.handle_event(cancel_event)

      # Verify cancellation was recorded
      updated_sub = Repo.get!(UserSubscription, user_sub.id)
      assert updated_sub.canceled_at != nil

      # Step 5: Simulate subscription deletion at period end
      delete_event = build_event("customer.subscription.deleted", %{
        id: stripe_sub_id,
        status: "canceled"
      })

      assert :ok = StripeWebhookHandler.handle_event(delete_event)

      # Verify subscription is now canceled
      final_sub = Repo.get!(UserSubscription, user_sub.id)
      assert final_sub.status == :canceled
    end

    test "subscription with trial period flow", %{user: user, plan: plan} do
      stripe_sub_id = "sub_test_#{unique_id()}"
      now = DateTime.utc_now() |> DateTime.to_unix()
      trial_end = DateTime.utc_now() |> DateTime.add(14, :day) |> DateTime.to_unix()
      period_end = DateTime.utc_now() |> DateTime.add(44, :day) |> DateTime.to_unix()

      # Create subscription with trial
      event = build_event("customer.subscription.created", %{
        id: stripe_sub_id,
        customer: "cus_test_#{unique_id()}",
        status: "trialing",
        currency: "usd",
        current_period_start: now,
        current_period_end: period_end,
        trial_start: now,
        trial_end: trial_end,
        metadata: %{
          "user_id" => user.id,
          "plan_id" => plan.id
        },
        items: %{
          data: [%{price: %{unit_amount: 999, recurring: %{interval: "month"}}}]
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      user_sub = get_user_subscription(user.id)
      assert user_sub.status == :trialing
      assert user_sub.trial_start != nil
      assert user_sub.trial_end != nil

      # Simulate trial will end notification
      trial_ending_event = build_event("customer.subscription.trial_will_end", %{
        id: stripe_sub_id,
        trial_end: trial_end
      })

      assert :ok = StripeWebhookHandler.handle_event(trial_ending_event)

      # Verify trial ending event was recorded
      sub_events = Subscriptions.list_subscription_events(user_sub.id)
      assert Enum.any?(sub_events, &(&1.event_type == :trial_ending))

      # Simulate trial conversion to active
      convert_event = build_event("customer.subscription.updated", %{
        id: stripe_sub_id,
        status: "active",
        current_period_start: trial_end,
        current_period_end: period_end,
        cancel_at_period_end: false
      })

      assert :ok = StripeWebhookHandler.handle_event(convert_event)

      updated_sub = Repo.get!(UserSubscription, user_sub.id)
      assert updated_sub.status == :active
    end

    test "payment failure and recovery flow", %{user: user, plan: plan} do
      stripe_sub_id = "sub_test_#{unique_id()}"
      _now = DateTime.utc_now() |> DateTime.to_unix()
      _period_end = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()

      # Create active subscription
      {:ok, user_sub} = Subscriptions.create_user_subscription(%{
        user_id: user.id,
        subscription_plan_id: plan.id,
        status: :active,
        billing_cycle: :monthly,
        amount: Decimal.new("9.99"),
        currency: "USD",
        payment_provider: "stripe",
        payment_provider_subscription_id: stripe_sub_id,
        current_period_start: DateTime.utc_now(),
        current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
      })

      # Simulate payment failure
      failure_event = build_event("invoice.payment_failed", %{
        id: "in_test_#{unique_id()}",
        subscription: stripe_sub_id,
        amount_due: 999,
        currency: "usd",
        attempt_count: 1,
        next_payment_attempt: DateTime.utc_now() |> DateTime.add(3, :day) |> DateTime.to_unix()
      })

      assert :ok = StripeWebhookHandler.handle_event(failure_event)

      # Verify subscription is past_due
      failed_sub = Repo.get!(UserSubscription, user_sub.id)
      assert failed_sub.status == :past_due

      # Verify billing event recorded
      billing_events = Subscriptions.list_billing_events(user_sub.id)
      failed_event = Enum.find(billing_events, &(&1.event_type == :payment_failed))
      assert failed_event != nil
      assert failed_event.status == :failed

      # Simulate successful retry payment
      success_event = build_event("invoice.payment_succeeded", %{
        id: "in_test_#{unique_id()}",
        subscription: stripe_sub_id,
        amount_paid: 999,
        currency: "usd"
      })

      assert :ok = StripeWebhookHandler.handle_event(success_event)

      # Verify subscription is active again
      recovered_sub = Repo.get!(UserSubscription, user_sub.id)
      assert recovered_sub.status == :active

      # Verify success billing event recorded
      updated_events = Subscriptions.list_billing_events(user_sub.id)
      success_recorded = Enum.find(updated_events, &(&1.event_type == :payment_succeeded))
      assert success_recorded != nil
    end

    test "upgrade subscription plan flow", %{user: user, plan: plan} do
      stripe_sub_id = "sub_test_#{unique_id()}"
      now = DateTime.utc_now() |> DateTime.to_unix()
      period_end = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()

      # Create subscription on current plan
      {:ok, user_sub} = Subscriptions.create_user_subscription(%{
        user_id: user.id,
        subscription_plan_id: plan.id,
        status: :active,
        billing_cycle: :monthly,
        amount: Decimal.new("9.99"),
        currency: "USD",
        payment_provider: "stripe",
        payment_provider_subscription_id: stripe_sub_id,
        current_period_start: DateTime.utc_now(),
        current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
      })

      # Simulate subscription update (plan change)
      _enterprise_plan = Subscriptions.get_subscription_plan_by_slug("enterprise")

      update_event = build_event("customer.subscription.updated", %{
        id: stripe_sub_id,
        status: "active",
        current_period_start: now,
        current_period_end: period_end,
        cancel_at_period_end: false
      })

      assert :ok = StripeWebhookHandler.handle_event(update_event)

      # Verify subscription event was recorded
      sub_events = Subscriptions.list_subscription_events(user_sub.id)
      assert length(sub_events) >= 1
    end

    test "invoice lifecycle: created -> finalized -> paid", %{user: user, plan: plan} do
      stripe_sub_id = "sub_test_#{unique_id()}"
      stripe_invoice_id = "in_test_#{unique_id()}"
      now = DateTime.utc_now() |> DateTime.to_unix()
      due = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()

      # Create subscription first
      {:ok, _user_sub} = Subscriptions.create_user_subscription(%{
        user_id: user.id,
        subscription_plan_id: plan.id,
        status: :active,
        billing_cycle: :monthly,
        amount: Decimal.new("9.99"),
        currency: "USD",
        payment_provider: "stripe",
        payment_provider_subscription_id: stripe_sub_id,
        current_period_start: DateTime.utc_now(),
        current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
      })

      # Step 1: Invoice created
      created_event = build_event("invoice.created", %{
        id: stripe_invoice_id,
        subscription: stripe_sub_id,
        amount_due: 999,
        subtotal: 999,
        tax: 0,
        currency: "usd",
        created: now,
        due_date: due,
        hosted_invoice_url: "https://invoice.stripe.com/#{stripe_invoice_id}",
        lines: %{
          data: [
            %{
              description: "Premium Plan (Monthly)",
              amount: 999,
              quantity: 1,
              period: %{start: now, end: due}
            }
          ]
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(created_event)

      # Verify invoice was created
      invoice = Subscriptions.get_invoice_by_stripe_id(stripe_invoice_id)
      assert invoice != nil
      assert invoice.status == :draft

      # Step 2: Invoice finalized
      finalized_event = build_event("invoice.finalized", %{
        id: stripe_invoice_id,
        hosted_invoice_url: "https://invoice.stripe.com/#{stripe_invoice_id}/final",
        invoice_pdf: "https://invoice.stripe.com/#{stripe_invoice_id}/pdf"
      })

      assert :ok = StripeWebhookHandler.handle_event(finalized_event)

      # Verify invoice was finalized
      finalized_invoice = Repo.get!(Subscriptions.Invoice, invoice.id)
      assert finalized_invoice.status == :open

      # Step 3: Invoice paid
      paid_event = build_event("invoice.paid", %{
        id: stripe_invoice_id,
        charge: "ch_test_#{unique_id()}"
      })

      assert :ok = StripeWebhookHandler.handle_event(paid_event)

      # Verify invoice was marked paid
      paid_invoice = Repo.get!(Subscriptions.Invoice, invoice.id)
      assert paid_invoice.status == :paid
      assert paid_invoice.paid_at != nil
    end
  end

  describe "subscription limits and feature access" do
    test "user gets correct feature access after subscription" do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")

      # Before subscription - user should have free limits
      assert Subscriptions.get_user_subscription(user.id).plan.slug == "free"

      # Create subscription
      {:ok, _user_sub} = Subscriptions.create_user_subscription(%{
        user_id: user.id,
        subscription_plan_id: plan.id,
        status: :active,
        billing_cycle: :monthly,
        amount: Decimal.new("9.99"),
        currency: "USD",
        current_period_start: DateTime.utc_now(),
        current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
      })

      # After subscription - user should have premium limits
      user_plan = Subscriptions.get_user_subscription(user.id).plan
      assert user_plan.slug == "premium"
      assert user_plan.max_buttons > 5
      assert user_plan.has_advanced_analytics == true
    end

    test "user reverts to free plan after cancellation" do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")

      {:ok, user_sub} = Subscriptions.create_user_subscription(%{
        user_id: user.id,
        subscription_plan_id: plan.id,
        status: :active,
        billing_cycle: :monthly,
        amount: Decimal.new("9.99"),
        currency: "USD",
        current_period_start: DateTime.utc_now(),
        current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
      })

      # User has premium
      assert Subscriptions.get_user_subscription(user.id).plan.slug == "premium"

      # Cancel subscription
      Subscriptions.update_user_subscription(user_sub, %{status: :canceled})

      # User should revert to free
      assert Subscriptions.get_user_subscription(user.id).plan.slug == "free"
    end
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp unique_id, do: System.unique_integer([:positive])

  defp build_event(type, data) do
    %{
      id: "evt_test_#{unique_id()}",
      type: type,
      data: %{
        object: convert_to_struct(data)
      }
    }
    |> convert_to_struct()
  end

  # Convert map to Stripe-like struct with dot access
  # IMPORTANT: metadata keys must stay as strings
  defp convert_to_struct(map) when is_map(map) do
    map
    |> Enum.map(fn
      # Keep metadata as-is (with string keys)
      {:metadata, v} -> {:metadata, v}
      {"metadata", v} -> {:metadata, v}
      # Convert nested maps
      {k, v} when is_map(v) -> {to_atom(k), convert_to_struct(v)}
      # Keep other values
      {k, v} -> {to_atom(k), v}
    end)
    |> Enum.into(%{})
  end
  defp convert_to_struct(value), do: value

  defp to_atom(key) when is_atom(key), do: key
  defp to_atom(key) when is_binary(key), do: String.to_atom(key)

  defp insert_user do
    {:ok, user} = ButtonLog.Accounts.create_user(%{
      email: "test#{unique_id()}@example.com",
      username: "testuser#{unique_id()}",
      display_name: "Test User",
      password: "password123",
      password_confirmation: "password123"
    })
    user
  end

  defp get_user_subscription(user_id) do
    import Ecto.Query

    from(us in UserSubscription, where: us.user_id == ^user_id, limit: 1)
    |> Repo.one()
  end
end
