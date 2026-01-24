defmodule ButtonLogWeb.API.OrganizationControllerTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLog.Organizations
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
    test "lists user's organizations", %{conn: conn, user: user} do
      # Create an organization for the user
      {:ok, org} = Organizations.create_organization(%{name: "Test Org", slug: "test-org"}, user.id)

      conn = get(conn, ~p"/api/organizations")

      assert %{"success" => true, "data" => organizations} = json_response(conn, 200)
      assert length(organizations) >= 1
      assert Enum.any?(organizations, fn o -> o["id"] == org.id end)
    end

    test "returns empty list when user has no organizations", %{conn: conn} do
      conn = get(conn, ~p"/api/organizations")

      assert %{"success" => true, "data" => []} = json_response(conn, 200)
    end
  end

  describe "show/2" do
    test "returns organization details for member", %{conn: conn, user: user} do
      {:ok, org} = Organizations.create_organization(%{name: "Test Org", slug: "test-org"}, user.id)

      conn = get(conn, ~p"/api/organizations/#{org.id}")

      assert %{"success" => true, "data" => org_data} = json_response(conn, 200)
      assert org_data["id"] == org.id
      assert org_data["name"] == "Test Org"
    end

    test "returns 404 for non-existent organization", %{conn: conn} do
      conn = get(conn, ~p"/api/organizations/#{Ecto.UUID.generate()}")

      assert %{"success" => false, "error" => %{"message" => "Organization not found"}} =
               json_response(conn, 404)
    end
  end

  describe "create/2" do
    test "creates organization with valid params", %{conn: conn} do
      params = %{
        "name" => "New Organization",
        "slug" => "new-org",
        "description" => "A new organization"
      }

      conn = post(conn, ~p"/api/organizations", params)

      assert %{"success" => true, "data" => org_data} = json_response(conn, 201)
      assert org_data["name"] == "New Organization"
      assert org_data["slug"] == "new-org"
    end

    test "returns error with invalid params", %{conn: conn} do
      params = %{"name" => ""}

      conn = post(conn, ~p"/api/organizations", params)

      assert %{"success" => false, "error" => _} = json_response(conn, 422)
    end
  end

  describe "update/2" do
    test "updates organization when user is owner", %{conn: conn, user: user} do
      {:ok, org} = Organizations.create_organization(%{name: "Test Org", slug: "test-org"}, user.id)

      params = %{"name" => "Updated Org Name"}

      conn = put(conn, ~p"/api/organizations/#{org.id}", params)

      assert %{"success" => true, "data" => org_data} = json_response(conn, 200)
      assert org_data["name"] == "Updated Org Name"
    end

    test "returns 403 when user is not authorized", %{conn: conn} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, org} = Organizations.create_organization(%{name: "Other Org", slug: "other-org"}, other_user.id)

      params = %{"name" => "Hacked Name"}

      conn = put(conn, ~p"/api/organizations/#{org.id}", params)

      assert json_response(conn, 404) or json_response(conn, 403)
    end
  end

  describe "delete/2" do
    test "deletes organization when user is owner", %{conn: conn, user: user} do
      {:ok, org} = Organizations.create_organization(%{name: "To Delete", slug: "to-delete"}, user.id)

      conn = delete(conn, ~p"/api/organizations/#{org.id}")

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns 403 when user is not owner", %{conn: conn} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, org} = Organizations.create_organization(%{name: "Other Org", slug: "other-org"}, other_user.id)

      conn = delete(conn, ~p"/api/organizations/#{org.id}")

      # Should be forbidden or not found (depending on implementation)
      assert json_response(conn, 403) or json_response(conn, 404)
    end
  end

  describe "list_members/2" do
    test "lists organization members when user is member", %{conn: conn, user: user} do
      {:ok, org} = Organizations.create_organization(%{name: "Test Org", slug: "test-org"}, user.id)

      conn = get(conn, ~p"/api/organizations/#{org.id}/members")

      assert %{"success" => true, "data" => members} = json_response(conn, 200)
      assert length(members) >= 1
    end

    test "returns 403 when user is not member", %{conn: conn} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, org} = Organizations.create_organization(%{name: "Other Org", slug: "other-org"}, other_user.id)

      conn = get(conn, ~p"/api/organizations/#{org.id}/members")

      assert %{"success" => false, "error" => %{"message" => msg}} = json_response(conn, 403)
      assert msg =~ "not a member"
    end
  end

  describe "create_invitation/2" do
    test "creates invitation when user can manage", %{conn: conn, user: user} do
      {:ok, org} = Organizations.create_organization(%{name: "Test Org", slug: "test-org"}, user.id)
      invitee = insert_user(%{email: "invitee@test.com", username: "invitee"})

      params = %{"user_id" => invitee.id, "role" => "member"}

      conn = post(conn, ~p"/api/organizations/#{org.id}/invitations", params)

      assert %{"success" => true, "data" => _invitation} = json_response(conn, 201)
    end
  end

  describe "my_invitations/2" do
    test "lists user's pending invitations", %{conn: conn, user: user} do
      # Create an org as another user
      other_user = insert_user(%{email: "org_owner@test.com", username: "org_owner"})
      {:ok, org} = Organizations.create_organization(%{name: "Other Org", slug: "other-org"}, other_user.id)

      # Invite the test user
      Organizations.create_invitation(org.id, other_user.id, user.id, "member")

      conn = get(conn, ~p"/api/organizations/invitations")

      assert %{"success" => true, "data" => invitations} = json_response(conn, 200)
      assert length(invitations) >= 1
    end
  end

  describe "accept_invitation/2" do
    test "accepts invitation for current user", %{conn: conn, user: user} do
      other_user = insert_user(%{email: "org_owner@test.com", username: "org_owner"})
      {:ok, org} = Organizations.create_organization(%{name: "Other Org", slug: "other-org"}, other_user.id)

      {:ok, invitation} = Organizations.create_invitation(org.id, other_user.id, user.id, "member")

      conn = post(conn, ~p"/api/organizations/invitations/#{invitation.id}/accept")

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns error for invitation to wrong user", %{conn: conn} do
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      {:ok, org} = Organizations.create_organization(%{name: "Org", slug: "org"}, owner.id)

      other_invitee = insert_user(%{email: "other@test.com", username: "other"})
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, other_invitee.id, "member")

      conn = post(conn, ~p"/api/organizations/invitations/#{invitation.id}/accept")

      assert %{"success" => false, "error" => %{"message" => msg}} = json_response(conn, 403)
      assert msg =~ "another user"
    end
  end

  describe "decline_invitation/2" do
    test "declines invitation for current user", %{conn: conn, user: user} do
      other_user = insert_user(%{email: "org_owner@test.com", username: "org_owner"})
      {:ok, org} = Organizations.create_organization(%{name: "Other Org", slug: "other-org"}, other_user.id)

      {:ok, invitation} = Organizations.create_invitation(org.id, other_user.id, user.id, "member")

      conn = post(conn, ~p"/api/organizations/invitations/#{invitation.id}/decline")

      assert %{"success" => true} = json_response(conn, 200)
    end
  end

  describe "leave/2" do
    test "member can leave organization", %{conn: conn, user: user} do
      # Create org as another user
      owner = insert_user(%{email: "owner@test.com", username: "owner"})
      {:ok, org} = Organizations.create_organization(%{name: "Org", slug: "org"}, owner.id)

      # Invite and accept as test user
      {:ok, invitation} = Organizations.create_invitation(org.id, owner.id, user.id, "member")
      Organizations.accept_invitation(invitation.id, user.id)

      conn = delete(conn, ~p"/api/organizations/#{org.id}/leave")

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "owner cannot leave without transferring ownership", %{conn: conn, user: user} do
      {:ok, org} = Organizations.create_organization(%{name: "My Org", slug: "my-org"}, user.id)

      conn = delete(conn, ~p"/api/organizations/#{org.id}/leave")

      assert %{"success" => false, "error" => %{"message" => msg}} = json_response(conn, 422)
      assert msg =~ "Owner cannot leave" or msg =~ "transfer"
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
