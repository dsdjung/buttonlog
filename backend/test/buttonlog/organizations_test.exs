defmodule ButtonLog.OrganizationsTest do
  use ButtonLog.DataCase, async: true

  alias ButtonLog.Organizations

  describe "create_organization/2" do
    setup do
      user = insert_user(%{email: "owner@test.com", username: "owner", display_name: "Owner"})
      %{user: user}
    end

    test "creates an organization with valid attributes", %{user: user} do
      attrs = %{name: "Acme Inc", description: "A test company", billing_email: "billing@acme.com"}

      {:ok, org} = Organizations.create_organization(attrs, user.id)

      assert org.name == "Acme Inc"
      assert org.description == "A test company"
      assert org.billing_email == "billing@acme.com"
      assert org.slug == "acme-inc"
    end

    test "adds owner as a member with owner role", %{user: user} do
      attrs = %{name: "Test Org"}

      {:ok, org} = Organizations.create_organization(attrs, user.id)

      assert Organizations.member_of_organization?(org.id, user.id)
      assert Organizations.get_user_role(org.id, user.id) == "owner"
    end

    test "fails with invalid attributes", %{user: user} do
      attrs = %{name: ""}

      {:error, _changeset} = Organizations.create_organization(attrs, user.id)
    end
  end

  describe "list_user_organizations/1" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:ok, org1} = Organizations.create_organization(%{name: "Org 1"}, owner.id)
      {:ok, org2} = Organizations.create_organization(%{name: "Org 2"}, owner.id)
      {:ok, _member} = Organizations.add_member(org1.id, member.id, "member", owner.id, owner.id)

      %{owner: owner, member: member, other: other, org1: org1, org2: org2}
    end

    test "returns organizations user owns", %{owner: owner, org1: org1, org2: org2} do
      orgs = Organizations.list_user_organizations(owner.id)
      org_ids = Enum.map(orgs, & &1.id)

      assert org1.id in org_ids
      assert org2.id in org_ids
    end

    test "returns organizations user is member of", %{member: member, org1: org1} do
      orgs = Organizations.list_user_organizations(member.id)
      org_ids = Enum.map(orgs, & &1.id)

      assert org1.id in org_ids
    end

    test "does not return organizations user is not part of", %{other: other, org1: org1, org2: org2} do
      orgs = Organizations.list_user_organizations(other.id)
      org_ids = Enum.map(orgs, & &1.id)

      refute org1.id in org_ids
      refute org2.id in org_ids
    end
  end

  describe "get_organization_for_user/2" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)
      {:ok, _} = Organizations.add_member(org.id, member.id, "member", owner.id, owner.id)

      %{owner: owner, member: member, other: other, org: org}
    end

    test "returns organization for owner", %{owner: owner, org: org} do
      result = Organizations.get_organization_for_user(org.id, owner.id)
      assert result.id == org.id
    end

    test "returns organization for member", %{member: member, org: org} do
      result = Organizations.get_organization_for_user(org.id, member.id)
      assert result.id == org.id
    end

    test "returns nil for non-member", %{other: other, org: org} do
      result = Organizations.get_organization_for_user(org.id, other.id)
      assert result == nil
    end
  end

  describe "delete_organization/2" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      admin = insert_user(%{email: "admin@test.com", username: "admin"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)
      {:ok, _} = Organizations.add_member(org.id, admin.id, "admin", owner.id, owner.id)

      %{owner: owner, admin: admin, org: org}
    end

    test "owner can delete organization", %{owner: owner, org: org} do
      {:ok, _} = Organizations.delete_organization(org, owner.id)
      assert Organizations.get_organization(org.id) == nil
    end

    test "admin cannot delete organization", %{admin: admin, org: org} do
      {:error, :unauthorized} = Organizations.delete_organization(org, admin.id)
      assert Organizations.get_organization(org.id) != nil
    end
  end

  describe "organization members" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})
      admin = insert_user(%{email: "admin@test.com", username: "admin"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)
      {:ok, _} = Organizations.add_member(org.id, member.id, "member", owner.id, owner.id)
      {:ok, _} = Organizations.add_member(org.id, admin.id, "admin", owner.id, owner.id)

      %{owner: owner, member: member, admin: admin, org: org}
    end

    test "get_user_role returns correct role", %{owner: owner, member: member, admin: admin, org: org} do
      assert Organizations.get_user_role(org.id, owner.id) == "owner"
      assert Organizations.get_user_role(org.id, admin.id) == "admin"
      assert Organizations.get_user_role(org.id, member.id) == "member"
    end

    test "can_manage_organization? returns true for owner and admin", %{owner: owner, admin: admin, org: org} do
      assert Organizations.can_manage_organization?(org.id, owner.id) == true
      assert Organizations.can_manage_organization?(org.id, admin.id) == true
    end

    test "can_manage_organization? returns false for regular member", %{member: member, org: org} do
      assert Organizations.can_manage_organization?(org.id, member.id) == false
    end

    test "owner can update member role", %{owner: owner, member: member, org: org} do
      {:ok, _} = Organizations.update_member_role(org.id, member.id, "admin", owner.id)
      assert Organizations.get_user_role(org.id, member.id) == "admin"
    end

    test "cannot change owner's role", %{owner: owner, org: org} do
      {:error, :cannot_change_owner} = Organizations.update_member_role(org.id, owner.id, "admin", owner.id)
    end

    test "owner can remove member", %{owner: owner, member: member, org: org} do
      {:ok, _} = Organizations.remove_member(org.id, member.id, owner.id)
      refute Organizations.member_of_organization?(org.id, member.id)
    end

    test "cannot remove owner", %{owner: owner, admin: admin, org: org} do
      {:error, :cannot_remove_owner} = Organizations.remove_member(org.id, owner.id, admin.id)
    end

    test "member can remove themselves", %{member: member, org: org} do
      {:ok, _} = Organizations.remove_member(org.id, member.id, member.id)
      refute Organizations.member_of_organization?(org.id, member.id)
    end
  end

  describe "organization invitations" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      invitee = insert_user(%{email: "invitee@test.com", username: "invitee"})
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)

      %{owner: owner, invitee: invitee, other: other, org: org}
    end

    test "owner can create invitation", %{owner: owner, invitee: invitee, org: org} do
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, invitee.id, "member")

      assert invitation.organization_id == org.id
      assert invitation.inviter_id == owner.id
      assert invitation.invitee_id == invitee.id
      assert invitation.role == "member"
      assert invitation.token != nil
    end

    test "cannot invite existing member", %{owner: owner, org: org} do
      {:error, :already_member} = Organizations.create_invitation(org.id, owner.id, owner.id, "member")
    end

    test "invitee can accept invitation", %{owner: owner, invitee: invitee, org: org} do
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, invitee.id, "member")

      {:ok, member} = Organizations.accept_invitation(invitation.id, invitee.id)

      assert member.user_id == invitee.id
      assert member.organization_id == org.id
      assert Organizations.member_of_organization?(org.id, invitee.id)
    end

    test "wrong user cannot accept invitation", %{owner: owner, invitee: invitee, other: other, org: org} do
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, invitee.id, "member")

      {:error, :wrong_user} = Organizations.accept_invitation(invitation.id, other.id)
    end

    test "invitee can decline invitation", %{owner: owner, invitee: invitee, org: org} do
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, invitee.id, "member")

      {:ok, declined} = Organizations.decline_invitation(invitation.id, invitee.id)

      assert declined.declined_at != nil
      refute Organizations.member_of_organization?(org.id, invitee.id)
    end

    test "owner can cancel invitation", %{owner: owner, invitee: invitee, org: org} do
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, invitee.id, "member")

      {:ok, _} = Organizations.cancel_invitation(invitation.id, owner.id)

      invitations = Organizations.list_organization_invitations(org.id)
      invitation_ids = Enum.map(invitations, & &1.id)
      refute invitation.id in invitation_ids
    end
  end

  describe "organization teams" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)
      {:ok, team} = ButtonLog.Teams.create_team(%{name: "Test Team"}, owner.id)

      %{owner: owner, org: org, team: team}
    end

    test "can add team to organization", %{owner: owner, org: org, team: team} do
      {:ok, updated_team} = Organizations.add_team_to_organization(team.id, org.id, owner.id)

      assert updated_team.organization_id == org.id
    end

    test "can remove team from organization", %{owner: owner, org: org, team: team} do
      {:ok, _} = Organizations.add_team_to_organization(team.id, org.id, owner.id)
      {:ok, updated_team} = Organizations.remove_team_from_organization(team.id, org.id, owner.id)

      assert updated_team.organization_id == nil
    end

    test "cannot add team that's already in an organization", %{owner: owner, org: org, team: team} do
      {:ok, _} = Organizations.add_team_to_organization(team.id, org.id, owner.id)
      {:ok, other_org} = Organizations.create_organization(%{name: "Other Org"}, owner.id)

      {:error, :team_already_in_organization} = Organizations.add_team_to_organization(team.id, other_org.id, owner.id)
    end

    test "list_organization_teams returns teams", %{owner: owner, org: org, team: team} do
      {:ok, _} = Organizations.add_team_to_organization(team.id, org.id, owner.id)

      teams = Organizations.list_organization_teams(org.id)
      team_ids = Enum.map(teams, & &1.id)

      assert team.id in team_ids
    end
  end

  describe "transfer_ownership/3" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      admin = insert_user(%{email: "admin@test.com", username: "admin"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)
      {:ok, _} = Organizations.add_member(org.id, admin.id, "admin", owner.id, owner.id)

      %{owner: owner, admin: admin, org: org}
    end

    test "owner can transfer ownership to member", %{owner: owner, admin: admin, org: org} do
      {:ok, _updated_org} = Organizations.transfer_ownership(org.id, admin.id, owner.id)

      assert Organizations.get_user_role(org.id, admin.id) == "owner"
      assert Organizations.get_user_role(org.id, owner.id) == "admin"
    end

    test "non-owner cannot transfer ownership", %{admin: admin, org: org} do
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:error, :unauthorized} = Organizations.transfer_ownership(org.id, other.id, admin.id)
    end

    test "cannot transfer to non-member", %{owner: owner, org: org} do
      non_member = insert_user(%{email: "nonmember@test.com", username: "nonmember"})

      {:error, :not_a_member} = Organizations.transfer_ownership(org.id, non_member.id, owner.id)
    end
  end

  describe "billing admin role" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      billing_admin = insert_user(%{email: "billing@test.com", username: "billing"})
      member = insert_user(%{email: "member@test.com", username: "member"})

      {:ok, org} = Organizations.create_organization(%{name: "Test Org"}, owner.id)
      {:ok, _} = Organizations.add_member(org.id, billing_admin.id, "billing_admin", owner.id, owner.id)
      {:ok, _} = Organizations.add_member(org.id, member.id, "member", owner.id, owner.id)

      %{owner: owner, billing_admin: billing_admin, member: member, org: org}
    end

    test "billing_admin can manage billing", %{billing_admin: billing_admin, org: org} do
      assert Organizations.can_manage_billing?(org.id, billing_admin.id) == true
    end

    test "owner can manage billing", %{owner: owner, org: org} do
      assert Organizations.can_manage_billing?(org.id, owner.id) == true
    end

    test "regular member cannot manage billing", %{member: member, org: org} do
      assert Organizations.can_manage_billing?(org.id, member.id) == false
    end

    test "billing_admin cannot manage organization", %{billing_admin: billing_admin, org: org} do
      assert Organizations.can_manage_organization?(org.id, billing_admin.id) == false
    end
  end

  describe "stats" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})

      {:ok, org1} = Organizations.create_organization(%{name: "Org 1"}, owner.id)
      {:ok, org2} = Organizations.create_organization(%{name: "Org 2"}, owner.id)
      {:ok, _} = Organizations.add_member(org1.id, member.id, "member", owner.id, owner.id)

      {:ok, team} = ButtonLog.Teams.create_team(%{name: "Test Team"}, owner.id)
      {:ok, _} = Organizations.add_team_to_organization(team.id, org1.id, owner.id)

      %{owner: owner, org1: org1, org2: org2}
    end

    test "count_owned_organizations returns correct count", %{owner: owner} do
      assert Organizations.count_owned_organizations(owner.id) == 2
    end

    test "count_organization_members returns correct count", %{org1: org1, org2: org2} do
      # org1 has owner + member = 2
      assert Organizations.count_organization_members(org1.id) == 2
      # org2 has only owner = 1
      assert Organizations.count_organization_members(org2.id) == 1
    end

    test "count_organization_teams returns correct count", %{org1: org1, org2: org2} do
      assert Organizations.count_organization_teams(org1.id) == 1
      assert Organizations.count_organization_teams(org2.id) == 0
    end
  end

  # Helper functions
  defp insert_user(attrs) do
    default_attrs = %{
      email: "test#{System.unique_integer()}@test.com",
      username: "testuser#{System.unique_integer()}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123")
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash])
    |> ButtonLog.Repo.insert!()
  end
end
