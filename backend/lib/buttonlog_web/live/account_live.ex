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
       |> assign(:page_title, "Account Settings")
       |> assign(:editing_profile, false)
       |> assign(:profile_form, build_profile_form(current_user))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access account settings")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  defp build_profile_form(user) do
    %{
      "display_name" => user.display_name || "",
      "first_name" => user.first_name || "",
      "last_name" => user.last_name || ""
    }
  end

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Logged out successfully")
     |> redirect(to: ~p"/auth/login")}
  end

  @impl true
  def handle_event("start_edit_profile", _params, socket) do
    {:noreply, assign(socket, :editing_profile, true)}
  end

  @impl true
  def handle_event("cancel_edit_profile", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_profile, false)
     |> assign(:profile_form, build_profile_form(socket.assigns.current_user))}
  end

  @impl true
  def handle_event("validate_profile", %{"profile" => profile_params}, socket) do
    {:noreply, assign(socket, :profile_form, profile_params)}
  end

  @impl true
  def handle_event("save_profile", %{"profile" => profile_params}, socket) do
    user = socket.assigns.current_user

    attrs = %{
      display_name: profile_params["display_name"],
      first_name: profile_params["first_name"],
      last_name: profile_params["last_name"]
    }

    case Accounts.update_user_profile(user, attrs) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:editing_profile, false)
         |> assign(:profile_form, build_profile_form(updated_user))
         |> put_flash(:info, "Profile updated successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update profile")}
    end
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
  def handle_event("update_privacy", %{"field" => field, "value" => value}, socket) do
    user = socket.assigns.current_user

    attrs = %{String.to_existing_atom(field) => value}

    case Accounts.update_user_profile(user, attrs) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, "Privacy settings updated")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update privacy settings")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end


