defmodule ButtonLogWeb.PricingLiveTest do
  use ButtonLogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /pricing (unauthenticated)" do
    test "renders pricing page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/pricing")

      assert html =~ "Pricing"
    end

    test "displays available plans", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/pricing")

      # Should show free plan at minimum
      assert html =~ "Free" or html =~ "free"
    end
  end

  describe "GET /pricing (authenticated)" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "renders pricing page for logged in user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, "/pricing")

      assert html =~ "Pricing"
    end

    test "displays billing options", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, "/pricing")

      # Should show billing cycle options
      assert html =~ "Monthly" or html =~ "monthly"
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
