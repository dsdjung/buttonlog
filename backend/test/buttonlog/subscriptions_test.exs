defmodule ButtonLog.SubscriptionsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.{
    SubscriptionPlan,
    UserSubscription,
    PaymentMethod,
    Invoice,
    CouponCode,
    UserCoupon
  }

  describe "subscription_plans" do
    test "list_subscription_plans/0 returns all subscription plans" do
      # Plans are seeded by migration
      plans = Subscriptions.list_subscription_plans()
      assert length(plans) >= 3
      assert Enum.any?(plans, &(&1.slug == "free"))
      assert Enum.any?(plans, &(&1.slug == "premium"))
      assert Enum.any?(plans, &(&1.slug == "enterprise"))
    end

    test "get_subscription_plan_by_slug/1 returns the plan" do
      plan = Subscriptions.get_subscription_plan_by_slug("free")
      assert plan.name == "Free"
      assert plan.price_monthly == Decimal.new("0.00")
    end

    test "free_plan/0 returns correct limits" do
      plan = SubscriptionPlan.free_plan()
      assert plan.max_buttons == 5
      assert plan.max_friends == 10
      assert plan.has_advanced_analytics == false
    end

    test "premium_plan/0 returns correct limits" do
      plan = SubscriptionPlan.premium_plan()
      assert plan.max_buttons == 50
      assert plan.max_friends == 100
      assert plan.has_advanced_analytics == true
    end

    test "enterprise_plan/0 returns unlimited values" do
      plan = SubscriptionPlan.enterprise_plan()
      assert plan.max_buttons == -1
      assert SubscriptionPlan.is_unlimited(plan.max_buttons)
    end

    test "has_feature/2 returns correct feature access" do
      free = SubscriptionPlan.free_plan()
      premium = SubscriptionPlan.premium_plan()

      assert SubscriptionPlan.has_feature(premium, :advanced_analytics) == true
      assert SubscriptionPlan.has_feature(free, :advanced_analytics) == false
    end
  end

  describe "payment_methods" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "list_payment_methods/1 returns payment methods for user", %{user: user} do
      {:ok, _pm} = create_payment_method(user.id)

      methods = Subscriptions.list_payment_methods(user.id)
      assert length(methods) == 1
    end

    test "list_payment_methods/1 only returns active methods", %{user: user} do
      {:ok, pm1} = create_payment_method(user.id)
      {:ok, pm2} = create_payment_method(user.id, %{is_active: false})

      methods = Subscriptions.list_payment_methods(user.id)
      assert length(methods) == 1
      assert hd(methods).id == pm1.id
    end

    test "get_payment_method/1 returns the payment method", %{user: user} do
      {:ok, pm} = create_payment_method(user.id)

      result = Subscriptions.get_payment_method(pm.id)
      assert result.id == pm.id
    end

    test "create_payment_method/1 creates a payment method", %{user: user} do
      attrs = %{
        user_id: user.id,
        payment_provider: "stripe",
        payment_provider_method_id: "pm_test_#{System.unique_integer([:positive])}",
        card_brand: "visa",
        card_last_four: "4242",
        card_exp_month: 12,
        card_exp_year: DateTime.utc_now().year + 1
      }

      assert {:ok, pm} = Subscriptions.create_payment_method(attrs)
      assert pm.card_brand == "visa"
      assert pm.is_default == false
    end

    test "set_default_payment_method/2 sets the default", %{user: user} do
      {:ok, pm1} = create_payment_method(user.id, %{is_default: true})
      {:ok, pm2} = create_payment_method(user.id)

      assert {:ok, _} = Subscriptions.set_default_payment_method(user.id, pm2.id)

      # Refresh from database
      pm1_refreshed = Subscriptions.get_payment_method(pm1.id)
      pm2_refreshed = Subscriptions.get_payment_method(pm2.id)

      assert pm1_refreshed.is_default == false
      assert pm2_refreshed.is_default == true
    end

    test "delete_payment_method/2 deactivates the method", %{user: user} do
      {:ok, pm} = create_payment_method(user.id)

      assert {:ok, deleted} = Subscriptions.delete_payment_method(user.id, pm.id)
      assert deleted.is_active == false
    end

    test "PaymentMethod.expired?/1 detects expired cards" do
      # Test directly with struct, since validation prevents saving expired cards
      expired = %PaymentMethod{
        card_exp_month: 1,
        card_exp_year: 2020
      }

      valid = %PaymentMethod{
        card_exp_month: 12,
        card_exp_year: DateTime.utc_now().year + 1
      }

      assert PaymentMethod.expired?(expired) == true
      assert PaymentMethod.expired?(valid) == false
    end

    test "PaymentMethod.display_string/1 formats correctly", %{user: user} do
      {:ok, pm} = create_payment_method(user.id, %{
        card_brand: "visa",
        card_last_four: "4242"
      })

      assert PaymentMethod.display_string(pm) == "Visa ****4242"
    end
  end

  describe "invoices" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "list_invoices/2 returns invoices for user", %{user: user} do
      {:ok, _inv} = create_invoice(user.id)

      invoices = Subscriptions.list_invoices(user.id)
      assert length(invoices) == 1
    end

    test "get_invoice/1 returns the invoice", %{user: user} do
      {:ok, inv} = create_invoice(user.id)

      result = Subscriptions.get_invoice(inv.id)
      assert result.id == inv.id
    end

    test "create_invoice/1 generates invoice number", %{user: user} do
      attrs = %{
        user_id: user.id,
        status: :open,
        amount_due: Decimal.new("9.99"),
        invoice_date: DateTime.utc_now()
      }

      assert {:ok, inv} = Subscriptions.create_invoice(attrs)
      assert String.starts_with?(inv.invoice_number, "INV-")
    end

    test "mark_invoice_paid/2 updates invoice status", %{user: user} do
      {:ok, inv} = create_invoice(user.id, %{status: :open})

      assert {:ok, paid} = Subscriptions.mark_invoice_paid(inv.id)
      assert paid.status == :paid
      assert paid.paid_at != nil
    end

    test "Invoice.paid?/1 returns correct status", %{user: user} do
      {:ok, open} = create_invoice(user.id, %{status: :open})
      {:ok, paid} = create_invoice(user.id, %{status: :paid})

      assert Invoice.paid?(open) == false
      assert Invoice.paid?(paid) == true
    end

    test "Invoice.balance/1 calculates remaining balance", %{user: user} do
      {:ok, inv} = create_invoice(user.id, %{
        amount_due: Decimal.new("100.00"),
        amount_paid: Decimal.new("40.00")
      })

      assert Invoice.balance(inv) == Decimal.new("60.00")
    end
  end

  describe "coupon_codes" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "create_coupon_code/1 creates a coupon" do
      attrs = %{
        code: "SAVE20",
        discount_type: :percentage,
        discount_value: Decimal.new("20"),
        duration: :once
      }

      assert {:ok, coupon} = Subscriptions.create_coupon_code(attrs)
      assert coupon.code == "SAVE20"
      assert coupon.discount_type == :percentage
    end

    test "create_coupon_code/1 upcases the code" do
      attrs = %{
        code: "save20",
        discount_type: :percentage,
        discount_value: Decimal.new("20"),
        duration: :once
      }

      assert {:ok, coupon} = Subscriptions.create_coupon_code(attrs)
      assert coupon.code == "SAVE20"
    end

    test "get_coupon_code/1 finds by code (case insensitive)" do
      {:ok, _} = Subscriptions.create_coupon_code(%{
        code: "SUMMER",
        discount_type: :fixed_amount,
        discount_value: Decimal.new("10"),
        duration: :once,
        currency: "USD"
      })

      assert coupon = Subscriptions.get_coupon_code("summer")
      assert coupon.code == "SUMMER"
    end

    test "CouponCode.valid?/1 checks all validity conditions" do
      {:ok, valid} = Subscriptions.create_coupon_code(%{
        code: "VALID",
        discount_type: :percentage,
        discount_value: Decimal.new("10"),
        duration: :once,
        is_active: true
      })

      {:ok, inactive} = Subscriptions.create_coupon_code(%{
        code: "INACTIVE",
        discount_type: :percentage,
        discount_value: Decimal.new("10"),
        duration: :once,
        is_active: false
      })

      assert CouponCode.valid?(valid) == true
      assert CouponCode.valid?(inactive) == false
    end

    test "CouponCode.valid?/1 checks date range" do
      past = DateTime.add(DateTime.utc_now(), -86400, :second)
      future = DateTime.add(DateTime.utc_now(), 86400, :second)

      {:ok, expired} = Subscriptions.create_coupon_code(%{
        code: "EXPIRED",
        discount_type: :percentage,
        discount_value: Decimal.new("10"),
        duration: :once,
        valid_until: past
      })

      {:ok, not_yet} = Subscriptions.create_coupon_code(%{
        code: "NOTYET",
        discount_type: :percentage,
        discount_value: Decimal.new("10"),
        duration: :once,
        valid_from: future
      })

      assert CouponCode.valid?(expired) == false
      assert CouponCode.valid?(not_yet) == false
    end

    test "CouponCode.calculate_discount/2 for percentage" do
      {:ok, coupon} = Subscriptions.create_coupon_code(%{
        code: "PERCENT20",
        discount_type: :percentage,
        discount_value: Decimal.new("20"),
        duration: :once
      })

      discount = CouponCode.calculate_discount(coupon, Decimal.new("100"))
      # Compare using Decimal.equal? to avoid precision issues
      assert Decimal.equal?(discount, Decimal.new("20"))
    end

    test "CouponCode.calculate_discount/2 for fixed amount" do
      {:ok, coupon} = Subscriptions.create_coupon_code(%{
        code: "FLAT10",
        discount_type: :fixed_amount,
        discount_value: Decimal.new("10"),
        duration: :once,
        currency: "USD"
      })

      discount = CouponCode.calculate_discount(coupon, Decimal.new("100"))
      assert discount == Decimal.new("10")
    end

    test "apply_coupon_code/3 applies coupon to user", %{user: user} do
      {:ok, coupon} = Subscriptions.create_coupon_code(%{
        code: "APPLY",
        discount_type: :percentage,
        discount_value: Decimal.new("15"),
        duration: :once
      })

      assert {:ok, {applied_coupon, user_coupon}} = Subscriptions.apply_coupon_code(user.id, "APPLY")
      assert applied_coupon.id == coupon.id
      assert user_coupon.user_id == user.id
    end

    test "apply_coupon_code/3 prevents double use", %{user: user} do
      {:ok, _coupon} = Subscriptions.create_coupon_code(%{
        code: "ONCEONLY",
        discount_type: :percentage,
        discount_value: Decimal.new("15"),
        duration: :once
      })

      assert {:ok, _} = Subscriptions.apply_coupon_code(user.id, "ONCEONLY")
      assert {:error, :already_used} = Subscriptions.apply_coupon_code(user.id, "ONCEONLY")
    end

    test "apply_coupon_code/3 rejects invalid code", %{user: user} do
      assert {:error, :invalid_code} = Subscriptions.apply_coupon_code(user.id, "DOESNOTEXIST")
    end

    test "apply_coupon_code/3 rejects expired coupon", %{user: user} do
      past = DateTime.add(DateTime.utc_now(), -86400, :second)

      {:ok, _} = Subscriptions.create_coupon_code(%{
        code: "EXPIREDCODE",
        discount_type: :percentage,
        discount_value: Decimal.new("15"),
        duration: :once,
        valid_until: past
      })

      assert {:error, :coupon_expired} = Subscriptions.apply_coupon_code(user.id, "EXPIREDCODE")
    end

    test "apply_coupon_code/3 increments redemption count", %{user: user} do
      {:ok, coupon} = Subscriptions.create_coupon_code(%{
        code: "COUNTME",
        discount_type: :percentage,
        discount_value: Decimal.new("15"),
        duration: :once,
        redemptions_count: 0
      })

      assert {:ok, _} = Subscriptions.apply_coupon_code(user.id, "COUNTME")

      updated = Subscriptions.get_coupon_code("COUNTME")
      assert updated.redemptions_count == 1
    end
  end

  describe "subscription events" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, subscription} = create_user_subscription(user.id, plan.id)
      %{user: user, subscription: subscription}
    end

    test "record_subscription_event/3 creates event", %{subscription: subscription} do
      assert {:ok, event} = Subscriptions.record_subscription_event(
        subscription.id,
        :activated,
        %{reason: "test"}
      )

      assert event.event_type == :activated
      # Map keys may be atoms or strings depending on how they're stored
      assert event.event_data[:reason] == "test" or event.event_data["reason"] == "test"
    end

    test "list_subscription_events/2 returns events", %{subscription: subscription} do
      {:ok, _} = Subscriptions.record_subscription_event(subscription.id, :activated, %{})
      {:ok, _} = Subscriptions.record_subscription_event(subscription.id, :plan_changed, %{})

      events = Subscriptions.list_subscription_events(subscription.id)
      assert length(events) == 2
    end
  end

  describe "billing events" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      {:ok, subscription} = create_user_subscription(user.id, plan.id)
      %{user: user, subscription: subscription}
    end

    test "record_billing_event/4 creates event", %{subscription: subscription} do
      assert {:ok, event} = Subscriptions.record_billing_event(
        subscription.id,
        :payment_succeeded,
        :succeeded,
        %{amount: Decimal.new("9.99"), currency: "USD"}
      )

      assert event.event_type == :payment_succeeded
      assert event.status == :succeeded
    end

    test "list_billing_events/2 returns events", %{subscription: subscription} do
      {:ok, _} = Subscriptions.record_billing_event(subscription.id, :payment_succeeded, :succeeded, %{})
      {:ok, _} = Subscriptions.record_billing_event(subscription.id, :payment_failed, :failed, %{})

      events = Subscriptions.list_billing_events(subscription.id)
      assert length(events) == 2
    end
  end

  # Helper functions

  defp insert_user do
    {:ok, user} = ButtonLog.Accounts.create_user(%{
      email: "test#{System.unique_integer([:positive])}@example.com",
      username: "testuser#{System.unique_integer([:positive])}",
      display_name: "Test User",
      password: "password123",
      password_confirmation: "password123"
    })
    user
  end

  defp create_payment_method(user_id, attrs \\ %{}) do
    default_attrs = %{
      user_id: user_id,
      payment_provider: "stripe",
      payment_provider_method_id: "pm_test_#{System.unique_integer([:positive])}",
      card_brand: "visa",
      card_last_four: "4242",
      card_exp_month: 12,
      card_exp_year: DateTime.utc_now().year + 1,
      is_active: true,
      is_default: false
    }

    Subscriptions.create_payment_method(Map.merge(default_attrs, attrs))
  end

  defp create_invoice(user_id, attrs \\ %{}) do
    default_attrs = %{
      user_id: user_id,
      status: :open,
      amount_due: Decimal.new("9.99"),
      invoice_date: DateTime.utc_now()
    }

    Subscriptions.create_invoice(Map.merge(default_attrs, attrs))
  end

  defp create_user_subscription(user_id, plan_id) do
    attrs = %{
      user_id: user_id,
      subscription_plan_id: plan_id,
      status: :active,
      billing_cycle: :monthly,
      amount: Decimal.new("9.99"),
      currency: "USD",
      current_period_start: DateTime.utc_now(),
      current_period_end: DateTime.add(DateTime.utc_now(), 30 * 86400, :second)
    }

    Subscriptions.create_user_subscription(attrs)
  end
end
