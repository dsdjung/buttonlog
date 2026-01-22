defmodule ButtonLog.Organizations do
  @moduledoc """
  The Organizations context.

  Organizations are top-level enterprise entities that can contain multiple teams
  and have organization-level subscriptions with seat-based pricing.
  """

  import Ecto.Query, warn: false
  alias ButtonLog.Repo

  alias ButtonLog.Organizations.{
    Organization,
    OrganizationMember,
    OrganizationInvitation,
    OrganizationSubscription,
    OrganizationAuditLog
  }
  alias ButtonLog.Teams.Team

  # =============================================================================
  # Organizations
  # =============================================================================

  @doc """
  Returns the list of organizations for a user.
  """
  def list_user_organizations(user_id) do
    Repo.all(
      from o in Organization,
        join: m in OrganizationMember,
        on: m.organization_id == o.id,
        where: m.user_id == ^user_id and m.status == "active",
        preload: [:subscription],
        order_by: [asc: o.name]
    )
  end

  @doc """
  Gets a single organization by ID.
  """
  def get_organization(id) do
    Repo.get(Organization, id)
    |> Repo.preload([:subscription, members: :user, teams: [], invitations: [:inviter, :invitee]])
  end

  @doc """
  Gets an organization by slug.
  """
  def get_organization_by_slug(slug) do
    Repo.get_by(Organization, slug: slug)
    |> Repo.preload([:subscription, members: :user])
  end

  @doc """
  Gets an organization if the user is a member.
  """
  def get_organization_for_user(org_id, user_id) do
    org = get_organization(org_id)

    if org && member_of_organization?(org_id, user_id) do
      org
    else
      nil
    end
  end

  @doc """
  Creates an organization and adds the creator as the owner.
  """
  def create_organization(attrs, owner_id) do
    Repo.transaction(fn ->
      # Create the organization
      org_result =
        %Organization{}
        |> Organization.create_changeset(attrs)
        |> Repo.insert()

      case org_result do
        {:ok, org} ->
          # Add owner as a member
          member_result =
            %OrganizationMember{}
            |> OrganizationMember.create_changeset(%{role: "owner"}, org.id, owner_id)
            |> Repo.insert()

          case member_result do
            {:ok, _member} ->
              # Log the creation
              log_action(org.id, owner_id, "organization_created", "organization", org.id, %{name: org.name})
              get_organization(org.id)

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates an organization.
  Only owners and admins can update.
  """
  def update_organization(%Organization{} = org, attrs, user_id) do
    if can_manage_organization?(org.id, user_id) do
      result =
        org
        |> Organization.changeset(attrs)
        |> Repo.update()

      case result do
        {:ok, updated_org} ->
          log_action(org.id, user_id, "organization_updated", "organization", org.id, %{changes: attrs})
          {:ok, updated_org}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes an organization.
  Only the owner can delete.
  """
  def delete_organization(%Organization{} = org, user_id) do
    if get_user_role(org.id, user_id) == "owner" do
      Repo.delete(org)
    else
      {:error, :unauthorized}
    end
  end

  # =============================================================================
  # Organization Members
  # =============================================================================

  @doc """
  Lists all members of an organization.
  """
  def list_organization_members(org_id) do
    Repo.all(
      from m in OrganizationMember,
        where: m.organization_id == ^org_id,
        preload: [:user, :invited_by],
        order_by: [asc: m.role, asc: m.joined_at]
    )
  end

  @doc """
  Gets an organization member.
  """
  def get_organization_member(org_id, user_id) do
    Repo.get_by(OrganizationMember, organization_id: org_id, user_id: user_id)
    |> Repo.preload([:user, :invited_by])
  end

  @doc """
  Checks if a user is a member of an organization.
  """
  def member_of_organization?(org_id, user_id) do
    Repo.exists?(
      from m in OrganizationMember,
        where: m.organization_id == ^org_id and m.user_id == ^user_id and m.status == "active"
    )
  end

  @doc """
  Gets the user's role in an organization.
  """
  def get_user_role(org_id, user_id) do
    Repo.one(
      from m in OrganizationMember,
        where: m.organization_id == ^org_id and m.user_id == ^user_id,
        select: m.role
    )
  end

  @doc """
  Checks if a user can manage an organization (is owner or admin).
  """
  def can_manage_organization?(org_id, user_id) do
    role = get_user_role(org_id, user_id)
    OrganizationMember.is_admin?(role)
  end

  @doc """
  Checks if a user can manage billing (is owner or billing_admin).
  """
  def can_manage_billing?(org_id, user_id) do
    role = get_user_role(org_id, user_id)
    OrganizationMember.can_manage_billing?(role)
  end

  @doc """
  Adds a member to an organization directly.
  """
  def add_member(org_id, user_id, role \\ "member", invited_by_id \\ nil, acting_user_id \\ nil) do
    # Check seat availability
    subscription = get_organization_subscription(org_id)

    cond do
      subscription && !OrganizationSubscription.seats_available?(subscription) ->
        {:error, :no_seats_available}

      true ->
        result =
          %OrganizationMember{}
          |> OrganizationMember.create_changeset(%{role: role}, org_id, user_id, invited_by_id)
          |> Repo.insert()

        case result do
          {:ok, member} ->
            # Update seat count
            if subscription do
              update_seat_count(org_id)
            end

            if acting_user_id do
              log_action(org_id, acting_user_id, "member_added", "user", user_id, %{role: role})
            end

            {:ok, member}

          error ->
            error
        end
    end
  end

  @doc """
  Updates a member's role.
  Only owner can change roles. Cannot demote owner.
  """
  def update_member_role(org_id, member_user_id, new_role, acting_user_id) do
    with true <- can_manage_organization?(org_id, acting_user_id),
         member when not is_nil(member) <- get_organization_member(org_id, member_user_id),
         false <- member.role == "owner" do
      result =
        member
        |> OrganizationMember.changeset(%{role: new_role})
        |> Repo.update()

      case result do
        {:ok, updated_member} ->
          log_action(org_id, acting_user_id, "member_role_changed", "user", member_user_id, %{
            old_role: member.role,
            new_role: new_role
          })
          {:ok, updated_member}

        error ->
          error
      end
    else
      nil -> {:error, :not_found}
      true -> {:error, :cannot_change_owner}
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Removes a member from an organization.
  """
  def remove_member(org_id, member_user_id, acting_user_id) do
    member = get_organization_member(org_id, member_user_id)
    acting_role = get_user_role(org_id, acting_user_id)

    cond do
      is_nil(member) ->
        {:error, :not_found}

      member.role == "owner" ->
        {:error, :cannot_remove_owner}

      member_user_id == acting_user_id ->
        result = Repo.delete(member)
        update_seat_count(org_id)
        result

      acting_role == "owner" ->
        result = Repo.delete(member)
        log_action(org_id, acting_user_id, "member_removed", "user", member_user_id, %{})
        update_seat_count(org_id)
        result

      acting_role == "admin" && member.role == "member" ->
        result = Repo.delete(member)
        log_action(org_id, acting_user_id, "member_removed", "user", member_user_id, %{})
        update_seat_count(org_id)
        result

      true ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Transfers organization ownership to another member.
  """
  def transfer_ownership(org_id, new_owner_id, current_owner_id) do
    org = get_organization(org_id)

    cond do
      is_nil(org) ->
        {:error, :not_found}

      get_user_role(org_id, current_owner_id) != "owner" ->
        {:error, :unauthorized}

      !member_of_organization?(org_id, new_owner_id) ->
        {:error, :not_a_member}

      true ->
        Repo.transaction(fn ->
          # Update old owner to admin
          old_owner_member = get_organization_member(org_id, current_owner_id)
          {:ok, _} =
            old_owner_member
            |> OrganizationMember.changeset(%{role: "admin"})
            |> Repo.update()

          # Update new owner to owner role
          new_owner_member = get_organization_member(org_id, new_owner_id)
          {:ok, _} =
            new_owner_member
            |> OrganizationMember.changeset(%{role: "owner"})
            |> Repo.update()

          log_action(org_id, current_owner_id, "organization_updated", "organization", org_id, %{
            action: "ownership_transferred",
            new_owner_id: new_owner_id
          })

          get_organization(org_id)
        end)
    end
  end

  # =============================================================================
  # Organization Teams
  # =============================================================================

  @doc """
  Lists all teams belonging to an organization.
  """
  def list_organization_teams(org_id) do
    Repo.all(
      from t in Team,
        where: t.organization_id == ^org_id,
        preload: [:owner, members: :user],
        order_by: [asc: t.name]
    )
  end

  @doc """
  Adds an existing team to an organization.
  """
  def add_team_to_organization(team_id, org_id, acting_user_id) do
    team = ButtonLog.Teams.get_team(team_id)

    cond do
      is_nil(team) ->
        {:error, :team_not_found}

      team.organization_id != nil ->
        {:error, :team_already_in_organization}

      team.owner_id != acting_user_id && !can_manage_organization?(org_id, acting_user_id) ->
        {:error, :unauthorized}

      true ->
        result =
          team
          |> Ecto.Changeset.change(organization_id: org_id)
          |> Repo.update()

        case result do
          {:ok, updated_team} ->
            log_action(org_id, acting_user_id, "team_added_to_org", "team", team_id, %{team_name: team.name})
            {:ok, updated_team}

          error ->
            error
        end
    end
  end

  @doc """
  Removes a team from an organization (but doesn't delete the team).
  """
  def remove_team_from_organization(team_id, org_id, acting_user_id) do
    team = ButtonLog.Teams.get_team(team_id)

    cond do
      is_nil(team) ->
        {:error, :team_not_found}

      team.organization_id != org_id ->
        {:error, :team_not_in_organization}

      !can_manage_organization?(org_id, acting_user_id) ->
        {:error, :unauthorized}

      true ->
        result =
          team
          |> Ecto.Changeset.change(organization_id: nil)
          |> Repo.update()

        case result do
          {:ok, updated_team} ->
            log_action(org_id, acting_user_id, "team_removed_from_org", "team", team_id, %{})
            {:ok, updated_team}

          error ->
            error
        end
    end
  end

  # =============================================================================
  # Organization Invitations
  # =============================================================================

  @doc """
  Lists pending invitations for an organization.
  """
  def list_organization_invitations(org_id) do
    now = DateTime.utc_now()

    Repo.all(
      from i in OrganizationInvitation,
        where:
          i.organization_id == ^org_id and
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
  def list_user_organization_invitations(user_id) do
    now = DateTime.utc_now()

    Repo.all(
      from i in OrganizationInvitation,
        where:
          i.invitee_id == ^user_id and
            is_nil(i.accepted_at) and
            is_nil(i.declined_at) and
            i.expires_at > ^now,
        preload: [:organization, :inviter],
        order_by: [desc: i.inserted_at]
    )
  end

  @doc """
  Creates an invitation to join an organization.
  """
  def create_invitation(org_id, inviter_id, invitee_id, role \\ "member") do
    if can_manage_organization?(org_id, inviter_id) do
      if member_of_organization?(org_id, invitee_id) do
        {:error, :already_member}
      else
        result =
          %OrganizationInvitation{}
          |> OrganizationInvitation.create_changeset(%{role: role}, org_id, inviter_id, invitee_id)
          |> Repo.insert()

        case result do
          {:ok, invitation} ->
            log_action(org_id, inviter_id, "invitation_sent", "invitation", invitation.id, %{
              invitee_id: invitee_id,
              role: role
            })
            {:ok, invitation}

          error ->
            error
        end
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Creates an invitation by email.
  """
  def create_email_invitation(org_id, inviter_id, email, role \\ "member") do
    if can_manage_organization?(org_id, inviter_id) do
      result =
        %OrganizationInvitation{}
        |> OrganizationInvitation.create_changeset(%{email: email, role: role}, org_id, inviter_id)
        |> Repo.insert()

      case result do
        {:ok, invitation} ->
          log_action(org_id, inviter_id, "invitation_sent", "invitation", invitation.id, %{
            email: email,
            role: role
          })
          {:ok, invitation}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Accepts an invitation.
  """
  def accept_invitation(invitation_id, user_id) do
    invitation =
      Repo.get(OrganizationInvitation, invitation_id)
      |> Repo.preload(:organization)

    cond do
      is_nil(invitation) ->
        {:error, :not_found}

      !OrganizationInvitation.valid?(invitation) ->
        {:error, :expired}

      invitation.invitee_id && invitation.invitee_id != user_id ->
        {:error, :wrong_user}

      true ->
        Repo.transaction(fn ->
          # Mark invitation as accepted
          {:ok, _} =
            invitation
            |> OrganizationInvitation.accept_changeset()
            |> Repo.update()

          # Add user as member
          {:ok, member} = add_member(
            invitation.organization_id,
            user_id,
            invitation.role,
            invitation.inviter_id
          )

          log_action(invitation.organization_id, user_id, "invitation_accepted", "invitation", invitation_id, %{})

          member
        end)
    end
  end

  @doc """
  Declines an invitation.
  """
  def decline_invitation(invitation_id, user_id) do
    invitation = Repo.get(OrganizationInvitation, invitation_id)

    cond do
      is_nil(invitation) ->
        {:error, :not_found}

      invitation.invitee_id && invitation.invitee_id != user_id ->
        {:error, :wrong_user}

      true ->
        result =
          invitation
          |> OrganizationInvitation.decline_changeset()
          |> Repo.update()

        case result do
          {:ok, _} ->
            log_action(invitation.organization_id, user_id, "invitation_declined", "invitation", invitation_id, %{})

          _ ->
            nil
        end

        result
    end
  end

  @doc """
  Cancels an invitation.
  """
  def cancel_invitation(invitation_id, user_id) do
    invitation = Repo.get(OrganizationInvitation, invitation_id)

    cond do
      is_nil(invitation) ->
        {:error, :not_found}

      !can_manage_organization?(invitation.organization_id, user_id) ->
        {:error, :unauthorized}

      true ->
        result = Repo.delete(invitation)

        case result do
          {:ok, _} ->
            log_action(invitation.organization_id, user_id, "invitation_cancelled", "invitation", invitation_id, %{})

          _ ->
            nil
        end

        result
    end
  end

  # =============================================================================
  # Organization Subscriptions
  # =============================================================================

  @doc """
  Gets the subscription for an organization.
  """
  def get_organization_subscription(org_id) do
    Repo.one(
      from s in OrganizationSubscription,
        where: s.organization_id == ^org_id,
        preload: [:plan]
    )
  end

  @doc """
  Creates a subscription for an organization.
  """
  def create_subscription(org_id, plan_id, attrs, acting_user_id) do
    if can_manage_billing?(org_id, acting_user_id) do
      result =
        %OrganizationSubscription{}
        |> OrganizationSubscription.create_changeset(attrs, org_id, plan_id)
        |> Repo.insert()

      case result do
        {:ok, subscription} ->
          log_action(org_id, acting_user_id, "subscription_created", "subscription", subscription.id, %{
            plan_id: plan_id
          })
          {:ok, subscription}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates an organization subscription.
  """
  def update_subscription(%OrganizationSubscription{} = subscription, attrs, acting_user_id) do
    if can_manage_billing?(subscription.organization_id, acting_user_id) do
      result =
        subscription
        |> OrganizationSubscription.changeset(attrs)
        |> Repo.update()

      case result do
        {:ok, updated_subscription} ->
          log_action(subscription.organization_id, acting_user_id, "subscription_updated", "subscription", subscription.id, %{
            changes: attrs
          })
          {:ok, updated_subscription}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates the seat count based on current member count.
  """
  def update_seat_count(org_id) do
    member_count = Repo.one(
      from m in OrganizationMember,
        where: m.organization_id == ^org_id and m.status == "active",
        select: count(m.id)
    )

    subscription = get_organization_subscription(org_id)

    if subscription do
      subscription
      |> Ecto.Changeset.change(seats_used: member_count)
      |> Repo.update()
    else
      {:ok, nil}
    end
  end

  # =============================================================================
  # Audit Logging
  # =============================================================================

  @doc """
  Logs an action in the audit log.
  """
  def log_action(org_id, actor_id, action, resource_type, resource_id, metadata) do
    %OrganizationAuditLog{}
    |> OrganizationAuditLog.create_changeset(
      %{
        action: action,
        resource_type: resource_type,
        resource_id: resource_id,
        metadata: metadata
      },
      org_id,
      actor_id
    )
    |> Repo.insert()
  end

  @doc """
  Lists audit logs for an organization.
  """
  def list_audit_logs(org_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    Repo.all(
      from l in OrganizationAuditLog,
        where: l.organization_id == ^org_id,
        preload: [:actor],
        order_by: [desc: l.inserted_at],
        limit: ^limit,
        offset: ^offset
    )
  end

  # =============================================================================
  # Stats & Counts
  # =============================================================================

  @doc """
  Counts the number of organizations a user owns.
  """
  def count_owned_organizations(user_id) do
    Repo.one(
      from m in OrganizationMember,
        where: m.user_id == ^user_id and m.role == "owner",
        select: count(m.id)
    )
  end

  @doc """
  Counts the number of members in an organization.
  """
  def count_organization_members(org_id) do
    Repo.one(
      from m in OrganizationMember,
        where: m.organization_id == ^org_id and m.status == "active",
        select: count(m.id)
    )
  end

  @doc """
  Counts the number of teams in an organization.
  """
  def count_organization_teams(org_id) do
    Repo.one(
      from t in Team,
        where: t.organization_id == ^org_id,
        select: count(t.id)
    )
  end
end
