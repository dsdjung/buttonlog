defmodule ButtonLogWeb.AboutLiveTest do
  use ButtonLogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /about" do
    test "renders about page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/about")

      assert html =~ "ButtonLog"
      assert html =~ "Version Information"
      assert html =~ "Web Version"
    end

    test "displays legal links", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/about")

      assert html =~ "Terms of Service"
      assert html =~ "Privacy Policy"
    end

    test "displays contact information", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/about")

      assert html =~ "Contact"
      assert html =~ "Email Support"
    end

    test "has back to home link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/about")

      assert html =~ "Back to Home"
    end
  end
end
