defmodule ButtonLogWeb.API.TeamControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Teams
  alias ButtonLog.Buttons
  alias ButtonLog.Auth.Token

  setup %{conn: conn} do
    user = insert_user()
    token = Token.create_token(user.id)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")

    {:ok, conn: conn, user: user}
  end

  describe "index/2" do
    test "lists user's teams", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)

      conn = get(conn, ~p"/api/teams")

      assert %{"success" => true, "data" => teams} = json_response(conn, 200)
      assert length(teams) >= 1
      assert Enum.any?(teams, fn t -> t["id"] == team.id end)
    end

    test "returns empty list when user has no teams", %{conn: conn} do
      conn = get(conn, ~p"/api/teams")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end
  end

  describe "show/2" do
    test "returns team details for member", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team", "description" => "A test team"}, user.id)

      conn = get(conn, ~p"/api/teams/#{team.id}")

      assert %{"success" => true, "data" => team_data} = json_response(conn, 200)
      assert team_data["id"] == team.id
      assert team_data["name"] == "Test Team"
    end

    test "returns 404 for non-existent team", %{conn: conn} do
      conn = get(conn, ~p"/api/teams/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => %{"message" => "Team not found"}} =
               json_response(conn, 404)
    end
  end

  describe "create/2" do
    test "creates team with valid params", %{conn: conn} do
      params = %{
        "name" => "New Team",
        "description" => "A new team",
        "color" => "#FF0000"
      }

      conn = post(conn, ~p"/api/teams", params)

      assert %{"success" => true, "data" => team_data} = json_response(conn, 201)
      assert team_data["name"] == "New Team"
    end

    test "returns error with invalid params", %{conn: conn} do
      params = %{"name" => ""}

      conn = post(conn, ~p"/api/teams", params)

      assert %{"success" => false, "error" => _} = json_response(conn, 422)
    end
  end

  describe "update/2" do
    test "updates team when user is owner", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)

      params = %{"name" => "Updated Team Name"}

      conn = put(conn, ~p"/api/teams/#{team.id}", params)

      assert %{"success" => true, "data" => team_data} = json_response(conn, 200)
      assert team_data["name"] == "Updated Team Name"
    end

    test "returns 403 when user is not authorized", %{conn: conn} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, team} = Teams.create_team(%{"name" => "Other Team"}, other_user.id)

      params = %{"name" => "Hacked Name"}

      conn = put(conn, ~p"/api/teams/#{team.id}", params)

      # Should be not found or forbidden
      assert conn.status in [403, 404]
    end
  end

  describe "delete/2" do
    test "deletes team when user is owner", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "To Delete"}, user.id)

      conn = delete(conn, ~p"/api/teams/#{team.id}")

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns 403 when user is not owner", %{conn: conn} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, team} = Teams.create_team(%{"name" => "Other Team"}, other_user.id)

      conn = delete(conn, ~p"/api/teams/#{team.id}")

      # Should be forbidden or not found
      assert conn.status in [403, 404]
    end
  end

  describe "list_members/2" do
    test "lists team members when user is member", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)

      conn = get(conn, ~p"/api/teams/#{team.id}/members")

      assert %{"success" => true, "data" => members} = json_response(conn, 200)
      assert length(members) >= 1
    end

    test "returns 403 when user is not member", %{conn: conn} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, team} = Teams.create_team(%{"name" => "Other Team"}, other_user.id)

      conn = get(conn, ~p"/api/teams/#{team.id}/members")

      assert %{"success" => false, "error" => %{"message" => msg}} = json_response(conn, 403)
      assert msg =~ "not a member"
    end
  end

  describe "list_buttons/2" do
    test "lists team buttons when user is member", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)

      conn = get(conn, ~p"/api/teams/#{team.id}/buttons")

      assert %{"success" => true, "data" => _buttons} = json_response(conn, 200)
    end
  end

  describe "add_button/2" do
    test "adds button to team", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)
      {:ok, button} = Buttons.create_button(%{name: "Test Button", type: "instant"}, user.id)

      params = %{"button_id" => button.id, "permission" => "click"}

      conn = post(conn, ~p"/api/teams/#{team.id}/buttons", params)

      assert %{"success" => true, "data" => _team_button} = json_response(conn, 201)
    end
  end

  describe "remove_button/2" do
    test "removes button from team", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)
      {:ok, button} = Buttons.create_button(%{name: "Test Button", type: "instant"}, user.id)

      {:ok, _team_button} = Teams.add_button_to_team(team.id, button.id, "click", user.id)

      conn = delete(conn, ~p"/api/teams/#{team.id}/buttons/#{button.id}")

      assert %{"success" => true} = json_response(conn, 200)
    end
  end

  describe "create_invitation/2" do
    test "creates invitation when user can manage", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "Test Team"}, user.id)
      invitee = insert_user(%{email: "invitee@test.com", username: "invitee"})

      params = %{"user_id" => invitee.id, "role" => "member"}

      conn = post(conn, ~p"/api/teams/#{team.id}/invitations", params)

      assert %{"success" => true, "data" => _invitation} = json_response(conn, 201)
    end
  end

  describe "my_invitations/2" do
    test "lists user's pending invitations", %{conn: conn, user: user} do
      # Create team as another user
      other_user = insert_user(%{email: "team_owner@test.com", username: "team_owner"})
      {:ok, team} = Teams.create_team(%{"name" => "Other Team"}, other_user.id)

      # Invite the test user
      Teams.create_invitation(team.id, other_user.id, user.id, "member")

      conn = get(conn, ~p"/api/teams/invitations")

      assert %{"success" => true, "data" => invitations} = json_response(conn, 200)
      assert length(invitations) >= 1
    end
  end

  describe "accept_invitation/2" do
    test "accepts invitation for current user", %{conn: conn, user: user} do
      other_user = insert_user(%{email: "team_owner@test.com", username: "team_owner"})
      {:ok, team} = Teams.create_team(%{"name" => "Other Team"}, other_user.id)

      {:ok, invitation} = Teams.create_invitation(team.id, other_user.id, user.id, "member")

      conn = post(conn, ~p"/api/teams/invitations/#{invitation.id}/accept")

      assert %{"success" => true} = json_response(conn, 200)
    end
  end

  describe "decline_invitation/2" do
    test "declines invitation for current user", %{conn: conn, user: user} do
      other_user = insert_user(%{email: "team_owner@test.com", username: "team_owner"})
      {:ok, team} = Teams.create_team(%{"name" => "Other Team"}, other_user.id)

      {:ok, invitation} = Teams.create_invitation(team.id, other_user.id, user.id, "member")

      conn = post(conn, ~p"/api/teams/invitations/#{invitation.id}/decline")

      assert %{"success" => true} = json_response(conn, 200)
    end
  end

  describe "leave/2" do
    test "member can leave team", %{conn: conn, user: user} do
      # Create team as another user
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      {:ok, team} = Teams.create_team(%{"name" => "Team"}, owner.id)

      # Invite and accept as test user
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, user.id, "member")
      Teams.accept_invitation(invitation.id, user.id)

      conn = post(conn, ~p"/api/teams/#{team.id}/leave")

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "owner cannot leave without transferring ownership", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "My Team"}, user.id)

      conn = post(conn, ~p"/api/teams/#{team.id}/leave")

      assert %{"success" => false, "error" => %{"message" => msg}} = json_response(conn, 422)
      assert msg =~ "Owner cannot leave" or msg =~ "transfer"
    end
  end

  describe "transfer_ownership/2" do
    test "owner can transfer ownership to another member", %{conn: conn, user: user} do
      {:ok, team} = Teams.create_team(%{"name" => "My Team"}, user.id)

      # Add another member
      new_owner = insert_user(%{email: "new_owner@test.com", username: "new_owner"})
      {:ok, invitation} = Teams.create_invitation(team.id, user.id, new_owner.id, "member")
      Teams.accept_invitation(invitation.id, new_owner.id)

      params = %{"new_owner_id" => new_owner.id}

      conn = post(conn, ~p"/api/teams/#{team.id}/transfer-ownership", params)

      assert %{"success" => true, "data" => _team_data} = json_response(conn, 200)
    end

    test "non-owner cannot transfer ownership", %{conn: conn, user: user} do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      {:ok, team} = Teams.create_team(%{"name" => "Team"}, owner.id)

      # Make test user a member (not owner)
      {:ok, invitation} = Teams.create_invitation(team.id, owner.id, user.id, "member")
      Teams.accept_invitation(invitation.id, user.id)

      third_user = insert_user(%{email: "third@test.com", username: "third"})
      params = %{"new_owner_id" => third_user.id}

      conn = post(conn, ~p"/api/teams/#{team.id}/transfer-ownership", params)

      assert %{"success" => false, "error" => %{"message" => msg}} = json_response(conn, 403)
      assert msg =~ "Only the owner"
    end
  end

  # Helper functions
  defp insert_user(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    default_attrs = %{
      email: "test#{unique_id}@test.com",
      username: "testuser#{unique_id}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123!")
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash])
    |> ButtonLog.Repo.insert!()
  end
end
