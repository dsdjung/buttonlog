defmodule ButtonLogWeb.PricingLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Accounts
  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.{SubscriptionService, StripeService}

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    plans = SubscriptionService.get_available_plans()

    socket =
      if user_id do
        current_user = Accounts.get_user!(user_id)
        subscription_info = SubscriptionService.get_user_subscription(user_id)

        socket
        |> assign(:current_user, current_user)
        |> assign(:subscription_info, subscription_info)
        |> assign(:current_plan_slug, subscription_info.plan.slug)
      else
        socket
        |> assign(:current_user, nil)
        |> assign(:subscription_info, nil)
        |> assign(:current_plan_slug, nil)
      end

    {:ok,
     socket
     |> assign(:plans, plans)
     |> assign(:billing_cycle, :monthly)
     |> assign(:page_title, "Pricing")}
  end

  @impl true
  def handle_event("toggle_billing_cycle", _params, socket) do
    new_cycle =
      case socket.assigns.billing_cycle do
        :monthly -> :yearly
        :yearly -> :monthly
      end

    {:noreply, assign(socket, :billing_cycle, new_cycle)}
  end

  @impl true
  def handle_event("select_plan", %{"plan_id" => plan_id}, socket) do
    user = socket.assigns.current_user
    billing_cycle = socket.assigns.billing_cycle

    if is_nil(user) do
      {:noreply,
       socket
       |> put_flash(:info, "Please log in to subscribe")
       |> redirect(to: ~p"/auth/login")}
    else
      plan = Subscriptions.get_subscription_plan(plan_id)

      if plan && plan.slug != "free" do
        case StripeService.create_checkout_session(user, plan, billing_cycle) do
          {:ok, session} ->
            {:noreply, redirect(socket, external: session.url)}

          {:error, :price_not_configured} ->
            {:noreply,
             socket
             |> put_flash(:error, "Stripe pricing is not configured for this plan")}

          {:error, message} ->
            {:noreply,
             socket
             |> put_flash(:error, "Unable to start checkout: #{message}")}
        end
      else
        {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
