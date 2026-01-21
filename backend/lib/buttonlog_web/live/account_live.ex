defmodule ButtonLogWeb.AccountLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)

      {:ok,
       socket
       |> assign(:current_user, current_user)
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
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end


