defmodule ButtonLogWeb.API.TeamController do
  use ButtonLogWeb, :controller

  alias ButtonLog.Teams

  # =============================================================================
  # Teams
  # =============================================================================

  @doc """
  GET /api/teams - List user's teams
  """
  def index(conn, _params) do
    user_id = conn.assigns.current_user.id
    teams = Teams.list_user_teams(user_id)

    json(conn, %{
      success: true,
      data: Enum.map(teams, &format_team/1)
    })
  end

  @doc """
  POST /api/teams - Create a new team
  """
  def create(conn, params) do
    user_id = conn.assigns.current_user.id

    case Teams.create_team(params, user_id) do
      {:ok, team} ->
        conn
        |> put_status(:created)
        |> json(%{success: true, data: format_team(team)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  GET /api/teams/:id - Get a team
  """
  def show(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user.id

    case Teams.get_team_for_user(id, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Team not found"}})

      team ->
        json(conn, %{success: true, data: format_team_detail(team, user_id)})
    end
  end

  @doc """
  PUT /api/teams/:id - Update a team
  """
  def update(conn, %{"id" => id} = params) do
    user_id = conn.assigns.current_user.id

    with team when not is_nil(team) <- Teams.get_team(id),
         {:ok, updated_team} <- Teams.update_team(team, params, user_id) do
      json(conn, %{success: true, data: format_team(updated_team)})
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Team not found"}})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to update this team"}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  DELETE /api/teams/:id - Delete a team
  """
  def delete(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user.id

    with team when not is_nil(team) <- Teams.get_team(id),
         {:ok, _} <- Teams.delete_team(team, user_id) do
      json(conn, %{success: true, message: "Team deleted"})
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Team not found"}})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "Only the team owner can delete the team"}})
    end
  end

  # =============================================================================
  # Team Members
  # =============================================================================

  @doc """
  GET /api/teams/:team_id/members - List team members
  """
  def list_members(conn, %{"team_id" => team_id}) do
    user_id = conn.assigns.current_user.id

    if Teams.member_of_team?(team_id, user_id) do
      members = Teams.list_team_members(team_id)
      json(conn, %{success: true, data: Enum.map(members, &format_member/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You are not a member of this team"}})
    end
  end

  @doc """
  PUT /api/teams/:team_id/members/:user_id/role - Update member role
  """
  def update_member_role(conn, %{"team_id" => team_id, "user_id" => member_user_id, "role" => role}) do
    acting_user_id = conn.assigns.current_user.id

    case Teams.update_member_role(team_id, member_user_id, role, acting_user_id) do
      {:ok, member} ->
        json(conn, %{success: true, data: format_member(member)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to change roles"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Member not found"}})

      {:error, :cannot_change_owner} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Cannot change the owner's role"}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  DELETE /api/teams/:team_id/members/:user_id - Remove a member
  """
  def remove_member(conn, %{"team_id" => team_id, "user_id" => member_user_id}) do
    acting_user_id = conn.assigns.current_user.id

    case Teams.remove_member(team_id, member_user_id, acting_user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Member removed"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to remove this member"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Member not found"}})

      {:error, :cannot_remove_owner} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Cannot remove the team owner"}})
    end
  end

  @doc """
  POST /api/teams/:team_id/leave - Leave a team
  """
  def leave(conn, %{"team_id" => team_id}) do
    user_id = conn.assigns.current_user.id

    case Teams.remove_member(team_id, user_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "You have left the team"})

      {:error, :cannot_remove_owner} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Owner cannot leave. Transfer ownership first."}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "You are not a member of this team"}})
    end
  end

  @doc """
  POST /api/teams/:team_id/transfer-ownership - Transfer team ownership
  """
  def transfer_ownership(conn, %{"team_id" => team_id, "new_owner_id" => new_owner_id}) do
    user_id = conn.assigns.current_user.id

    case Teams.transfer_ownership(team_id, new_owner_id, user_id) do
      {:ok, team} ->
        json(conn, %{success: true, data: format_team(team)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "Only the owner can transfer ownership"}})

      {:error, :not_a_member} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "New owner must be a team member"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Team not found"}})
    end
  end

  # =============================================================================
  # Team Buttons
  # =============================================================================

  @doc """
  GET /api/teams/:team_id/buttons - List team buttons
  """
  def list_buttons(conn, %{"team_id" => team_id}) do
    user_id = conn.assigns.current_user.id

    if Teams.member_of_team?(team_id, user_id) do
      team_buttons = Teams.list_team_buttons(team_id)
      json(conn, %{success: true, data: Enum.map(team_buttons, &format_team_button/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You are not a member of this team"}})
    end
  end

  @doc """
  POST /api/teams/:team_id/buttons - Add a button to team
  """
  def add_button(conn, %{"team_id" => team_id, "button_id" => button_id} = params) do
    user_id = conn.assigns.current_user.id
    permission = Map.get(params, "permission", "click")

    case Teams.add_button_to_team(team_id, button_id, permission, user_id) do
      {:ok, team_button} ->
        team_button = ButtonLog.Repo.preload(team_button, [:button, :added_by])

        conn
        |> put_status(:created)
        |> json(%{success: true, data: format_team_button(team_button)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to add buttons"}})

      {:error, :button_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Button not found"}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  PUT /api/teams/:team_id/buttons/:button_id - Update button permission
  """
  def update_button_permission(conn, %{"team_id" => team_id, "button_id" => button_id, "permission" => permission}) do
    user_id = conn.assigns.current_user.id

    case Teams.update_team_button_permission(team_id, button_id, permission, user_id) do
      {:ok, team_button} ->
        team_button = ButtonLog.Repo.preload(team_button, [:button, :added_by])
        json(conn, %{success: true, data: format_team_button(team_button)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to update button permissions"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Button not found in team"}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  DELETE /api/teams/:team_id/buttons/:button_id - Remove button from team
  """
  def remove_button(conn, %{"team_id" => team_id, "button_id" => button_id}) do
    user_id = conn.assigns.current_user.id

    case Teams.remove_button_from_team(team_id, button_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Button removed from team"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to remove buttons"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Button not found in team"}})
    end
  end

  # =============================================================================
  # Invitations
  # =============================================================================

  @doc """
  GET /api/teams/:team_id/invitations - List team invitations
  """
  def list_invitations(conn, %{"team_id" => team_id}) do
    user_id = conn.assigns.current_user.id

    if Teams.can_manage_team?(team_id, user_id) do
      invitations = Teams.list_team_invitations(team_id)
      json(conn, %{success: true, data: Enum.map(invitations, &format_invitation/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You don't have permission to view invitations"}})
    end
  end

  @doc """
  GET /api/teams/invitations - List user's pending invitations
  """
  def my_invitations(conn, _params) do
    user_id = conn.assigns.current_user.id
    invitations = Teams.list_user_invitations(user_id)
    json(conn, %{success: true, data: Enum.map(invitations, &format_invitation/1)})
  end

  @doc """
  POST /api/teams/:team_id/invitations - Create invitation
  """
  def create_invitation(conn, %{"team_id" => team_id, "user_id" => invitee_id} = params) do
    user_id = conn.assigns.current_user.id
    role = Map.get(params, "role", "member")

    case Teams.create_invitation(team_id, user_id, invitee_id, role) do
      {:ok, invitation} ->
        invitation = ButtonLog.Repo.preload(invitation, [:team, :inviter, :invitee])

        conn
        |> put_status(:created)
        |> json(%{success: true, data: format_invitation(invitation)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to invite members"}})

      {:error, :already_member} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "User is already a member of this team"}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  POST /api/teams/invitations/:id/accept - Accept invitation
  """
  def accept_invitation(conn, %{"id" => invitation_id}) do
    user_id = conn.assigns.current_user.id

    case Teams.accept_invitation(invitation_id, user_id) do
      {:ok, member} ->
        member = ButtonLog.Repo.preload(member, [:team, :user])
        json(conn, %{success: true, data: format_member(member), message: "You have joined the team"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Invitation not found"}})

      {:error, :expired} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Invitation has expired"}})

      {:error, :wrong_user} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "This invitation is for someone else"}})
    end
  end

  @doc """
  POST /api/teams/invitations/:id/decline - Decline invitation
  """
  def decline_invitation(conn, %{"id" => invitation_id}) do
    user_id = conn.assigns.current_user.id

    case Teams.decline_invitation(invitation_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Invitation declined"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Invitation not found"}})

      {:error, :wrong_user} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "This invitation is for someone else"}})
    end
  end

  @doc """
  DELETE /api/teams/:team_id/invitations/:id - Cancel invitation
  """
  def cancel_invitation(conn, %{"team_id" => _team_id, "id" => invitation_id}) do
    user_id = conn.assigns.current_user.id

    case Teams.cancel_invitation(invitation_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Invitation cancelled"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Invitation not found"}})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to cancel invitations"}})
    end
  end

  # =============================================================================
  # Formatters
  # =============================================================================

  defp format_team(team) do
    %{
      id: team.id,
      name: team.name,
      description: team.description,
      icon: team.icon,
      color: team.color,
      owner_id: team.owner_id,
      owner: format_user(team.owner),
      member_count: length(team.members || []),
      created_at: team.inserted_at,
      updated_at: team.updated_at
    }
  end

  defp format_team_detail(team, user_id) do
    role = Teams.get_user_role(team.id, user_id)

    format_team(team)
    |> Map.merge(%{
      my_role: role,
      can_manage: ButtonLog.Teams.TeamMember.is_admin?(role),
      members: Enum.map(team.members || [], &format_member/1),
      buttons: Enum.map(team.team_buttons || [], &format_team_button/1)
    })
  end

  defp format_member(member) do
    %{
      id: member.id,
      user_id: member.user_id,
      user: if(Ecto.assoc_loaded?(member.user), do: format_user(member.user), else: nil),
      role: member.role,
      joined_at: member.joined_at,
      invited_by: if(Ecto.assoc_loaded?(member.invited_by) && member.invited_by, do: format_user(member.invited_by), else: nil)
    }
  end

  defp format_team_button(team_button) do
    %{
      id: team_button.id,
      button_id: team_button.button_id,
      button: if(Ecto.assoc_loaded?(team_button.button), do: format_button(team_button.button), else: nil),
      permission: team_button.permission,
      added_by: if(Ecto.assoc_loaded?(team_button.added_by) && team_button.added_by, do: format_user(team_button.added_by), else: nil),
      added_at: team_button.inserted_at
    }
  end

  defp format_invitation(invitation) do
    %{
      id: invitation.id,
      team_id: invitation.team_id,
      team: if(Ecto.assoc_loaded?(invitation.team), do: %{id: invitation.team.id, name: invitation.team.name}, else: nil),
      inviter: if(Ecto.assoc_loaded?(invitation.inviter), do: format_user(invitation.inviter), else: nil),
      invitee: if(invitation.invitee && Ecto.assoc_loaded?(invitation.invitee), do: format_user(invitation.invitee), else: nil),
      email: invitation.email,
      role: invitation.role,
      token: invitation.token,
      expires_at: invitation.expires_at,
      created_at: invitation.inserted_at
    }
  end

  defp format_user(nil), do: nil

  defp format_user(user) do
    %{
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      avatar_url: user.avatar
    }
  end

  defp format_button(nil), do: nil

  defp format_button(button) do
    %{
      id: button.id,
      name: button.name,
      type: button.type,
      icon: button.icon,
      color: button.color,
      current_state: button.current_state
    }
  end

  defp format_changeset_errors(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    %{message: "Validation failed", errors: errors}
  end
end
