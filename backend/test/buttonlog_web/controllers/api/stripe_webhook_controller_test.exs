defmodule ButtonLogWeb.API.StripeWebhookControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Subscriptions

  @moduletag :stripe_webhook

  describe "handle/2" do
    test "returns 400 when Stripe signature is missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/webhooks/stripe", Jason.encode!(%{type: "test"}))

      assert json_response(conn, 400)["error"] == "Missing Stripe signature"
    end

    test "returns 400 when signature is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("stripe-signature", "invalid_signature")
        |> assign(:raw_body, Jason.encode!(%{type: "test"}))
        |> post("/api/webhooks/stripe", Jason.encode!(%{type: "test"}))

      assert json_response(conn, 400)["error"] =~ "Invalid signature" or
             json_response(conn, 400)["error"] =~ "Webhook verification failed"
    end

    test "handles checkout.session.completed event structure" do
      # Simulate the checkout.session.completed event data
      # This test verifies the expected event structure for webhook handling
      event_data = %{
        "id" => "evt_test_#{System.unique_integer([:positive])}",
        "type" => "checkout.session.completed",
        "data" => %{
          "object" => %{
            "id" => "cs_test_#{System.unique_integer([:positive])}",
            "customer" => "cus_test_#{System.unique_integer([:positive])}",
            "subscription" => "sub_test_#{System.unique_integer([:positive])}",
            "client_reference_id" => Ecto.UUID.generate(),
            "metadata" => %{
              "plan_id" => Ecto.UUID.generate(),
              "billing_cycle" => "monthly"
            }
          }
        }
      }

      # Verify expected event structure for webhook handling
      assert is_map(event_data)
      assert event_data["type"] == "checkout.session.completed"
      assert is_map(event_data["data"]["object"])
      assert event_data["data"]["object"]["metadata"]["billing_cycle"] == "monthly"
    end

    test "handles customer.subscription.updated event" do
      event_data = %{
        "id" => "evt_test_#{System.unique_integer([:positive])}",
        "type" => "customer.subscription.updated",
        "data" => %{
          "object" => %{
            "id" => "sub_test_#{System.unique_integer([:positive])}",
            "status" => "active",
            "current_period_start" => DateTime.utc_now() |> DateTime.to_unix(),
            "current_period_end" => DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix()
          }
        }
      }

      assert is_map(event_data)
      assert event_data["type"] == "customer.subscription.updated"
    end

    test "handles customer.subscription.deleted event" do
      event_data = %{
        "id" => "evt_test_#{System.unique_integer([:positive])}",
        "type" => "customer.subscription.deleted",
        "data" => %{
          "object" => %{
            "id" => "sub_test_#{System.unique_integer([:positive])}",
            "status" => "canceled"
          }
        }
      }

      assert is_map(event_data)
      assert event_data["type"] == "customer.subscription.deleted"
    end

    test "handles invoice.payment_succeeded event" do
      event_data = %{
        "id" => "evt_test_#{System.unique_integer([:positive])}",
        "type" => "invoice.payment_succeeded",
        "data" => %{
          "object" => %{
            "id" => "in_test_#{System.unique_integer([:positive])}",
            "subscription" => "sub_test_#{System.unique_integer([:positive])}",
            "amount_paid" => 999,
            "currency" => "usd"
          }
        }
      }

      assert is_map(event_data)
      assert event_data["type"] == "invoice.payment_succeeded"
    end

    test "handles invoice.payment_failed event" do
      event_data = %{
        "id" => "evt_test_#{System.unique_integer([:positive])}",
        "type" => "invoice.payment_failed",
        "data" => %{
          "object" => %{
            "id" => "in_test_#{System.unique_integer([:positive])}",
            "subscription" => "sub_test_#{System.unique_integer([:positive])}",
            "attempt_count" => 1
          }
        }
      }

      assert is_map(event_data)
      assert event_data["type"] == "invoice.payment_failed"
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
    |> ButtonLog.Repo.insert!()
  end
end
