defmodule ButtonLogWeb.OrganizationsLive do
  @moduledoc """
  LiveView for managing organizations.
  """

  use ButtonLogWeb, :live_view

  alias ButtonLog.{Accounts, Organizations}

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      organizations = Organizations.list_user_organizations(user_id)
      invitations = Organizations.list_user_organization_invitations(user_id)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:organizations, organizations)
       |> assign(:invitations, invitations)
       |> assign(:show_create_modal, false)
       |> assign(:new_org_form, to_form(%{"name" => "", "description" => "", "billing_email" => ""}))
       |> assign(:page_title, "Organizations")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access organizations")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_create_modal", _params, socket) do
    {:noreply, assign(socket, :show_create_modal, true)}
  end

  @impl true
  def handle_event("hide_create_modal", _params, socket) do
    {:noreply, assign(socket, :show_create_modal, false)}
  end

  @impl true
  def handle_event("validate_org", %{"name" => name, "description" => description, "billing_email" => billing_email}, socket) do
    form = to_form(%{"name" => name, "description" => description, "billing_email" => billing_email})
    {:noreply, assign(socket, :new_org_form, form)}
  end

  @impl true
  def handle_event("create_org", %{"name" => name, "description" => description, "billing_email" => billing_email}, socket) do
    attrs = %{
      name: name,
      description: description,
      billing_email: billing_email
    }

    case Organizations.create_organization(attrs, socket.assigns.current_user.id) do
      {:ok, _org} ->
        organizations = Organizations.list_user_organizations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:organizations, organizations)
         |> assign(:show_create_modal, false)
         |> assign(:new_org_form, to_form(%{"name" => "", "description" => "", "billing_email" => ""}))
         |> put_flash(:info, "Organization created successfully")}

      {:error, changeset} ->
        errors = format_errors(changeset)

        {:noreply,
         socket
         |> put_flash(:error, "Failed to create organization: #{errors}")}
    end
  end

  @impl true
  def handle_event("accept_invitation", %{"id" => invitation_id}, socket) do
    case Organizations.accept_invitation(invitation_id, socket.assigns.current_user.id) do
      {:ok, _member} ->
        organizations = Organizations.list_user_organizations(socket.assigns.current_user.id)
        invitations = Organizations.list_user_organization_invitations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:organizations, organizations)
         |> assign(:invitations, invitations)
         |> put_flash(:info, "You have joined the organization")}

      {:error, :expired} ->
        {:noreply, put_flash(socket, :error, "This invitation has expired")}

      {:error, :no_seats_available} ->
        {:noreply, put_flash(socket, :error, "No seats available in this organization")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to accept invitation")}
    end
  end

  @impl true
  def handle_event("decline_invitation", %{"id" => invitation_id}, socket) do
    case Organizations.decline_invitation(invitation_id, socket.assigns.current_user.id) do
      {:ok, _} ->
        invitations = Organizations.list_user_organization_invitations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:invitations, invitations)
         |> put_flash(:info, "Invitation declined")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to decline invitation")}
    end
  end

  @impl true
  def handle_event("leave_org", %{"id" => org_id}, socket) do
    case Organizations.remove_member(org_id, socket.assigns.current_user.id, socket.assigns.current_user.id) do
      {:ok, _} ->
        organizations = Organizations.list_user_organizations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:organizations, organizations)
         |> put_flash(:info, "You have left the organization")}

      {:error, :cannot_remove_owner} ->
        {:noreply, put_flash(socket, :error, "Owner cannot leave. Transfer ownership first.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to leave organization")}
    end
  end

  @impl true
  def handle_event("delete_org", %{"id" => org_id}, socket) do
    org = Organizations.get_organization(org_id)

    case Organizations.delete_organization(org, socket.assigns.current_user.id) do
      {:ok, _} ->
        organizations = Organizations.list_user_organizations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:organizations, organizations)
         |> put_flash(:info, "Organization deleted")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only the organization owner can delete it")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete organization")}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  def get_user_role(org, user_id) do
    member = Enum.find(org.members, fn m -> m.user_id == user_id end)
    if member, do: member.role, else: nil
  end

  def role_badge_class(role) do
    case role do
      "owner" -> "bg-purple-100 text-purple-800"
      "admin" -> "bg-primary-100 text-primary-700"
      "billing_admin" -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
