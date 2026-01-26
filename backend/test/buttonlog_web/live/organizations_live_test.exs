defmodule ButtonLogWeb.OrganizationsLiveTest do
  use ButtonLogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /organizations (unauthenticated)" do
    test "redirects to login", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, "/organizations")

      assert path =~ "/auth/login"
    end
  end

  describe "GET /organizations (authenticated)" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "renders organizations page", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, "/organizations")

      assert html =~ "Organization" or html =~ "organization"
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

  defp log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
  end
end
