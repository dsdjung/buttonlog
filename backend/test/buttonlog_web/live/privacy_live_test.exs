defmodule ButtonLogWeb.PrivacyLiveTest do
  use ButtonLogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /privacy" do
    test "renders privacy policy page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/privacy")

      assert html =~ "Privacy Policy"
      assert html =~ "Last updated"
    end

    test "displays all required sections", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/privacy")

      assert html =~ "Introduction"
      assert html =~ "Information We Collect"
      assert html =~ "How We Use Your Information"
      assert html =~ "Information Sharing"
      assert html =~ "Data Security"
      assert html =~ "Data Retention"
      assert html =~ "Your Rights"
      assert html =~ "Cookies and Tracking"
      assert html =~ "Changes to This Policy"
      assert html =~ "Contact Us"
    end

    test "explains data collection", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/privacy")

      assert html =~ "Account information"
      assert html =~ "Button data and click history"
    end

    test "explains user rights", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/privacy")

      assert html =~ "Access your personal information"
      assert html =~ "Delete your account and data"
      assert html =~ "Export your data"
    end

    test "has contact information", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/privacy")

      assert html =~ "privacy@buttonlog.com"
    end

    test "has back to home link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/privacy")

      assert html =~ "Back to Home"
    end
  end
end
