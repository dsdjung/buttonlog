defmodule ButtonLogWeb.AccountLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Accounts
  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.SubscriptionService

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      subscription_info = SubscriptionService.get_user_subscription(user_id)
      plans = SubscriptionService.get_available_plans()

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:subscription_info, subscription_info)
       |> assign(:plans, plans)
       |> assign(:page_title, "Account Settings")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access account settings")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Logged out successfully")
     |> redirect(to: ~p"/auth/login")}
  end

  @impl true
  def handle_event("manage_subscription", _params, socket) do
    user = socket.assigns.current_user

    case Subscriptions.StripeService.create_portal_session(user) do
      {:ok, session} ->
        {:noreply, redirect(socket, external: session.url)}

      {:error, message} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to open subscription portal: #{message}")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end


