defmodule ButtonLogWeb.AccountLiveTest do
  use ButtonLogWeb.ConnCase

  import Phoenix.LiveViewTest

  @endpoint ButtonLogWeb.Endpoint

  setup %{conn: conn} do
    user = insert_user()
    {:ok, conn: conn, user: user}
  end

  describe "mount" do
    test "renders account page when logged in", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/account")

      assert html =~ "Account" or html =~ user.email
    end

    test "shows user information", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/account")

      assert html =~ user.display_name or html =~ user.username
    end

    test "redirects to login when not authenticated", %{conn: conn} do
      result = live(conn, ~p"/account")

      # Should redirect or show login requirement
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/auth/login" or path =~ "/login"

        {:ok, _view, html} ->
          # If it doesn't redirect, it should show login requirement
          assert html =~ "log in" or html =~ "Login"
      end
    end
  end

  describe "logout event" do
    test "logs out user and redirects", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/account")

      # Click logout using event name directly
      render_click(view, "logout")

      # Should redirect to login page
      assert_redirect(view, ~p"/auth/login")
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
    |> init_test_session(%{})
    |> put_session(:user_id, user.id)
  end
end
