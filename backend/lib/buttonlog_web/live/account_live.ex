defmodule ButtonLogWeb.AccountLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Accounts
  alias ButtonLog.Subscriptions
  alias ButtonLog.Subscriptions.SubscriptionService

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    case user_id && Accounts.get_user(user_id) do
      nil ->
        # No user_id in session or user not found - redirect to login
        {:ok,
         socket
         |> put_flash(:error, "Please log in to access account settings")
         |> redirect(to: ~p"/auth/login")}

      current_user ->
        subscription_info = SubscriptionService.get_user_subscription(user_id)
        plans = SubscriptionService.get_available_plans()

        {:ok,
         socket
         |> assign(:current_user, current_user)
         |> assign(:subscription_info, subscription_info)
         |> assign(:plans, plans)
         |> assign(:page_title, "Account Settings")
         |> assign(:editing_profile, false)
         |> assign(:profile_form, build_profile_form(current_user))
         |> assign(:editing_password, false)
         |> assign(:password_form, %{"current_password" => "", "new_password" => "", "confirm_password" => ""})
         |> assign(:password_error, nil)}
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
  def handle_event("start_edit_password", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_password, true)
     |> assign(:password_error, nil)}
  end

  @impl true
  def handle_event("cancel_edit_password", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_password, false)
     |> assign(:password_form, %{"current_password" => "", "new_password" => "", "confirm_password" => ""})
     |> assign(:password_error, nil)}
  end

  @impl true
  def handle_event("validate_password", %{"password" => password_params}, socket) do
    {:noreply, assign(socket, :password_form, password_params)}
  end

  @impl true
  def handle_event("save_password", %{"password" => password_params}, socket) do
    user = socket.assigns.current_user
    current_password = password_params["current_password"]
    new_password = password_params["new_password"]
    confirm_password = password_params["confirm_password"]

    cond do
      new_password != confirm_password ->
        {:noreply, assign(socket, :password_error, "New passwords do not match")}

      String.length(new_password) < 8 ->
        {:noreply, assign(socket, :password_error, "Password must be at least 8 characters")}

      !Bcrypt.verify_pass(current_password, user.password_hash || "") ->
        {:noreply, assign(socket, :password_error, "Current password is incorrect")}

      true ->
        case Accounts.change_user_password(user, new_password) do
          {:ok, _updated_user} ->
            {:noreply,
             socket
             |> assign(:editing_password, false)
             |> assign(:password_form, %{"current_password" => "", "new_password" => "", "confirm_password" => ""})
             |> assign(:password_error, nil)
             |> put_flash(:info, "Password changed successfully")}

          {:error, _changeset} ->
            {:noreply, assign(socket, :password_error, "Failed to change password")}
        end
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end


