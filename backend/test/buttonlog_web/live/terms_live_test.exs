defmodule ButtonLogWeb.TermsLiveTest do
  use ButtonLogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /terms" do
    test "renders terms of service page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/terms")

      assert html =~ "Terms of Service"
      assert html =~ "Last updated"
    end

    test "displays all required sections", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/terms")

      assert html =~ "Acceptance of Terms"
      assert html =~ "Description of Service"
      assert html =~ "User Accounts"
      assert html =~ "User Content"
      assert html =~ "Acceptable Use"
      assert html =~ "Subscription and Payments"
      assert html =~ "Termination"
      assert html =~ "Disclaimer of Warranties"
      assert html =~ "Limitation of Liability"
      assert html =~ "Changes to Terms"
      assert html =~ "Contact Us"
    end

    test "has contact information", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/terms")

      assert html =~ "support@buttonlog.app"
    end

    test "has back to home link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/terms")

      assert html =~ "Back to Home"
    end
  end
end
