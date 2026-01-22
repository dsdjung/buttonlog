defmodule ButtonLogWeb.OrganizationLive.Show do
  @moduledoc """
  LiveView for viewing and managing a single organization.
  """

  use ButtonLogWeb, :live_view

  alias ButtonLog.{Accounts, Organizations}
  alias ButtonLog.Organizations.OrganizationMember

  @impl true
  def mount(%{"id" => org_id}, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      org = Organizations.get_organization_for_user(org_id, user_id)

      if org do
        role = Organizations.get_user_role(org_id, user_id)
        teams = Organizations.list_organization_teams(org_id)
        invitations = Organizations.list_organization_invitations(org_id)
        subscription = Organizations.get_organization_subscription(org_id)

        {:ok,
         socket
         |> assign(:current_user, current_user)
         |> assign(:organization, org)
         |> assign(:my_role, role)
         |> assign(:can_manage, OrganizationMember.is_admin?(role))
         |> assign(:can_manage_billing, OrganizationMember.can_manage_billing?(role))
         |> assign(:teams, teams)
         |> assign(:invitations, invitations)
         |> assign(:subscription, subscription)
         |> assign(:show_invite_modal, false)
         |> assign(:page_title, org.name)}
      else
        {:ok,
         socket
         |> put_flash(:error, "Organization not found")
         |> redirect(to: ~p"/organizations")}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_invite_modal", _params, socket) do
    {:noreply, assign(socket, :show_invite_modal, true)}
  end

  @impl true
  def handle_event("hide_invite_modal", _params, socket) do
    {:noreply, assign(socket, :show_invite_modal, false)}
  end

  @impl true
  def handle_event("invite_member", %{"username" => username, "role" => role}, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found")}

      invitee ->
        case Organizations.create_invitation(
          socket.assigns.organization.id,
          socket.assigns.current_user.id,
          invitee.id,
          role
        ) do
          {:ok, _invitation} ->
            invitations = Organizations.list_organization_invitations(socket.assigns.organization.id)

            {:noreply,
             socket
             |> assign(:invitations, invitations)
             |> assign(:show_invite_modal, false)
             |> put_flash(:info, "Invitation sent to #{username}")}

          {:error, :already_member} ->
            {:noreply, put_flash(socket, :error, "User is already a member")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to send invitation")}
        end
    end
  end

  @impl true
  def handle_event("update_member_role", %{"user_id" => member_user_id, "role" => role}, socket) do
    case Organizations.update_member_role(
      socket.assigns.organization.id,
      member_user_id,
      role,
      socket.assigns.current_user.id
    ) do
      {:ok, _} ->
        org = Organizations.get_organization(socket.assigns.organization.id)

        {:noreply,
         socket
         |> assign(:organization, org)
         |> put_flash(:info, "Member role updated")}

      {:error, :cannot_change_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot change owner's role")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update role")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user_id" => member_user_id}, socket) do
    case Organizations.remove_member(
      socket.assigns.organization.id,
      member_user_id,
      socket.assigns.current_user.id
    ) do
      {:ok, _} ->
        org = Organizations.get_organization(socket.assigns.organization.id)

        {:noreply,
         socket
         |> assign(:organization, org)
         |> put_flash(:info, "Member removed")}

      {:error, :cannot_remove_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot remove organization owner")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to remove member")}
    end
  end

  @impl true
  def handle_event("cancel_invitation", %{"id" => invitation_id}, socket) do
    case Organizations.cancel_invitation(invitation_id, socket.assigns.current_user.id) do
      {:ok, _} ->
        invitations = Organizations.list_organization_invitations(socket.assigns.organization.id)

        {:noreply,
         socket
         |> assign(:invitations, invitations)
         |> put_flash(:info, "Invitation cancelled")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel invitation")}
    end
  end

  @impl true
  def handle_event("remove_team", %{"team_id" => team_id}, socket) do
    case Organizations.remove_team_from_organization(
      team_id,
      socket.assigns.organization.id,
      socket.assigns.current_user.id
    ) do
      {:ok, _} ->
        teams = Organizations.list_organization_teams(socket.assigns.organization.id)

        {:noreply,
         socket
         |> assign(:teams, teams)
         |> put_flash(:info, "Team removed from organization")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to remove team")}
    end
  end

  def role_badge_class(role) do
    case role do
      "owner" -> "bg-purple-100 text-purple-800"
      "admin" -> "bg-blue-100 text-blue-800"
      "billing_admin" -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
