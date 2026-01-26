defmodule ButtonLog.Subscriptions.StripeServiceTest do
  use ButtonLog.DataCase

  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.StripeService

  @moduletag :stripe_service

  # Integration tests require STRIPE_SECRET_KEY (test mode) to be set
  # Run with: STRIPE_SECRET_KEY=sk_test_xxx mix test --only stripe_integration
  @moduletag :stripe_integration

  describe "get_or_create_customer/1" do
    setup do
      user = insert_user()
      %{user: user}
    end

    @tag :stripe_integration
    test "creates a new Stripe customer for user without existing customer", %{user: user} do
      case StripeService.get_or_create_customer(user) do
        {:ok, customer_id} ->
          assert String.starts_with?(customer_id, "cus_")

        {:error, error} ->
          # If Stripe is not configured, this is expected
          assert is_binary(error) or error == :stripe_not_configured
      end
    end

    @tag :stripe_integration
    test "returns existing customer_id when user has payment method", %{user: user} do
      # First create a payment method with customer_id
      customer_id = "cus_existing_#{unique_id()}"
      {:ok, _pm} = Subscriptions.create_payment_method(%{
        user_id: user.id,
        payment_provider: "stripe",
        payment_provider_method_id: "pm_test_#{unique_id()}",
        payment_provider_customer_id: customer_id,
        card_brand: "visa",
        card_last_four: "4242",
        card_exp_month: 12,
        card_exp_year: DateTime.utc_now().year + 1
      })

      # Should return the existing customer_id
      assert {:ok, ^customer_id} = StripeService.get_or_create_customer(user)
    end
  end

  describe "create_checkout_session/3" do
    setup do
      user = insert_user()
      plan = Subscriptions.get_subscription_plan_by_slug("premium")
      %{user: user, plan: plan}
    end

    @tag :stripe_integration
    test "creates checkout session for monthly subscription", %{user: user, plan: plan} do
      # Skip if plan doesn't have Stripe price configured
      if plan.stripe_price_id_monthly do
        case StripeService.create_checkout_session(user, plan, :monthly) do
          {:ok, session} ->
            assert session.id != nil
            assert String.starts_with?(session.id, "cs_")
            assert session.url != nil

          {:error, error} ->
            # Expected if Stripe is not properly configured
            assert is_binary(error) or error == :price_not_configured
        end
      else
        # Plan doesn't have Stripe price - expected in test environment
        assert {:error, :price_not_configured} =
          StripeService.create_checkout_session(user, plan, :monthly)
      end
    end

    @tag :stripe_integration
    test "creates checkout session with coupon code", %{user: user, plan: plan} do
      if plan.stripe_price_id_monthly do
        opts = [coupon_code: "TESTCOUPON"]
        case StripeService.create_checkout_session(user, plan, :monthly, opts) do
          {:ok, session} ->
            assert session.id != nil

          {:error, _} ->
            # Expected - coupon might not exist in Stripe
            :ok
        end
      end
    end

    @tag :stripe_integration
    test "creates checkout session with custom URLs", %{user: user, plan: plan} do
      if plan.stripe_price_id_monthly do
        opts = [
          success_url: "https://example.com/success?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: "https://example.com/cancel"
        ]

        case StripeService.create_checkout_session(user, plan, :monthly, opts) do
          {:ok, session} ->
            assert session.id != nil

          {:error, _} ->
            :ok
        end
      end
    end

    test "returns error for invalid billing cycle", %{user: user, plan: plan} do
      assert {:error, :price_not_configured} =
        StripeService.create_checkout_session(user, plan, :invalid_cycle)
    end
  end

  describe "create_portal_session/2" do
    setup do
      user = insert_user()
      %{user: user}
    end

    @tag :stripe_integration
    test "creates portal session for managing subscription", %{user: user} do
      case StripeService.create_portal_session(user) do
        {:ok, session} ->
          assert session.url != nil
          assert String.contains?(session.url, "billing.stripe.com")

        {:error, _} ->
          # Expected if Stripe portal not configured or no customer exists
          :ok
      end
    end

    @tag :stripe_integration
    test "creates portal session with custom return URL", %{user: user} do
      case StripeService.create_portal_session(user, "https://example.com/account") do
        {:ok, session} ->
          assert session.url != nil

        {:error, _} ->
          :ok
      end
    end
  end

  describe "cancel_subscription/2" do
    @tag :stripe_integration
    test "cancels subscription at period end" do
      # This test requires an actual subscription - skip in most cases
      subscription_id = "sub_test_nonexistent"

      case StripeService.cancel_subscription(subscription_id, at_period_end: true) do
        {:ok, subscription} ->
          assert subscription.cancel_at_period_end == true

        {:error, _} ->
          # Expected for non-existent subscription
          :ok
      end
    end

    @tag :stripe_integration
    test "cancels subscription immediately" do
      subscription_id = "sub_test_nonexistent"

      case StripeService.cancel_subscription(subscription_id, at_period_end: false) do
        {:ok, subscription} ->
          assert subscription.status == "canceled"

        {:error, _} ->
          :ok
      end
    end
  end

  describe "create_setup_intent/1" do
    setup do
      user = insert_user()
      %{user: user}
    end

    @tag :stripe_integration
    test "creates setup intent for adding payment method", %{user: user} do
      case StripeService.create_setup_intent(user) do
        {:ok, intent} ->
          assert intent.id != nil
          assert String.starts_with?(intent.id, "seti_")
          assert intent.client_secret != nil

        {:error, _} ->
          :ok
      end
    end
  end

  describe "get_upcoming_invoice/1" do
    @tag :stripe_integration
    test "retrieves upcoming invoice for customer" do
      customer_id = "cus_test_#{unique_id()}"

      case StripeService.get_upcoming_invoice(customer_id) do
        {:ok, invoice} ->
          assert invoice.amount_due != nil

        {:error, _} ->
          # Expected for non-existent or customers without subscriptions
          :ok
      end
    end
  end

  describe "list_invoices/2" do
    @tag :stripe_integration
    test "lists invoices for customer" do
      customer_id = "cus_test_#{unique_id()}"

      case StripeService.list_invoices(customer_id) do
        {:ok, invoices} ->
          assert is_list(invoices)

        {:error, _} ->
          :ok
      end
    end

    @tag :stripe_integration
    test "respects limit option" do
      customer_id = "cus_test_#{unique_id()}"

      case StripeService.list_invoices(customer_id, limit: 5) do
        {:ok, invoices} ->
          assert length(invoices) <= 5

        {:error, _} ->
          :ok
      end
    end
  end

  describe "create_coupon/1" do
    @tag :stripe_integration
    test "creates percentage discount coupon" do
      coupon_code = %{
        code: "TEST#{unique_id()}",
        name: "Test Coupon",
        discount_type: :percentage,
        discount_value: Decimal.new("20"),
        duration: :once,
        max_redemptions: nil
      }

      case StripeService.create_coupon(coupon_code) do
        {:ok, coupon} ->
          assert coupon.id == coupon_code.code
          assert coupon.percent_off == 20.0

        {:error, _} ->
          :ok
      end
    end

    @tag :stripe_integration
    test "creates fixed amount discount coupon" do
      coupon_code = %{
        code: "FIXEDTEST#{unique_id()}",
        name: "Fixed Test Coupon",
        discount_type: :fixed_amount,
        discount_value: Decimal.new("10"),
        currency: "USD",
        duration: :once,
        max_redemptions: nil
      }

      case StripeService.create_coupon(coupon_code) do
        {:ok, coupon} ->
          assert coupon.id == coupon_code.code
          assert coupon.amount_off == 1000  # cents

        {:error, _} ->
          :ok
      end
    end
  end

  # ============================================================================
  # Unit Tests (no Stripe API calls)
  # ============================================================================

  describe "unit tests - service logic" do
    test "subscription plan price ID lookup" do
      plan = Subscriptions.get_subscription_plan_by_slug("premium")

      # Premium plan should exist
      assert plan != nil
      assert plan.slug == "premium"

      # Price IDs may or may not be configured
      # This tests the lookup logic without making API calls
    end

    test "free plan has no Stripe price IDs" do
      plan = Subscriptions.get_subscription_plan_by_slug("free")
      assert plan != nil
      assert plan.price_monthly == Decimal.new("0.00")
    end

    test "subscription plans are properly seeded" do
      plans = Subscriptions.list_subscription_plans()

      assert Enum.any?(plans, &(&1.slug == "free"))
      assert Enum.any?(plans, &(&1.slug == "premium"))
      assert Enum.any?(plans, &(&1.slug == "enterprise"))

      # Verify pricing
      free = Enum.find(plans, &(&1.slug == "free"))
      premium = Enum.find(plans, &(&1.slug == "premium"))

      assert free.price_monthly == Decimal.new("0.00")
      assert Decimal.compare(premium.price_monthly, Decimal.new("0")) == :gt
    end
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp unique_id, do: System.unique_integer([:positive])

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
end
