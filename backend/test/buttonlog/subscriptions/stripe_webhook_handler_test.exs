defmodule ButtonLog.Subscriptions.StripeWebhookHandlerTest do
  use ButtonLog.DataCase

  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.StripeWebhookHandler
  alias ButtonLog.Subscriptions.{UserSubscription, Invoice}

  @moduletag :stripe_webhook_handler

  describe "handle_event/1 - checkout.session.completed" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      %{user: user, plan: plan}
    end

    test "handles subscription checkout completion", %{user: user, plan: plan} do
      event = build_stripe_event("checkout.session.completed", %{
        id: "cs_test_#{unique_id()}",
        mode: "subscription",
        customer: "cus_test_#{unique_id()}",
        subscription: "sub_test_#{unique_id()}",
        metadata: %{
          "user_id" => user.id,
          "plan_id" => plan.id,
          "billing_cycle" => "monthly"
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(event)
    end

    test "handles setup checkout completion", %{user: user, plan: plan} do
      event = build_stripe_event("checkout.session.completed", %{
        id: "cs_test_#{unique_id()}",
        mode: "setup",
        customer: "cus_test_#{unique_id()}",
        metadata: %{
          "user_id" => user.id,
          "plan_id" => plan.id,
          "billing_cycle" => "monthly"
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(event)
    end
  end

  describe "handle_event/1 - customer.subscription.created" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      %{user: user, plan: plan}
    end

    test "creates user subscription from Stripe subscription", %{user: user, plan: plan} do
      stripe_sub_id = "sub_test_#{unique_id()}"
      now = DateTime.utc_now() |> DateTime.to_unix()
      period_end = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()

      event = build_stripe_event("customer.subscription.created", %{
        id: stripe_sub_id,
        customer: "cus_test_#{unique_id()}",
        status: "active",
        currency: "usd",
        current_period_start: now,
        current_period_end: period_end,
        metadata: %{
          "user_id" => user.id,
          "plan_id" => plan.id
        },
        items: %{
          data: [
            %{
              price: %{
                unit_amount: 999,
                recurring: %{interval: "month"}
              }
            }
          ]
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      # Verify subscription was created
      subscriptions = list_user_subscriptions(user.id)
      assert length(subscriptions) == 1

      sub = hd(subscriptions)
      assert sub.payment_provider_subscription_id == stripe_sub_id
      assert sub.status == :active
      assert sub.billing_cycle == :monthly
    end

    test "creates subscription with trial period", %{user: user, plan: plan} do
      now = DateTime.utc_now() |> DateTime.to_unix()
      trial_end = DateTime.utc_now() |> DateTime.add(14, :day) |> DateTime.to_unix()
      period_end = DateTime.utc_now() |> DateTime.add(44, :day) |> DateTime.to_unix()

      event = build_stripe_event("customer.subscription.created", %{
        id: "sub_test_#{unique_id()}",
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
          data: [
            %{price: %{unit_amount: 999, recurring: %{interval: "month"}}}
          ]
        }
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      subscriptions = list_user_subscriptions(user.id)
      sub = hd(subscriptions)
      assert sub.status == :trialing
      assert sub.trial_start != nil
      assert sub.trial_end != nil
    end

    test "returns error for invalid user_id", %{plan: plan} do
      event = build_stripe_event("customer.subscription.created", %{
        id: "sub_test_#{unique_id()}",
        customer: "cus_test_#{unique_id()}",
        status: "active",
        currency: "usd",
        current_period_start: DateTime.utc_now() |> DateTime.to_unix(),
        current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
        metadata: %{
          "user_id" => "invalid-uuid",
          "plan_id" => plan.id
        },
        items: %{data: [%{price: %{unit_amount: 999, recurring: %{interval: "month"}}}]}
      })

      assert {:error, :invalid_metadata} = StripeWebhookHandler.handle_event(event)
    end
  end

  describe "handle_event/1 - customer.subscription.updated" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, user_sub} = create_user_subscription(user.id, plan.id)
      %{user: user, plan: plan, user_sub: user_sub}
    end

    test "updates subscription status", %{user_sub: user_sub} do
      event = build_stripe_event("customer.subscription.updated", %{
        id: user_sub.payment_provider_subscription_id,
        status: "past_due",
        current_period_start: DateTime.utc_now() |> DateTime.to_unix(),
        current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
        cancel_at_period_end: false
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      updated = Repo.get!(UserSubscription, user_sub.id)
      assert updated.status == :past_due
    end

    test "handles cancellation at period end", %{user_sub: user_sub} do
      event = build_stripe_event("customer.subscription.updated", %{
        id: user_sub.payment_provider_subscription_id,
        status: "active",
        current_period_start: DateTime.utc_now() |> DateTime.to_unix(),
        current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
        cancel_at_period_end: true
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      updated = Repo.get!(UserSubscription, user_sub.id)
      assert updated.canceled_at != nil
    end

    test "handles unknown subscription gracefully" do
      event = build_stripe_event("customer.subscription.updated", %{
        id: "sub_nonexistent_#{unique_id()}",
        status: "active",
        current_period_start: DateTime.utc_now() |> DateTime.to_unix(),
        current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
        cancel_at_period_end: false
      })

      # Should return :ok even for unknown subscription
      assert :ok = StripeWebhookHandler.handle_event(event)
    end
  end

  describe "handle_event/1 - customer.subscription.deleted" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, user_sub} = create_user_subscription(user.id, plan.id)
      %{user: user, plan: plan, user_sub: user_sub}
    end

    test "marks subscription as canceled", %{user_sub: user_sub} do
      event = build_stripe_event("customer.subscription.deleted", %{
        id: user_sub.payment_provider_subscription_id,
        status: "canceled"
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      updated = Repo.get!(UserSubscription, user_sub.id)
      assert updated.status == :canceled
      assert updated.canceled_at != nil
    end
  end

  describe "handle_event/1 - invoice.payment_succeeded" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, user_sub} = create_user_subscription(user.id, plan.id, %{status: :past_due})
      %{user: user, plan: plan, user_sub: user_sub}
    end

    test "records billing event and updates subscription status", %{user_sub: user_sub} do
      event = build_stripe_event("invoice.payment_succeeded", %{
        id: "in_test_#{unique_id()}",
        subscription: user_sub.payment_provider_subscription_id,
        amount_paid: 999,
        currency: "usd"
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      # Check subscription was reactivated
      updated = Repo.get!(UserSubscription, user_sub.id)
      assert updated.status == :active

      # Check billing event was recorded
      events = Subscriptions.list_billing_events(user_sub.id)
      assert length(events) == 1
      assert hd(events).event_type == :payment_succeeded
    end
  end

  describe "handle_event/1 - invoice.payment_failed" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, user_sub} = create_user_subscription(user.id, plan.id)
      %{user: user, plan: plan, user_sub: user_sub}
    end

    test "records billing event and marks subscription as past_due", %{user_sub: user_sub} do
      event = build_stripe_event("invoice.payment_failed", %{
        id: "in_test_#{unique_id()}",
        subscription: user_sub.payment_provider_subscription_id,
        amount_due: 999,
        currency: "usd",
        attempt_count: 1,
        next_payment_attempt: DateTime.utc_now() |> DateTime.add(3, :day) |> DateTime.to_unix()
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      # Check subscription status
      updated = Repo.get!(UserSubscription, user_sub.id)
      assert updated.status == :past_due

      # Check billing event was recorded
      events = Subscriptions.list_billing_events(user_sub.id)
      assert length(events) == 1
      assert hd(events).event_type == :payment_failed
      assert hd(events).status == :failed
    end
  end

  describe "handle_event/1 - invoice lifecycle" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, user_sub} = create_user_subscription(user.id, plan.id)
      %{user: user, plan: plan, user_sub: user_sub}
    end

    test "creates local invoice on invoice.created", %{user_sub: user_sub} do
      stripe_invoice_id = "in_test_#{unique_id()}"
      now = DateTime.utc_now() |> DateTime.to_unix()
      due = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()

      event = build_stripe_event("invoice.created", %{
        id: stripe_invoice_id,
        subscription: user_sub.payment_provider_subscription_id,
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

      assert :ok = StripeWebhookHandler.handle_event(event)

      # Verify invoice was created
      invoice = Subscriptions.get_invoice_by_stripe_id(stripe_invoice_id)
      assert invoice != nil
      assert invoice.user_id == user_sub.user_id
      assert invoice.status == :draft
    end

    test "finalizes invoice on invoice.finalized", %{user_sub: user_sub} do
      # First create an invoice
      stripe_invoice_id = "in_test_#{unique_id()}"
      {:ok, invoice} = Subscriptions.create_invoice(%{
        user_id: user_sub.user_id,
        user_subscription_id: user_sub.id,
        status: :draft,
        amount_due: Decimal.new("9.99"),
        invoice_date: DateTime.utc_now(),
        payment_provider: "stripe",
        payment_provider_invoice_id: stripe_invoice_id
      })

      event = build_stripe_event("invoice.finalized", %{
        id: stripe_invoice_id,
        hosted_invoice_url: "https://invoice.stripe.com/#{stripe_invoice_id}/finalized",
        invoice_pdf: "https://invoice.stripe.com/#{stripe_invoice_id}/pdf"
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      # Verify invoice was updated
      updated = Repo.get!(Invoice, invoice.id)
      assert updated.status == :open
    end

    test "marks invoice paid on invoice.paid", %{user_sub: user_sub} do
      stripe_invoice_id = "in_test_#{unique_id()}"
      {:ok, invoice} = Subscriptions.create_invoice(%{
        user_id: user_sub.user_id,
        user_subscription_id: user_sub.id,
        status: :open,
        amount_due: Decimal.new("9.99"),
        invoice_date: DateTime.utc_now(),
        payment_provider: "stripe",
        payment_provider_invoice_id: stripe_invoice_id
      })

      event = build_stripe_event("invoice.paid", %{
        id: stripe_invoice_id,
        charge: "ch_test_#{unique_id()}"
      })

      assert :ok = StripeWebhookHandler.handle_event(event)

      # Verify invoice was marked paid
      updated = Repo.get!(Invoice, invoice.id)
      assert updated.status == :paid
      assert updated.paid_at != nil
    end
  end

  describe "handle_event/1 - unhandled events" do
    test "returns :ok for unhandled event types" do
      event = build_stripe_event("some.unknown.event", %{id: "test_#{unique_id()}"})
      assert :ok = StripeWebhookHandler.handle_event(event)
    end

    test "handles customer.updated event" do
      event = build_stripe_event("customer.updated", %{
        id: "cus_test_#{unique_id()}",
        email: "updated@example.com"
      })
      assert :ok = StripeWebhookHandler.handle_event(event)
    end

    test "handles payment_method.attached event" do
      event = build_stripe_event("payment_method.attached", %{
        id: "pm_test_#{unique_id()}",
        customer: "cus_test_#{unique_id()}",
        type: "card"
      })
      assert :ok = StripeWebhookHandler.handle_event(event)
    end
  end

  describe "status mapping" do
    test "maps all Stripe subscription statuses correctly" do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, user_sub} = create_user_subscription(user.id, plan.id)

      statuses = [
        {"active", :active},
        {"past_due", :past_due},
        {"unpaid", :unpaid},
        {"canceled", :canceled},
        {"incomplete", :unpaid},
        {"incomplete_expired", :canceled},
        {"trialing", :trialing},
        {"paused", :paused}
      ]

      for {stripe_status, expected_status} <- statuses do
        event = build_stripe_event("customer.subscription.updated", %{
          id: user_sub.payment_provider_subscription_id,
          status: stripe_status,
          current_period_start: DateTime.utc_now() |> DateTime.to_unix(),
          current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
          cancel_at_period_end: false
        })

        assert :ok = StripeWebhookHandler.handle_event(event)

        updated = Repo.get!(UserSubscription, user_sub.id)
        assert updated.status == expected_status,
          "Expected status #{expected_status} for Stripe status #{stripe_status}, got #{updated.status}"
      end
    end
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp unique_id, do: System.unique_integer([:positive])

  defp build_stripe_event(type, data) do
    # Build an event structure that mimics Stripe's API response
    # Keys are atoms for dot access, but metadata stays as string keys
    %{
      id: "evt_test_#{unique_id()}",
      type: type,
      data: %{
        object: convert_to_stripe_struct(data)
      }
    }
  end

  # Convert map to Stripe-like struct with dot access
  # IMPORTANT: metadata keys must stay as strings
  defp convert_to_stripe_struct(map) when is_map(map) do
    map
    |> Enum.map(fn
      # Keep metadata as-is (with string keys)
      {:metadata, v} -> {:metadata, v}
      {"metadata", v} -> {:metadata, v}
      # Convert nested maps
      {k, v} when is_map(v) -> {to_atom(k), convert_to_stripe_struct(v)}
      # Keep other values
      {k, v} -> {to_atom(k), v}
    end)
    |> Enum.into(%{})
  end
  defp convert_to_stripe_struct(value), do: value

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

  defp create_user_subscription(user_id, plan_id, attrs \\ %{}) do
    stripe_sub_id = "sub_test_#{unique_id()}"

    default_attrs = %{
      user_id: user_id,
      subscription_plan_id: plan_id,
      status: :active,
      billing_cycle: :monthly,
      amount: Decimal.new("9.99"),
      currency: "USD",
      payment_provider: "stripe",
      payment_provider_subscription_id: stripe_sub_id,
      current_period_start: DateTime.utc_now(),
      current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
    }

    Subscriptions.create_user_subscription(Map.merge(default_attrs, attrs))
  end

  defp list_user_subscriptions(user_id) do
    import Ecto.Query

    from(us in UserSubscription, where: us.user_id == ^user_id)
    |> Repo.all()
  end
end
