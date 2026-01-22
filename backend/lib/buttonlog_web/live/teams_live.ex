defmodule ButtonLogWeb.TeamsLive do
  @moduledoc """
  LiveView for managing teams.
  """

  use ButtonLogWeb, :live_view

  alias ButtonLog.{Accounts, Teams}

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      current_user = Accounts.get_user!(user_id)
      teams = Teams.list_user_teams(user_id)
      invitations = Teams.list_user_invitations(user_id)

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:teams, teams)
       |> assign(:invitations, invitations)
       |> assign(:show_create_modal, false)
       |> assign(:new_team_form, to_form(%{"name" => "", "description" => "", "color" => "#3B82F6"}))
       |> assign(:page_title, "Teams")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access teams")
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
  def handle_event("validate_team", %{"name" => name, "description" => description, "color" => color}, socket) do
    form = to_form(%{"name" => name, "description" => description, "color" => color})
    {:noreply, assign(socket, :new_team_form, form)}
  end

  @impl true
  def handle_event("create_team", %{"name" => name, "description" => description, "color" => color}, socket) do
    attrs = %{
      name: name,
      description: description,
      color: color
    }

    case Teams.create_team(attrs, socket.assigns.current_user.id) do
      {:ok, _team} ->
        teams = Teams.list_user_teams(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:teams, teams)
         |> assign(:show_create_modal, false)
         |> assign(:new_team_form, to_form(%{"name" => "", "description" => "", "color" => "#3B82F6"}))
         |> put_flash(:info, "Team created successfully")}

      {:error, changeset} ->
        errors = format_errors(changeset)

        {:noreply,
         socket
         |> put_flash(:error, "Failed to create team: #{errors}")}
    end
  end

  @impl true
  def handle_event("accept_invitation", %{"id" => invitation_id}, socket) do
    case Teams.accept_invitation(invitation_id, socket.assigns.current_user.id) do
      {:ok, _member} ->
        teams = Teams.list_user_teams(socket.assigns.current_user.id)
        invitations = Teams.list_user_invitations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:teams, teams)
         |> assign(:invitations, invitations)
         |> put_flash(:info, "You have joined the team")}

      {:error, :expired} ->
        {:noreply, put_flash(socket, :error, "This invitation has expired")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to accept invitation")}
    end
  end

  @impl true
  def handle_event("decline_invitation", %{"id" => invitation_id}, socket) do
    case Teams.decline_invitation(invitation_id, socket.assigns.current_user.id) do
      {:ok, _} ->
        invitations = Teams.list_user_invitations(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:invitations, invitations)
         |> put_flash(:info, "Invitation declined")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to decline invitation")}
    end
  end

  @impl true
  def handle_event("leave_team", %{"id" => team_id}, socket) do
    case Teams.remove_member(team_id, socket.assigns.current_user.id, socket.assigns.current_user.id) do
      {:ok, _} ->
        teams = Teams.list_user_teams(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:teams, teams)
         |> put_flash(:info, "You have left the team")}

      {:error, :cannot_remove_owner} ->
        {:noreply, put_flash(socket, :error, "Owner cannot leave. Transfer ownership first.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to leave team")}
    end
  end

  @impl true
  def handle_event("delete_team", %{"id" => team_id}, socket) do
    team = Teams.get_team(team_id)

    case Teams.delete_team(team, socket.assigns.current_user.id) do
      {:ok, _} ->
        teams = Teams.list_user_teams(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:teams, teams)
         |> put_flash(:info, "Team deleted")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only the team owner can delete the team")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete team")}
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

  def get_user_role(team, user_id) do
    member = Enum.find(team.members, fn m -> m.user_id == user_id end)
    if member, do: member.role, else: nil
  end

  def role_badge_class(role) do
    case role do
      "owner" -> "bg-purple-100 text-purple-800"
      "admin" -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
