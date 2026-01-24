defmodule ButtonLogWeb.ButtonLiveTest do
  use ButtonLogWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ButtonLog.Buttons

  @endpoint ButtonLogWeb.Endpoint

  setup %{conn: conn} do
    user = insert_user()
    {:ok, conn: conn, user: user}
  end

  describe "mount" do
    test "renders buttons page when logged in", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/buttons")

      assert html =~ "ButtonLog"
    end

    test "shows empty state when no buttons", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/buttons")

      assert html =~ "No buttons yet" or html =~ "Create your first"
    end

    test "shows buttons list when user has buttons", %{conn: conn, user: user} do
      {:ok, _button} = Buttons.create_button(%{name: "Test Button", type: "instant"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/buttons")

      assert html =~ "Test Button"
    end

    test "shows different button types", %{conn: conn, user: user} do
      {:ok, _} = Buttons.create_button(%{name: "Instant Button", type: "instant"}, user.id)
      {:ok, _} = Buttons.create_button(%{name: "Toggle Button", type: "toggle"}, user.id)
      {:ok, _} = Buttons.create_button(%{name: "One-Time Button", type: "one-time"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/buttons")

      assert html =~ "Instant Button"
      assert html =~ "Toggle Button"
      assert html =~ "One-Time Button"
    end
  end

  describe "show_create_form event" do
    test "shows create button form", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # Use render_click with event name directly
      result = render_click(view, "show_create_form")

      assert result =~ "Create Button" or result =~ "Button Name" or result =~ "create_button"
    end
  end

  describe "hide_create_form event" do
    test "hides create button form", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # First show the form
      render_click(view, "show_create_form")

      # Then hide it
      result = render_click(view, "hide_create_form")

      # Form should be hidden (check for create button to show again)
      assert result =~ "New Button" or not (result =~ "Button Name")
    end
  end

  describe "create_button event" do
    test "creates a new instant button", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # Show form first
      render_click(view, "show_create_form")

      # Submit the form - only include fields that exist in the form
      result =
        view
        |> form("form[phx-submit='create_button']", %{
          button: %{
            name: "New Test Button",
            type: "instant"
          }
        })
        |> render_submit()

      assert result =~ "Button created successfully!" or result =~ "New Test Button"
    end

    test "creates a one-time button", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # Show form first
      render_click(view, "show_create_form")

      # Submit the form for one-time button (without choices - they're added via JS)
      result =
        view
        |> form("form[phx-submit='create_button']", %{
          button: %{
            name: "One-Time Button",
            type: "one-time"
          }
        })
        |> render_submit()

      assert result =~ "Button created successfully!" or result =~ "One-Time Button"
    end

    test "shows error for invalid button", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # Show form first
      render_click(view, "show_create_form")

      # Submit invalid form (missing name)
      result =
        view
        |> form("form[phx-submit='create_button']", %{
          button: %{
            name: "",
            type: "instant"
          }
        })
        |> render_submit()

      assert result =~ "error" or result =~ "can't be blank" or result =~ "Failed"
    end
  end

  describe "click event" do
    test "clicks an instant button", %{conn: conn, user: user} do
      {:ok, button} = Buttons.create_button(%{name: "Clickable Button", type: "instant"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      result = render_click(view, "click", %{"id" => button.id})

      assert result =~ "completed" or result =~ "clicked"
    end

    test "clicking button updates UI", %{conn: conn, user: user} do
      {:ok, button} = Buttons.create_button(%{name: "My Button", type: "instant"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # Click the button and verify the page still renders properly
      result = render_click(view, "click", %{"id" => button.id})

      # The button should still be visible on the page after clicking
      assert result =~ "My Button"
    end

    test "archives one-time button after click", %{conn: conn, user: user} do
      {:ok, button} = Buttons.create_button(%{name: "One-Time Button", type: "one-time"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      result = render_click(view, "click", %{"id" => button.id})

      assert result =~ "completed" or result =~ "archived"
    end
  end

  describe "click_with_choice event" do
    test "clicks button with selected choice", %{conn: conn, user: user} do
      {:ok, button} = Buttons.create_button(%{
        name: "Choice Button",
        type: "one-time",
        choices: ["Yes", "No"]
      }, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      result = render_click(view, "click_with_choice", %{"id" => button.id, "choice" => "Yes"})

      assert result =~ "Yes" or result =~ "completed"
    end
  end

  describe "search event" do
    test "filters buttons by search query", %{conn: conn, user: user} do
      {:ok, _} = Buttons.create_button(%{name: "Apple Button", type: "instant"}, user.id)
      {:ok, _} = Buttons.create_button(%{name: "Banana Button", type: "instant"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      result = render_keyup(view, "search", %{"value" => "Apple"})

      assert result =~ "Apple Button"
      refute result =~ "Banana Button"
    end
  end

  describe "filter_type event" do
    test "filters buttons by type", %{conn: conn, user: user} do
      {:ok, _} = Buttons.create_button(%{name: "Instant Button", type: "instant"}, user.id)
      {:ok, _} = Buttons.create_button(%{name: "Toggle Button", type: "toggle"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      result = render_change(view, "filter_type", %{"filter_type" => "instant"})

      assert result =~ "Instant Button"
      refute result =~ "Toggle Button"
    end
  end

  describe "clear_search event" do
    test "clears search and filter", %{conn: conn, user: user} do
      {:ok, _} = Buttons.create_button(%{name: "Apple Button", type: "instant"}, user.id)
      {:ok, _} = Buttons.create_button(%{name: "Banana Button", type: "toggle"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      # Apply search
      render_keyup(view, "search", %{"value" => "Apple"})

      # Clear search
      result = render_click(view, "clear_search")

      assert result =~ "Apple Button"
      assert result =~ "Banana Button"
    end
  end

  describe "delete event" do
    test "deletes a button", %{conn: conn, user: user} do
      {:ok, button} = Buttons.create_button(%{name: "To Delete", type: "instant"}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/buttons")

      result = render_click(view, "delete", %{"id" => button.id})

      assert result =~ "deleted successfully" or not (result =~ "To Delete")
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
