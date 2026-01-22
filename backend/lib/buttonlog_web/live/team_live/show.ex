defmodule ButtonLogWeb.TeamLive.Show do
  @moduledoc """
  LiveView for viewing and managing a single team.
  """

  use ButtonLogWeb, :live_view

  alias ButtonLog.{Accounts, Teams, Buttons}
  alias ButtonLog.Teams.TeamMember

  @impl true
  def mount(%{"id" => team_id}, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      team = Teams.get_team_for_user(team_id, user_id)

      if team do
        role = Teams.get_user_role(team_id, user_id)
        user_buttons = Buttons.list_user_buttons(user_id)
        invitations = Teams.list_team_invitations(team_id)

        {:ok,
         socket
         |> assign(:current_user, current_user)
         |> assign(:team, team)
         |> assign(:my_role, role)
         |> assign(:can_manage, TeamMember.is_admin?(role))
         |> assign(:user_buttons, user_buttons)
         |> assign(:invitations, invitations)
         |> assign(:show_invite_modal, false)
         |> assign(:show_add_button_modal, false)
         |> assign(:page_title, team.name)}
      else
        {:ok,
         socket
         |> put_flash(:error, "Team not found")
         |> redirect(to: ~p"/teams")}
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
  def handle_event("show_add_button_modal", _params, socket) do
    {:noreply, assign(socket, :show_add_button_modal, true)}
  end

  @impl true
  def handle_event("hide_add_button_modal", _params, socket) do
    {:noreply, assign(socket, :show_add_button_modal, false)}
  end

  @impl true
  def handle_event("add_button", %{"button_id" => button_id, "permission" => permission}, socket) do
    case Teams.add_button_to_team(socket.assigns.team.id, button_id, permission, socket.assigns.current_user.id) do
      {:ok, _} ->
        team = Teams.get_team(socket.assigns.team.id)

        {:noreply,
         socket
         |> assign(:team, team)
         |> assign(:show_add_button_modal, false)
         |> put_flash(:info, "Button added to team")}

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        {:noreply, put_flash(socket, :error, "Button is already shared with this team")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to add button")}
    end
  end

  @impl true
  def handle_event("remove_button", %{"button_id" => button_id}, socket) do
    case Teams.remove_button_from_team(socket.assigns.team.id, button_id, socket.assigns.current_user.id) do
      {:ok, _} ->
        team = Teams.get_team(socket.assigns.team.id)

        {:noreply,
         socket
         |> assign(:team, team)
         |> put_flash(:info, "Button removed from team")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to remove button")}
    end
  end

  @impl true
  def handle_event("update_member_role", %{"user_id" => member_user_id, "role" => role}, socket) do
    case Teams.update_member_role(socket.assigns.team.id, member_user_id, role, socket.assigns.current_user.id) do
      {:ok, _} ->
        team = Teams.get_team(socket.assigns.team.id)

        {:noreply,
         socket
         |> assign(:team, team)
         |> put_flash(:info, "Member role updated")}

      {:error, :cannot_change_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot change owner's role")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update role")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user_id" => member_user_id}, socket) do
    case Teams.remove_member(socket.assigns.team.id, member_user_id, socket.assigns.current_user.id) do
      {:ok, _} ->
        team = Teams.get_team(socket.assigns.team.id)

        {:noreply,
         socket
         |> assign(:team, team)
         |> put_flash(:info, "Member removed")}

      {:error, :cannot_remove_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot remove team owner")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to remove member")}
    end
  end

  @impl true
  def handle_event("cancel_invitation", %{"id" => invitation_id}, socket) do
    case Teams.cancel_invitation(invitation_id, socket.assigns.current_user.id) do
      {:ok, _} ->
        invitations = Teams.list_team_invitations(socket.assigns.team.id)

        {:noreply,
         socket
         |> assign(:invitations, invitations)
         |> put_flash(:info, "Invitation cancelled")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel invitation")}
    end
  end

  @impl true
  def handle_event("invite_member", %{"username" => username, "role" => role}, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found")}

      invitee ->
        case Teams.create_invitation(socket.assigns.team.id, socket.assigns.current_user.id, invitee.id, role) do
          {:ok, _invitation} ->
            invitations = Teams.list_team_invitations(socket.assigns.team.id)

            {:noreply,
             socket
             |> assign(:invitations, invitations)
             |> assign(:show_invite_modal, false)
             |> put_flash(:info, "Invitation sent to #{username}")}

          {:error, :already_member} ->
            {:noreply, put_flash(socket, :error, "User is already a member of this team")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to send invitation")}
        end
    end
  end

  def role_badge_class(role) do
    case role do
      "owner" -> "bg-purple-100 text-purple-800"
      "admin" -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  def permission_badge_class(permission) do
    case permission do
      "admin" -> "bg-purple-100 text-purple-800"
      "click" -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
