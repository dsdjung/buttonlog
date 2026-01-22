defmodule ButtonLog.TeamsTest do
  use ButtonLog.DataCase, async: true

  alias ButtonLog.{Teams, Buttons}
  alias ButtonLog.Teams

  describe "create_team/2" do
    setup do
      user = insert_user(%{email: "owner@test.com", username: "owner", display_name: "Owner"})
      %{user: user}
    end

    test "creates a team with valid attributes", %{user: user} do
      attrs = %{name: "My Team", description: "A test team", color: "#FF0000"}

      {:ok, team} = Teams.create_team(attrs, user.id)

      assert team.name == "My Team"
      assert team.description == "A test team"
      assert team.color == "#FF0000"
      assert team.owner_id == user.id
    end

    test "adds owner as a member with owner role", %{user: user} do
      attrs = %{name: "My Team"}

      {:ok, team} = Teams.create_team(attrs, user.id)

      assert Teams.member_of_team?(team.id, user.id)
      assert Teams.get_user_role(team.id, user.id) == "owner"
    end

    test "fails with invalid attributes", %{user: user} do
      attrs = %{name: ""}  # Name is required

      {:error, _changeset} = Teams.create_team(attrs, user.id)
    end
  end

  describe "list_user_teams/1" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:ok, team1} = Teams.create_team(%{name: "Team 1"}, owner.id)
      {:ok, team2} = Teams.create_team(%{name: "Team 2"}, owner.id)
      {:ok, _member} = Teams.add_member(team1.id, member.id, "member", owner.id)

      %{owner: owner, member: member, other: other, team1: team1, team2: team2}
    end

    test "returns teams user owns", %{owner: owner, team1: team1, team2: team2} do
      teams = Teams.list_user_teams(owner.id)
      team_ids = Enum.map(teams, & &1.id)

      assert team1.id in team_ids
      assert team2.id in team_ids
    end

    test "returns teams user is member of", %{member: member, team1: team1} do
      teams = Teams.list_user_teams(member.id)
      team_ids = Enum.map(teams, & &1.id)

      assert team1.id in team_ids
    end

    test "does not return teams user is not part of", %{other: other, team1: team1, team2: team2} do
      teams = Teams.list_user_teams(other.id)
      team_ids = Enum.map(teams, & &1.id)

      refute team1.id in team_ids
      refute team2.id in team_ids
    end
  end

  describe "get_team_for_user/2" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:ok, team} = Teams.create_team(%{name: "Test Team"}, owner.id)
      {:ok, _} = Teams.add_member(team.id, member.id, "member", owner.id)

      %{owner: owner, member: member, other: other, team: team}
    end

    test "returns team for owner", %{owner: owner, team: team} do
      result = Teams.get_team_for_user(team.id, owner.id)
      assert result.id == team.id
    end

    test "returns team for member", %{member: member, team: team} do
      result = Teams.get_team_for_user(team.id, member.id)
      assert result.id == team.id
    end

    test "returns nil for non-member", %{other: other, team: team} do
      result = Teams.get_team_for_user(team.id, other.id)
      assert result == nil
    end
  end

  describe "delete_team/2" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      admin = insert_user(%{email: "admin@test.com", username: "admin"})

      {:ok, team} = Teams.create_team(%{name: "Test Team"}, owner.id)
      {:ok, _} = Teams.add_member(team.id, admin.id, "admin", owner.id)

      %{owner: owner, admin: admin, team: team}
    end

    test "owner can delete team", %{owner: owner, team: team} do
      {:ok, _} = Teams.delete_team(team, owner.id)
      assert Teams.get_team(team.id) == nil
    end

    test "admin cannot delete team", %{admin: admin, team: team} do
      {:error, :unauthorized} = Teams.delete_team(team, admin.id)
      assert Teams.get_team(team.id) != nil
    end
  end

  describe "team members" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})
      admin = insert_user(%{email: "admin@test.com", username: "admin"})

      {:ok, team} = Teams.create_team(%{name: "Test Team"}, owner.id)
      {:ok, _} = Teams.add_member(team.id, member.id, "member", owner.id)
      {:ok, _} = Teams.add_member(team.id, admin.id, "admin", owner.id)

      %{owner: owner, member: member, admin: admin, team: team}
    end

    test "get_user_role returns correct role", %{owner: owner, member: member, admin: admin, team: team} do
      assert Teams.get_user_role(team.id, owner.id) == "owner"
      assert Teams.get_user_role(team.id, admin.id) == "admin"
      assert Teams.get_user_role(team.id, member.id) == "member"
    end

    test "can_manage_team? returns true for owner and admin", %{owner: owner, admin: admin, team: team} do
      assert Teams.can_manage_team?(team.id, owner.id) == true
      assert Teams.can_manage_team?(team.id, admin.id) == true
    end

    test "can_manage_team? returns false for regular member", %{member: member, team: team} do
      assert Teams.can_manage_team?(team.id, member.id) == false
    end

    test "owner can update member role", %{owner: owner, member: member, team: team} do
      {:ok, _} = Teams.update_member_role(team.id, member.id, "admin", owner.id)
      assert Teams.get_user_role(team.id, member.id) == "admin"
    end

    test "cannot change owner's role", %{owner: owner, team: team} do
      # Owner can't even change their own role (since they're the owner)
      {:error, :cannot_change_owner} = Teams.update_member_role(team.id, owner.id, "admin", owner.id)
    end

    test "owner can remove member", %{owner: owner, member: member, team: team} do
      {:ok, _} = Teams.remove_member(team.id, member.id, owner.id)
      refute Teams.member_of_team?(team.id, member.id)
    end

    test "cannot remove owner", %{owner: owner, admin: admin, team: team} do
      {:error, :cannot_remove_owner} = Teams.remove_member(team.id, owner.id, admin.id)
    end

    test "member can remove themselves", %{member: member, team: team} do
      {:ok, _} = Teams.remove_member(team.id, member.id, member.id)
      refute Teams.member_of_team?(team.id, member.id)
    end
  end

  describe "team buttons" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})

      {:ok, team} = Teams.create_team(%{name: "Test Team"}, owner.id)
      {:ok, _} = Teams.add_member(team.id, member.id, "member", owner.id)

      {:ok, button} = Buttons.create_button(%{
        "name" => "Test Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#FF0000"
      }, owner.id)

      %{owner: owner, member: member, team: team, button: button}
    end

    test "owner can add their button to team", %{owner: owner, team: team, button: button} do
      {:ok, team_button} = Teams.add_button_to_team(team.id, button.id, "click", owner.id)

      assert team_button.team_id == team.id
      assert team_button.button_id == button.id
      assert team_button.permission == "click"
    end

    test "member cannot add button they don't own", %{member: member, team: team, button: button} do
      {:error, :unauthorized} = Teams.add_button_to_team(team.id, button.id, "click", member.id)
    end

    test "team member can click button via team", %{owner: owner, member: member, team: team, button: button} do
      {:ok, _} = Teams.add_button_to_team(team.id, button.id, "click", owner.id)

      assert Teams.can_click_via_team?(button.id, member.id) == true
    end

    test "view permission does not allow clicking", %{owner: owner, member: member, team: team, button: button} do
      {:ok, _} = Teams.add_button_to_team(team.id, button.id, "view", owner.id)

      assert Teams.can_click_via_team?(button.id, member.id) == false
    end

    test "owner can remove button from team", %{owner: owner, team: team, button: button} do
      {:ok, _} = Teams.add_button_to_team(team.id, button.id, "click", owner.id)
      {:ok, _} = Teams.remove_button_from_team(team.id, button.id, owner.id)

      assert Teams.can_click_via_team?(button.id, owner.id) == false
    end
  end

  describe "team invitations" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      invitee = insert_user(%{email: "invitee@test.com", username: "invitee"})
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:ok, team} = Teams.create_team(%{name: "Test Team"}, owner.id)

      %{owner: owner, invitee: invitee, other: other, team: team}
    end

    test "owner can create invitation", %{owner: owner, invitee: invitee, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      assert invitation.team_id == team.id
      assert invitation.inviter_id == owner.id
      assert invitation.invitee_id == invitee.id
      assert invitation.role == "member"
      assert invitation.token != nil
    end

    test "cannot invite existing member", %{owner: owner, team: team} do
      {:error, :already_member} = Teams.create_invitation(team.id, owner.id, owner.id, "member")
    end

    test "invitee can accept invitation", %{owner: owner, invitee: invitee, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      {:ok, member} = Teams.accept_invitation(invitation.id, invitee.id)

      assert member.user_id == invitee.id
      assert member.team_id == team.id
      assert Teams.member_of_team?(team.id, invitee.id)
    end

    test "wrong user cannot accept invitation", %{owner: owner, invitee: invitee, other: other, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      {:error, :wrong_user} = Teams.accept_invitation(invitation.id, other.id)
    end

    test "invitee can decline invitation", %{owner: owner, invitee: invitee, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      {:ok, declined} = Teams.decline_invitation(invitation.id, invitee.id)

      assert declined.declined_at != nil
      refute Teams.member_of_team?(team.id, invitee.id)
    end

    test "owner can cancel invitation", %{owner: owner, invitee: invitee, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      {:ok, _} = Teams.cancel_invitation(invitation.id, owner.id)

      # Invitation should no longer be in pending list
      invitations = Teams.list_team_invitations(team.id)
      invitation_ids = Enum.map(invitations, & &1.id)
      refute invitation.id in invitation_ids
    end

    test "list_team_invitations returns pending invitations", %{owner: owner, invitee: invitee, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      invitations = Teams.list_team_invitations(team.id)

      assert length(invitations) == 1
      assert hd(invitations).id == invitation.id
    end

    test "list_user_invitations returns pending invitations for user", %{owner: owner, invitee: invitee, team: team} do
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, invitee.id, "member")

      invitations = Teams.list_user_invitations(invitee.id)

      assert length(invitations) == 1
      assert hd(invitations).id == invitation.id
    end
  end

  describe "transfer_ownership/3" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      admin = insert_user(%{email: "admin@test.com", username: "admin"})

      {:ok, team} = Teams.create_team(%{name: "Test Team"}, owner.id)
      {:ok, _} = Teams.add_member(team.id, admin.id, "admin", owner.id)

      %{owner: owner, admin: admin, team: team}
    end

    test "owner can transfer ownership to member", %{owner: owner, admin: admin, team: team} do
      {:ok, updated_team} = Teams.transfer_ownership(team.id, admin.id, owner.id)

      assert updated_team.owner_id == admin.id
      assert Teams.get_user_role(team.id, admin.id) == "owner"
      assert Teams.get_user_role(team.id, owner.id) == "admin"
    end

    test "non-owner cannot transfer ownership", %{owner: _owner, admin: admin, team: team} do
      other = insert_user(%{email: "other@test.com", username: "other"})

      {:error, :unauthorized} = Teams.transfer_ownership(team.id, other.id, admin.id)
    end

    test "cannot transfer to non-member", %{owner: owner, team: team} do
      non_member = insert_user(%{email: "nonmember@test.com", username: "nonmember"})

      {:error, :not_a_member} = Teams.transfer_ownership(team.id, non_member.id, owner.id)
    end
  end

  describe "stats" do
    setup do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      member = insert_user(%{email: "member@test.com", username: "member"})

      {:ok, team1} = Teams.create_team(%{name: "Team 1"}, owner.id)
      {:ok, team2} = Teams.create_team(%{name: "Team 2"}, owner.id)
      {:ok, _} = Teams.add_member(team1.id, member.id, "member", owner.id)

      {:ok, button} = Buttons.create_button(%{
        "name" => "Test Button",
        "type" => "instant",
        "icon" => "star",
        "color" => "#FF0000"
      }, owner.id)

      {:ok, _} = Teams.add_button_to_team(team1.id, button.id, "click", owner.id)

      %{owner: owner, team1: team1, team2: team2}
    end

    test "count_owned_teams returns correct count", %{owner: owner} do
      assert Teams.count_owned_teams(owner.id) == 2
    end

    test "count_team_members returns correct count", %{team1: team1, team2: team2} do
      # team1 has owner + member = 2
      assert Teams.count_team_members(team1.id) == 2
      # team2 has only owner = 1
      assert Teams.count_team_members(team2.id) == 1
    end

    test "count_team_buttons returns correct count", %{team1: team1, team2: team2} do
      assert Teams.count_team_buttons(team1.id) == 1
      assert Teams.count_team_buttons(team2.id) == 0
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
