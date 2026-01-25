defmodule ButtonLogWeb.API.SubscriptionControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Auth.Token
  alias ButtonLog.Repo

  setup do
    user = insert_user()
    token = Token.create_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "GET /api/subscriptions/plans (public)" do
    test "returns list of available subscription plans without auth", %{conn: conn} do
      # Clean up existing plans to have predictable test data
      Repo.delete_all(ButtonLog.Subscriptions.SubscriptionPlan)

      insert_subscription_plan(%{name: "Free", slug: "free", is_active: true})
      insert_subscription_plan(%{name: "Premium", slug: "premium", is_active: true})

      # No auth header - this is a public endpoint
      conn = get(conn, "/api/subscriptions/plans")

      assert %{
        "success" => true,
        "data" => plans
      } = json_response(conn, 200)

      assert length(plans) == 2
      assert Enum.all?(plans, fn plan ->
        Map.has_key?(plan, "id") and
        Map.has_key?(plan, "name") and
        Map.has_key?(plan, "slug")
      end)
    end

    test "returns prices as numbers (not strings) for mobile clients", %{conn: conn} do
      Repo.delete_all(ButtonLog.Subscriptions.SubscriptionPlan)

      insert_subscription_plan(%{
        name: "Premium",
        slug: "premium",
        is_active: true,
        price_monthly: Decimal.new("9.99"),
        price_yearly: Decimal.new("99.99")
      })

      conn = get(conn, "/api/subscriptions/plans")

      assert %{"success" => true, "data" => [plan]} = json_response(conn, 200)

      # Prices must be numbers, not strings (critical for iOS/Android JSON parsing)
      assert is_number(plan["monthly_price"])
      assert is_number(plan["yearly_price"])
      assert plan["monthly_price"] == 9.99
      assert plan["yearly_price"] == 99.99
    end

    test "includes plan features and limits", %{conn: conn} do
      Repo.delete_all(ButtonLog.Subscriptions.SubscriptionPlan)

      plan = insert_subscription_plan(%{
        name: "Premium",
        is_active: true,
        max_buttons: 100,
        max_friends: 50,
        has_advanced_analytics: true,
        has_calendar_sync: true
      })

      conn = get(conn, "/api/subscriptions/plans")

      assert %{"success" => true, "data" => plans} = json_response(conn, 200)

      premium_plan = Enum.find(plans, &(&1["slug"] == plan.slug))
      assert premium_plan != nil
      assert premium_plan["features"]["analytics"] == true
      assert premium_plan["features"]["calendar_sync"] == true
      assert premium_plan["limits"]["max_buttons"] == 100
      assert premium_plan["limits"]["max_friends"] == 50
    end
  end

  describe "GET /api/subscriptions (authenticated)" do
    test "returns list of available subscription plans", %{conn: conn, token: token} do
      # Insert some subscription plans
      insert_subscription_plan(%{name: "Free", is_active: true})
      insert_subscription_plan(%{name: "Premium", is_active: true})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/subscriptions")

      assert %{
        "success" => true,
        "data" => plans
      } = json_response(conn, 200)

      assert length(plans) >= 2
      assert Enum.all?(plans, fn plan ->
        Map.has_key?(plan, "id") and
        Map.has_key?(plan, "name") and
        Map.has_key?(plan, "slug")
      end)
    end

    test "includes plan features and limits", %{conn: conn, token: token} do
      plan = insert_subscription_plan(%{
        name: "Premium",
        is_active: true,
        max_buttons: 100,
        max_friends: 50,
        has_advanced_analytics: true,
        has_calendar_sync: true
      })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/subscriptions")

      assert %{"success" => true, "data" => plans} = json_response(conn, 200)

      premium_plan = Enum.find(plans, &(&1["slug"] == plan.slug))
      assert premium_plan != nil
      assert premium_plan["features"]["analytics"] == true
      assert premium_plan["features"]["calendar_sync"] == true
      assert premium_plan["limits"]["max_buttons"] == 100
      assert premium_plan["limits"]["max_friends"] == 50
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/subscriptions")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/subscriptions/current" do
    test "returns nil when no subscription exists", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/subscriptions/current")

      assert %{
        "success" => true,
        "data" => nil
      } = json_response(conn, 200)
    end

    test "returns current subscription with usage", %{conn: conn, user: user, token: token} do
      plan = insert_subscription_plan(%{name: "Premium", is_active: true})
      _subscription = insert_user_subscription(user, plan, %{
        status: :active,
        billing_cycle: :monthly,
        amount: 9.99
      })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/subscriptions/current")

      assert %{
        "success" => true,
        "data" => data
      } = json_response(conn, 200)

      assert data["status"] == "active"
      assert data["billing_cycle"] == "monthly"
      assert data["usage"] != nil
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/subscriptions/current")
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/subscriptions (cancel)" do
    test "cancels active subscription", %{conn: conn, user: user, token: token} do
      plan = insert_subscription_plan(%{name: "Premium", is_active: true})
      _subscription = insert_user_subscription(user, plan, %{status: :active})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/subscriptions")

      assert %{
        "success" => true,
        "data" => %{
          "message" => "Subscription canceled successfully",
          "subscription" => %{"status" => "canceled"}
        }
      } = json_response(conn, 200)
    end

    test "returns error when no active subscription", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/subscriptions")

      assert %{
        "success" => false,
        "error" => %{"message" => "No active subscription found"}
      } = json_response(conn, 422)
    end

    test "requires authentication", %{conn: conn} do
      conn = delete(conn, "/api/subscriptions")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/subscriptions/pause" do
    test "pauses active subscription", %{conn: conn, user: user, token: token} do
      plan = insert_subscription_plan(%{name: "Premium", is_active: true})
      _subscription = insert_user_subscription(user, plan, %{status: :active})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/pause")

      assert %{
        "success" => true,
        "data" => %{
          "message" => "Subscription paused successfully",
          "subscription" => %{"status" => "paused"}
        }
      } = json_response(conn, 200)
    end

    test "returns error when no active subscription", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/pause")

      assert %{
        "success" => false,
        "error" => %{"message" => "No active subscription found"}
      } = json_response(conn, 422)
    end

    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/api/subscriptions/pause")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/subscriptions/resume" do
    test "resumes active subscription (keeps it active)", %{conn: conn, user: user, token: token} do
      plan = insert_subscription_plan(%{name: "Premium", is_active: true})
      _subscription = insert_user_subscription(user, plan, %{status: :active})

      # Resume an active subscription (not paused)
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/resume")

      assert %{
        "success" => true,
        "data" => %{
          "message" => "Subscription resumed successfully",
          "subscription" => %{"status" => "active"}
        }
      } = json_response(conn, 200)
    end

    test "returns error when no subscription", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/resume")

      assert %{
        "success" => false,
        "error" => %{"message" => "No subscription found"}
      } = json_response(conn, 422)
    end

    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/api/subscriptions/resume")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/subscriptions/stats" do
    test "returns subscription stats for user with subscription", %{conn: conn, user: user, token: token} do
      plan = insert_subscription_plan(%{
        name: "Premium",
        is_active: true,
        max_buttons: 100,
        max_friends: 50,
        has_advanced_analytics: true
      })
      _subscription = insert_user_subscription(user, plan, %{
        status: :active,
        billing_cycle: :monthly,
        buttons_used: 5,
        friends_used: 3,
        clicks_this_month: 100
      })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/subscriptions/stats")

      assert %{
        "success" => true,
        "data" => stats
      } = json_response(conn, 200)

      assert stats["current_plan"] == "Premium"
      assert stats["status"] == "active"
      assert stats["limits"]["max_buttons"] == 100
      assert stats["features"]["advanced_analytics"] == true
    end

    test "returns free plan stats for user without subscription", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/subscriptions/stats")

      assert %{
        "success" => true,
        "data" => stats
      } = json_response(conn, 200)

      assert stats["current_plan"] == "Free"
      assert stats["status"] == "free"
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/subscriptions/stats")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/subscriptions/check-permission" do
    test "checks permission for creating button", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/check-permission", %{
          "action" => "create_button",
          "context" => %{"current_button_count" => 0}
        })

      assert %{
        "action" => "create_button",
        "can_perform" => can_perform
      } = json_response(conn, 200)

      assert is_boolean(can_perform)
    end

    test "checks permission for adding friend", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/check-permission", %{
          "action" => "add_friend",
          "context" => %{"current_friend_count" => 0}
        })

      assert %{
        "action" => "add_friend",
        "can_perform" => can_perform
      } = json_response(conn, 200)

      assert is_boolean(can_perform)
    end

    test "checks permission for analytics access", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/subscriptions/check-permission", %{
          "action" => "access_analytics",
          "context" => %{"days_back" => 30}
        })

      assert %{
        "action" => "access_analytics",
        "can_perform" => can_perform
      } = json_response(conn, 200)

      assert is_boolean(can_perform)
    end
  end

  # Helper functions
  defp insert_user(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    default_attrs = %{
      email: "test#{unique_id}@test.com",
      username: "testuser#{unique_id}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123!")
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash])
    |> Repo.insert!()
  end

  defp insert_subscription_plan(attrs) do
    unique_id = System.unique_integer([:positive])

    default_attrs = %{
      name: "Plan #{unique_id}",
      slug: "plan_#{unique_id}",
      description: "Test plan",
      price_monthly: Decimal.new("9.99"),
      price_yearly: Decimal.new("99.99"),
      currency: "USD",
      max_buttons: 10,
      max_friends: 10,
      max_button_clicks_per_month: 1000,
      max_analytics_history_days: 30,
      max_export_history_days: 30,
      has_advanced_analytics: false,
      has_calendar_sync: false,
      has_api_access: false,
      has_custom_themes: false,
      has_priority_support: false,
      has_team_features: false,
      has_white_label: false,
      trial_days: 0,
      is_active: true,
      sort_order: unique_id
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Subscriptions.SubscriptionPlan{}
    |> Ecto.Changeset.cast(attrs, [
      :name, :slug, :description, :price_monthly, :price_yearly, :currency,
      :max_buttons, :max_friends, :max_button_clicks_per_month,
      :max_analytics_history_days, :max_export_history_days,
      :has_advanced_analytics, :has_calendar_sync, :has_api_access,
      :has_custom_themes, :has_priority_support, :has_team_features,
      :has_white_label, :trial_days, :is_active, :sort_order
    ])
    |> Repo.insert!()
  end

  defp insert_user_subscription(user, plan, attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    default_attrs = %{
      user_id: user.id,
      subscription_plan_id: plan.id,
      status: :active,
      billing_cycle: :monthly,
      amount: Decimal.new("9.99"),
      currency: "USD",
      current_period_start: now,
      current_period_end: DateTime.add(now, 30, :day),
      next_billing_date: DateTime.add(now, 30, :day),
      buttons_used: 0,
      friends_used: 0,
      clicks_this_month: 0
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Subscriptions.UserSubscription{}
    |> Ecto.Changeset.cast(attrs, [
      :user_id, :subscription_plan_id, :status, :billing_cycle, :amount, :currency,
      :current_period_start, :current_period_end, :next_billing_date,
      :buttons_used, :friends_used, :clicks_this_month
    ])
    |> Repo.insert!()
  end
end
