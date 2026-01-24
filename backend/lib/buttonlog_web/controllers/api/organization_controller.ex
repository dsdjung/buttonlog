defmodule ButtonLogWeb.API.OrganizationController do
  use ButtonLogWeb, :controller

  alias ButtonLog.Organizations
  alias ButtonLog.Accounts

  # =============================================================================
  # Organizations
  # =============================================================================

  @doc """
  GET /api/organizations - List user's organizations
  """
  def index(conn, _params) do
    user_id = conn.assigns.current_user.id
    organizations = Organizations.list_user_organizations(user_id)

    json(conn, %{success: true, data: Enum.map(organizations, &format_organization/1)})
  end

  @doc """
  GET /api/organizations/:id - Get organization details
  """
  def show(conn, %{"id" => org_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.get_organization_for_user(org_id, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Organization not found"}})

      org ->
        role = Organizations.get_user_role(org_id, user_id)
        json(conn, %{success: true, data: format_organization_detail(org, role)})
    end
  end

  @doc """
  POST /api/organizations - Create a new organization
  """
  def create(conn, params) do
    user_id = conn.assigns.current_user.id

    attrs = %{
      name: params["name"],
      slug: params["slug"],
      description: params["description"],
      logo_url: params["logo_url"],
      website: params["website"],
      billing_email: params["billing_email"]
    }

    case Organizations.create_organization(attrs, user_id) do
      {:ok, org} ->
        conn
        |> put_status(:created)
        |> json(%{success: true, data: format_organization(org)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  PUT /api/organizations/:id - Update an organization
  """
  def update(conn, %{"id" => org_id} = params) do
    user_id = conn.assigns.current_user.id
    org = Organizations.get_organization(org_id)

    if org do
      attrs = %{
        name: params["name"],
        description: params["description"],
        logo_url: params["logo_url"],
        website: params["website"],
        billing_email: params["billing_email"],
        allow_personal_teams: params["allow_personal_teams"],
        default_team_role: params["default_team_role"]
      } |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

      case Organizations.update_organization(org, attrs, user_id) do
        {:ok, updated_org} ->
          json(conn, %{success: true, data: format_organization(updated_org)})

        {:error, :unauthorized} ->
          conn
          |> put_status(:forbidden)
          |> json(%{success: false, error: %{message: "You don't have permission to update this organization"}})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{success: false, error: format_changeset_errors(changeset)})
      end
    else
      conn
      |> put_status(:not_found)
      |> json(%{success: false, error: %{message: "Organization not found"}})
    end
  end

  @doc """
  DELETE /api/organizations/:id - Delete an organization
  """
  def delete(conn, %{"id" => org_id}) do
    user_id = conn.assigns.current_user.id
    org = Organizations.get_organization(org_id)

    case Organizations.delete_organization(org, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Organization deleted"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "Only the organization owner can delete it"}})

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Organization not found"}})
    end
  end

  # =============================================================================
  # Organization Members
  # =============================================================================

  @doc """
  GET /api/organizations/:org_id/members - List organization members
  """
  def list_members(conn, %{"org_id" => org_id}) do
    user_id = conn.assigns.current_user.id

    if Organizations.member_of_organization?(org_id, user_id) do
      members = Organizations.list_organization_members(org_id)
      json(conn, %{success: true, data: Enum.map(members, &format_member/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You are not a member of this organization"}})
    end
  end

  @doc """
  PUT /api/organizations/:org_id/members/:user_id/role - Update member role
  """
  def update_member_role(conn, %{"org_id" => org_id, "user_id" => member_user_id, "role" => role}) do
    acting_user_id = conn.assigns.current_user.id

    case Organizations.update_member_role(org_id, member_user_id, role, acting_user_id) do
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
        |> json(%{success: false, error: %{message: "Cannot change owner's role"}})
    end
  end

  @doc """
  DELETE /api/organizations/:org_id/members/:user_id - Remove a member
  """
  def remove_member(conn, %{"org_id" => org_id, "user_id" => member_user_id}) do
    acting_user_id = conn.assigns.current_user.id

    case Organizations.remove_member(org_id, member_user_id, acting_user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Member removed"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to remove members"}})

      {:error, :cannot_remove_owner} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Cannot remove organization owner"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Member not found"}})
    end
  end

  @doc """
  DELETE /api/organizations/:org_id/leave - Leave an organization
  """
  def leave(conn, %{"org_id" => org_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.remove_member(org_id, user_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "You have left the organization"})

      {:error, :cannot_remove_owner} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Owner cannot leave. Transfer ownership first."}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "You are not a member of this organization"}})
    end
  end

  @doc """
  POST /api/organizations/:org_id/transfer-ownership - Transfer organization ownership
  """
  def transfer_ownership(conn, %{"org_id" => org_id, "new_owner_id" => new_owner_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.transfer_ownership(org_id, new_owner_id, user_id) do
      {:ok, org} ->
        json(conn, %{success: true, data: format_organization(org)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "Only the owner can transfer ownership"}})

      {:error, :not_a_member} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "New owner must be an organization member"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Organization not found"}})
    end
  end

  # =============================================================================
  # Organization Teams
  # =============================================================================

  @doc """
  GET /api/organizations/:org_id/teams - List organization teams
  """
  def list_teams(conn, %{"org_id" => org_id}) do
    user_id = conn.assigns.current_user.id

    if Organizations.member_of_organization?(org_id, user_id) do
      teams = Organizations.list_organization_teams(org_id)
      json(conn, %{success: true, data: Enum.map(teams, &format_team/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You are not a member of this organization"}})
    end
  end

  @doc """
  POST /api/organizations/:org_id/teams/:team_id - Add a team to organization
  """
  def add_team(conn, %{"org_id" => org_id, "team_id" => team_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.add_team_to_organization(team_id, org_id, user_id) do
      {:ok, team} ->
        json(conn, %{success: true, data: format_team(team)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to add teams"}})

      {:error, :team_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Team not found"}})

      {:error, :team_already_in_organization} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Team is already in an organization"}})
    end
  end

  @doc """
  DELETE /api/organizations/:org_id/teams/:team_id - Remove a team from organization
  """
  def remove_team(conn, %{"org_id" => org_id, "team_id" => team_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.remove_team_from_organization(team_id, org_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Team removed from organization"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to remove teams"}})

      {:error, :team_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Team not found"}})

      {:error, :team_not_in_organization} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Team is not in this organization"}})
    end
  end

  # =============================================================================
  # Invitations
  # =============================================================================

  @doc """
  GET /api/organizations/:org_id/invitations - List organization invitations
  """
  def list_invitations(conn, %{"org_id" => org_id}) do
    user_id = conn.assigns.current_user.id

    if Organizations.can_manage_organization?(org_id, user_id) do
      invitations = Organizations.list_organization_invitations(org_id)
      json(conn, %{success: true, data: Enum.map(invitations, &format_invitation/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You don't have permission to view invitations"}})
    end
  end

  @doc """
  GET /api/organizations/invitations - List user's pending invitations
  """
  def my_invitations(conn, _params) do
    user_id = conn.assigns.current_user.id
    invitations = Organizations.list_user_organization_invitations(user_id)
    json(conn, %{success: true, data: Enum.map(invitations, &format_invitation/1)})
  end

  @doc """
  POST /api/organizations/:org_id/invitations - Create invitation
  """
  def create_invitation(conn, %{"org_id" => org_id} = params) do
    user_id = conn.assigns.current_user.id
    role = Map.get(params, "role", "member")

    result = cond do
      params["user_id"] ->
        Organizations.create_invitation(org_id, user_id, params["user_id"], role)

      params["username"] ->
        case Accounts.get_user_by_username(params["username"]) do
          nil -> {:error, :user_not_found}
          invitee -> Organizations.create_invitation(org_id, user_id, invitee.id, role)
        end

      params["email"] ->
        Organizations.create_email_invitation(org_id, user_id, params["email"], role)

      true ->
        {:error, :missing_invitee}
    end

    case result do
      {:ok, invitation} ->
        invitation = ButtonLog.Repo.preload(invitation, [:organization, :inviter, :invitee])

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
        |> json(%{success: false, error: %{message: "User is already a member"}})

      {:error, :user_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "User not found"}})

      {:error, :missing_invitee} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "Must provide user_id, username, or email"}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  POST /api/organizations/invitations/:id/accept - Accept invitation
  """
  def accept_invitation(conn, %{"id" => invitation_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.accept_invitation(invitation_id, user_id) do
      {:ok, member} ->
        json(conn, %{success: true, data: format_member(member)})

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
        |> json(%{success: false, error: %{message: "This invitation is for another user"}})

      {:error, :no_seats_available} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: %{message: "No seats available in this organization"}})
    end
  end

  @doc """
  POST /api/organizations/invitations/:id/decline - Decline invitation
  """
  def decline_invitation(conn, %{"id" => invitation_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.decline_invitation(invitation_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Invitation declined"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Invitation not found"}})

      {:error, :wrong_user} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "This invitation is for another user"}})
    end
  end

  @doc """
  DELETE /api/organizations/:org_id/invitations/:id - Cancel invitation
  """
  def cancel_invitation(conn, %{"id" => invitation_id}) do
    user_id = conn.assigns.current_user.id

    case Organizations.cancel_invitation(invitation_id, user_id) do
      {:ok, _} ->
        json(conn, %{success: true, message: "Invitation cancelled"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: %{message: "You don't have permission to cancel invitations"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: %{message: "Invitation not found"}})
    end
  end

  # =============================================================================
  # Subscription
  # =============================================================================

  @doc """
  GET /api/organizations/:org_id/subscription - Get subscription details
  """
  def show_subscription(conn, %{"org_id" => org_id}) do
    user_id = conn.assigns.current_user.id

    if Organizations.member_of_organization?(org_id, user_id) do
      case Organizations.get_organization_subscription(org_id) do
        nil ->
          json(conn, %{success: true, data: nil})

        subscription ->
          json(conn, %{success: true, data: format_subscription(subscription)})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You are not a member of this organization"}})
    end
  end

  # =============================================================================
  # Audit Logs
  # =============================================================================

  @doc """
  GET /api/organizations/:org_id/audit-logs - Get audit logs
  """
  def audit_logs(conn, %{"org_id" => org_id} = params) do
    user_id = conn.assigns.current_user.id

    if Organizations.can_manage_organization?(org_id, user_id) do
      opts = [
        limit: String.to_integer(params["limit"] || "50"),
        offset: String.to_integer(params["offset"] || "0")
      ]

      logs = Organizations.list_audit_logs(org_id, opts)
      json(conn, %{success: true, data: Enum.map(logs, &format_audit_log/1)})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{success: false, error: %{message: "You don't have permission to view audit logs"}})
    end
  end

  # =============================================================================
  # Formatters
  # =============================================================================

  defp format_organization(org) do
    %{
      id: org.id,
      name: org.name,
      slug: org.slug,
      description: org.description,
      logo_url: org.logo_url,
      website: org.website,
      status: org.status,
      subscription: if(org.subscription, do: format_subscription_summary(org.subscription), else: nil),
      inserted_at: org.inserted_at,
      updated_at: org.updated_at
    }
  end

  defp format_organization_detail(org, role) do
    org
    |> format_organization()
    |> Map.merge(%{
      my_role: role,
      can_manage: ButtonLog.Organizations.OrganizationMember.is_admin?(role),
      can_manage_billing: ButtonLog.Organizations.OrganizationMember.can_manage_billing?(role),
      domain: org.domain,
      sso_enabled: org.sso_enabled,
      require_sso: org.require_sso,
      allow_personal_teams: org.allow_personal_teams,
      billing_email: org.billing_email,
      member_count: length(org.members),
      team_count: length(org.teams),
      members: Enum.map(org.members, &format_member/1),
      teams: Enum.map(org.teams, &format_team_summary/1)
    })
  end

  defp format_member(member) do
    %{
      id: member.id,
      user_id: member.user_id,
      role: member.role,
      status: member.status,
      joined_at: member.joined_at,
      user: if Ecto.assoc_loaded?(member.user) && member.user do
        %{
          id: member.user.id,
          username: member.user.username,
          display_name: member.user.display_name,
          avatar: member.user.avatar
        }
      else
        nil
      end,
      invited_by: if Ecto.assoc_loaded?(member.invited_by) && member.invited_by do
        %{
          id: member.invited_by.id,
          username: member.invited_by.username,
          display_name: member.invited_by.display_name
        }
      else
        nil
      end
    }
  end

  defp format_team(team) do
    %{
      id: team.id,
      name: team.name,
      description: team.description,
      icon: team.icon,
      color: team.color,
      organization_id: team.organization_id,
      owner: if team.owner do
        %{
          id: team.owner.id,
          username: team.owner.username,
          display_name: team.owner.display_name
        }
      else
        nil
      end,
      member_count: if(team.members, do: length(team.members), else: 0)
    }
  end

  defp format_team_summary(team) do
    %{
      id: team.id,
      name: team.name,
      color: team.color
    }
  end

  defp format_invitation(invitation) do
    %{
      id: invitation.id,
      role: invitation.role,
      email: invitation.email,
      expires_at: invitation.expires_at,
      organization: if Ecto.assoc_loaded?(invitation.organization) && invitation.organization do
        %{
          id: invitation.organization.id,
          name: invitation.organization.name,
          slug: invitation.organization.slug
        }
      else
        nil
      end,
      inviter: if Ecto.assoc_loaded?(invitation.inviter) && invitation.inviter do
        %{
          id: invitation.inviter.id,
          username: invitation.inviter.username,
          display_name: invitation.inviter.display_name
        }
      else
        nil
      end,
      invitee: if Ecto.assoc_loaded?(invitation.invitee) && invitation.invitee do
        %{
          id: invitation.invitee.id,
          username: invitation.invitee.username,
          display_name: invitation.invitee.display_name
        }
      else
        nil
      end,
      inserted_at: invitation.inserted_at
    }
  end

  defp format_subscription(subscription) do
    %{
      id: subscription.id,
      status: subscription.status,
      billing_cycle: subscription.billing_cycle,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      trial_ends_at: subscription.trial_ends_at,
      seats_purchased: subscription.seats_purchased,
      seats_used: subscription.seats_used,
      seats_available: ButtonLog.Organizations.OrganizationSubscription.available_seats(subscription),
      price_per_seat: subscription.price_per_seat,
      cancel_at_period_end: subscription.cancel_at_period_end,
      plan: if subscription.plan do
        %{
          id: subscription.plan.id,
          name: subscription.plan.name,
          tier: subscription.plan.tier
        }
      else
        nil
      end
    }
  end

  defp format_subscription_summary(subscription) do
    %{
      status: subscription.status,
      seats_purchased: subscription.seats_purchased,
      seats_used: subscription.seats_used
    }
  end

  defp format_audit_log(log) do
    %{
      id: log.id,
      action: log.action,
      resource_type: log.resource_type,
      resource_id: log.resource_id,
      metadata: log.metadata,
      actor: if log.actor do
        %{
          id: log.actor.id,
          username: log.actor.username,
          display_name: log.actor.display_name
        }
      else
        nil
      end,
      inserted_at: log.inserted_at
    }
  end

  defp format_changeset_errors(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    %{
      message: "Validation failed",
      details: errors
    }
  end
end
