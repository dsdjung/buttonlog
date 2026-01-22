defmodule ButtonLog.Teams do
  @moduledoc """
  The Teams context.

  Teams are groups of users who share buttons together. Users can create teams,
  invite members, and share buttons with the entire team.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo

  alias ButtonLog.Teams.{Team, TeamMember, TeamButton, TeamInvitation}
  alias ButtonLog.Buttons.Button

  # =============================================================================
  # Teams
  # =============================================================================

  @doc """
  Returns the list of teams for a user (as owner or member).
  """
  def list_user_teams(user_id) do
    Repo.all(
      from t in Team,
        left_join: m in TeamMember,
        on: m.team_id == t.id,
        where: t.owner_id == ^user_id or m.user_id == ^user_id,
        distinct: true,
        preload: [:owner, members: :user],
        order_by: [asc: t.name]
    )
  end

  @doc """
  Gets a single team by ID.
  """
  def get_team(id) do
    Repo.get(Team, id)
    |> Repo.preload([:owner, members: :user, team_buttons: :button])
  end

  @doc """
  Gets a team if the user is a member or owner.
  """
  def get_team_for_user(team_id, user_id) do
    team = get_team(team_id)

    if team && (team.owner_id == user_id || member_of_team?(team_id, user_id)) do
      team
    else
      nil
    end
  end

  @doc """
  Creates a team and adds the creator as the owner member.
  """
  def create_team(attrs, owner_id) do
    Repo.transaction(fn ->
      # Create the team
      team_result =
        %Team{}
        |> Team.create_changeset(attrs, owner_id)
        |> Repo.insert()

      case team_result do
        {:ok, team} ->
          # Add owner as a member with owner role
          member_result =
            %TeamMember{}
            |> TeamMember.create_changeset(%{role: "owner"}, team.id, owner_id)
            |> Repo.insert()

          case member_result do
            {:ok, _member} ->
              get_team(team.id)

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a team.
  Only the owner or admins can update.
  """
  def update_team(%Team{} = team, attrs, user_id) do
    if can_manage_team?(team.id, user_id) do
      team
      |> Team.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a team.
  Only the owner can delete.
  """
  def delete_team(%Team{} = team, user_id) do
    if team.owner_id == user_id do
      Repo.delete(team)
    else
      {:error, :unauthorized}
    end
  end

  # =============================================================================
  # Team Members
  # =============================================================================

  @doc """
  Lists all members of a team.
  """
  def list_team_members(team_id) do
    Repo.all(
      from m in TeamMember,
        where: m.team_id == ^team_id,
        preload: [:user, :invited_by],
        order_by: [asc: m.role, asc: m.joined_at]
    )
  end

  @doc """
  Gets a team member.
  """
  def get_team_member(team_id, user_id) do
    Repo.get_by(TeamMember, team_id: team_id, user_id: user_id)
    |> Repo.preload([:user, :invited_by])
  end

  @doc """
  Checks if a user is a member of a team.
  """
  def member_of_team?(team_id, user_id) do
    Repo.exists?(
      from m in TeamMember,
        where: m.team_id == ^team_id and m.user_id == ^user_id
    )
  end

  @doc """
  Gets the user's role in a team.
  """
  def get_user_role(team_id, user_id) do
    Repo.one(
      from m in TeamMember,
        where: m.team_id == ^team_id and m.user_id == ^user_id,
        select: m.role
    )
  end

  @doc """
  Checks if a user can manage a team (is owner or admin).
  """
  def can_manage_team?(team_id, user_id) do
    role = get_user_role(team_id, user_id)
    TeamMember.is_admin?(role)
  end

  @doc """
  Adds a member to a team directly (for accepting invitations).
  """
  def add_member(team_id, user_id, role \\ "member", invited_by_id \\ nil) do
    %TeamMember{}
    |> TeamMember.create_changeset(%{role: role}, team_id, user_id, invited_by_id)
    |> Repo.insert()
  end

  @doc """
  Updates a member's role.
  Only owner can change roles. Cannot demote owner.
  """
  def update_member_role(team_id, member_user_id, new_role, acting_user_id) do
    with true <- can_manage_team?(team_id, acting_user_id),
         member when not is_nil(member) <- get_team_member(team_id, member_user_id),
         false <- member.role == "owner" do
      member
      |> TeamMember.changeset(%{role: new_role})
      |> Repo.update()
    else
      nil -> {:error, :not_found}
      # When member.role == "owner" returns true, the with check `false <- true` fails with true
      true -> {:error, :cannot_change_owner}
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Removes a member from a team.
  Owners can remove anyone except themselves.
  Admins can remove non-admin members.
  Members can remove themselves.
  """
  def remove_member(team_id, member_user_id, acting_user_id) do
    member = get_team_member(team_id, member_user_id)
    acting_role = get_user_role(team_id, acting_user_id)

    cond do
      is_nil(member) ->
        {:error, :not_found}

      # Owner cannot be removed
      member.role == "owner" ->
        {:error, :cannot_remove_owner}

      # User removing themselves
      member_user_id == acting_user_id ->
        Repo.delete(member)

      # Owner can remove anyone
      acting_role == "owner" ->
        Repo.delete(member)

      # Admin can remove non-admins
      acting_role == "admin" && member.role == "member" ->
        Repo.delete(member)

      true ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Transfers team ownership to another member.
  """
  def transfer_ownership(team_id, new_owner_id, current_owner_id) do
    team = get_team(team_id)

    cond do
      is_nil(team) ->
        {:error, :not_found}

      team.owner_id != current_owner_id ->
        {:error, :unauthorized}

      !member_of_team?(team_id, new_owner_id) ->
        {:error, :not_a_member}

      true ->
        Repo.transaction(fn ->
          # Update team owner
          {:ok, _team} =
            team
            |> Ecto.Changeset.change(owner_id: new_owner_id)
            |> Repo.update()

          # Update old owner to admin
          old_owner_member = get_team_member(team_id, current_owner_id)

          {:ok, _} =
            old_owner_member
            |> TeamMember.changeset(%{role: "admin"})
            |> Repo.update()

          # Update new owner to owner role
          new_owner_member = get_team_member(team_id, new_owner_id)

          {:ok, _} =
            new_owner_member
            |> TeamMember.changeset(%{role: "owner"})
            |> Repo.update()

          get_team(team_id)
        end)
    end
  end

  # =============================================================================
  # Team Buttons
  # =============================================================================

  @doc """
  Lists all buttons shared with a team.
  """
  def list_team_buttons(team_id) do
    Repo.all(
      from tb in TeamButton,
        where: tb.team_id == ^team_id,
        preload: [:button, :added_by],
        order_by: [desc: tb.inserted_at]
    )
  end

  @doc """
  Gets buttons available to a user through their team memberships.
  """
  def get_team_buttons_for_user(user_id) do
    Repo.all(
      from tb in TeamButton,
        join: m in TeamMember,
        on: m.team_id == tb.team_id,
        where: m.user_id == ^user_id,
        preload: [:button, team: :owner],
        order_by: [desc: tb.inserted_at]
    )
  end

  @doc """
  Adds a button to a team.
  Only the button owner or team admins can add buttons.
  """
  def add_button_to_team(team_id, button_id, permission, user_id) do
    button = Repo.get(Button, button_id)

    cond do
      is_nil(button) ->
        {:error, :button_not_found}

      button.user_id != user_id && !can_manage_team?(team_id, user_id) ->
        {:error, :unauthorized}

      true ->
        %TeamButton{}
        |> TeamButton.create_changeset(%{permission: permission}, team_id, button_id, user_id)
        |> Repo.insert()
    end
  end

  @doc """
  Updates a team button's permission.
  """
  def update_team_button_permission(team_id, button_id, permission, user_id) do
    with true <- can_manage_team?(team_id, user_id),
         team_button when not is_nil(team_button) <-
           Repo.get_by(TeamButton, team_id: team_id, button_id: button_id) do
      team_button
      |> TeamButton.changeset(%{permission: permission})
      |> Repo.update()
    else
      nil -> {:error, :not_found}
      false -> {:error, :unauthorized}
    end
  end

  @doc """
  Removes a button from a team.
  """
  def remove_button_from_team(team_id, button_id, user_id) do
    team_button = Repo.get_by(TeamButton, team_id: team_id, button_id: button_id)
    button = Repo.get(Button, button_id)

    cond do
      is_nil(team_button) ->
        {:error, :not_found}

      # Button owner can always remove
      button && button.user_id == user_id ->
        Repo.delete(team_button)

      # Team admin can remove
      can_manage_team?(team_id, user_id) ->
        Repo.delete(team_button)

      true ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Checks if a user can click a button through team membership.
  """
  def can_click_via_team?(button_id, user_id) do
    Repo.exists?(
      from tb in TeamButton,
        join: m in TeamMember,
        on: m.team_id == tb.team_id,
        where:
          tb.button_id == ^button_id and
            m.user_id == ^user_id and
            tb.permission in ["click", "admin"]
    )
  end

  # =============================================================================
  # Team Invitations
  # =============================================================================

  @doc """
  Lists pending invitations for a team.
  """
  def list_team_invitations(team_id) do
    now = DateTime.utc_now()

    Repo.all(
      from i in TeamInvitation,
        where:
          i.team_id == ^team_id and
            is_nil(i.accepted_at) and
            is_nil(i.declined_at) and
            i.expires_at > ^now,
        preload: [:inviter, :invitee],
        order_by: [desc: i.inserted_at]
    )
  end

  @doc """
  Lists pending invitations for a user.
  """
  def list_user_invitations(user_id) do
    now = DateTime.utc_now()

    Repo.all(
      from i in TeamInvitation,
        where:
          i.invitee_id == ^user_id and
            is_nil(i.accepted_at) and
            is_nil(i.declined_at) and
            i.expires_at > ^now,
        preload: [:team, :inviter],
        order_by: [desc: i.inserted_at]
    )
  end

  @doc """
  Creates an invitation to join a team.
  """
  def create_invitation(team_id, inviter_id, invitee_id, role \\ "member") do
    if can_manage_team?(team_id, inviter_id) do
      # Check if already a member
      if member_of_team?(team_id, invitee_id) do
        {:error, :already_member}
      else
        %TeamInvitation{}
        |> TeamInvitation.create_changeset(%{role: role}, team_id, inviter_id, invitee_id)
        |> Repo.insert()
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Creates an invitation by email (for non-users).
  """
  def create_email_invitation(team_id, inviter_id, email, role \\ "member") do
    if can_manage_team?(team_id, inviter_id) do
      %TeamInvitation{}
      |> TeamInvitation.create_changeset(%{email: email, role: role}, team_id, inviter_id)
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Gets an invitation by token.
  """
  def get_invitation_by_token(token) do
    Repo.get_by(TeamInvitation, token: token)
    |> Repo.preload([:team, :inviter])
  end

  @doc """
  Accepts an invitation.
  """
  def accept_invitation(invitation_id, user_id) do
    invitation =
      Repo.get(TeamInvitation, invitation_id)
      |> Repo.preload(:team)

    cond do
      is_nil(invitation) ->
        {:error, :not_found}

      !TeamInvitation.valid?(invitation) ->
        {:error, :expired}

      invitation.invitee_id && invitation.invitee_id != user_id ->
        {:error, :wrong_user}

      true ->
        Repo.transaction(fn ->
          # Mark invitation as accepted
          {:ok, _} =
            invitation
            |> TeamInvitation.accept_changeset()
            |> Repo.update()

          # Add user as member
          {:ok, member} = add_member(invitation.team_id, user_id, invitation.role, invitation.inviter_id)

          member
        end)
    end
  end

  @doc """
  Declines an invitation.
  """
  def decline_invitation(invitation_id, user_id) do
    invitation = Repo.get(TeamInvitation, invitation_id)

    cond do
      is_nil(invitation) ->
        {:error, :not_found}

      invitation.invitee_id && invitation.invitee_id != user_id ->
        {:error, :wrong_user}

      true ->
        invitation
        |> TeamInvitation.decline_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Cancels an invitation (by team admin).
  """
  def cancel_invitation(invitation_id, user_id) do
    invitation = Repo.get(TeamInvitation, invitation_id)

    cond do
      is_nil(invitation) ->
        {:error, :not_found}

      !can_manage_team?(invitation.team_id, user_id) ->
        {:error, :unauthorized}

      true ->
        Repo.delete(invitation)
    end
  end

  # =============================================================================
  # Stats & Counts
  # =============================================================================

  @doc """
  Counts the number of teams a user owns.
  """
  def count_owned_teams(user_id) do
    Repo.one(
      from t in Team,
        where: t.owner_id == ^user_id,
        select: count(t.id)
    )
  end

  @doc """
  Counts the number of members in a team.
  """
  def count_team_members(team_id) do
    Repo.one(
      from m in TeamMember,
        where: m.team_id == ^team_id,
        select: count(m.id)
    )
  end

  @doc """
  Counts the number of buttons shared with a team.
  """
  def count_team_buttons(team_id) do
    Repo.one(
      from tb in TeamButton,
        where: tb.team_id == ^team_id,
        select: count(tb.id)
    )
  end
end
