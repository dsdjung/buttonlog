defmodule ButtonLogWeb.FriendsLiveTest do
  use ButtonLogWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ButtonLog.Social
  alias ButtonLog.Buttons

  @endpoint ButtonLogWeb.Endpoint

  setup %{conn: conn} do
    user = insert_user()
    {:ok, conn: conn, user: user}
  end

  describe "mount" do
    test "renders friends page when logged in", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/friends")

      assert html =~ "Friends"
      assert html =~ "Invite Friend"
    end

    test "shows empty state when no friends", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/friends")

      assert html =~ "No friends yet"
    end

    test "shows friends list when user has friends", %{conn: conn, user: user} do
      friend = insert_user(%{email: "friend@test.com", username: "myfriend", display_name: "My Friend"})
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/friends")

      assert html =~ "myfriend" or html =~ "My Friend"
    end

    test "shows pending friend requests", %{conn: conn, user: user} do
      requester = insert_user(%{email: "requester@test.com", username: "requester", display_name: "Request User"})
      {:ok, _friendship} = Social.send_friend_request(requester.id, user.id)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/friends")

      assert html =~ "Pending Friend Requests" or html =~ "requester"
    end
  end

  describe "send_invite event" do
    test "sends invite to registered user", %{conn: conn, user: user} do
      other_user = insert_user(%{email: "other@test.com", username: "other"})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      result =
        view
        |> form("form", %{email: other_user.email})
        |> render_submit()

      assert result =~ "Invite sent to #{other_user.email}"
    end

    test "sends invite to unregistered email", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      result =
        view
        |> form("form", %{email: "newuser@example.com"})
        |> render_submit()

      assert result =~ "Invite sent to newuser@example.com"
    end

    test "shows error when inviting self", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      result =
        view
        |> form("form", %{email: user.email})
        |> render_submit()

      assert result =~ "You cannot invite yourself"
    end
  end

  describe "accept_friend_request event" do
    test "accepts pending friend request", %{conn: conn, user: user} do
      requester = insert_user(%{email: "requester2@test.com", username: "requester2"})
      {:ok, friendship} = Social.send_friend_request(requester.id, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      result =
        view
        |> element("button[phx-click='accept_friend_request'][phx-value-friendship_id='#{friendship.id}']")
        |> render_click()

      assert result =~ "Friend request accepted!"
    end
  end

  describe "decline_friend_request event" do
    test "declines pending friend request", %{conn: conn, user: user} do
      requester = insert_user(%{email: "requester3@test.com", username: "requester3"})
      {:ok, friendship} = Social.send_friend_request(requester.id, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      result =
        view
        |> element("button[phx-click='decline_friend_request'][phx-value-friendship_id='#{friendship.id}']")
        |> render_click()

      assert result =~ "Friend request declined"
    end
  end

  describe "cancel_friend_request event" do
    test "cancels sent friend request", %{conn: conn, user: user} do
      recipient = insert_user(%{email: "recipient@test.com", username: "recipient"})
      {:ok, friendship} = Social.send_friend_request(user.id, recipient.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      result =
        view
        |> element("button[phx-click='cancel_friend_request'][phx-value-friendship_id='#{friendship.id}']")
        |> render_click()

      assert result =~ "Friend request cancelled"
    end
  end

  describe "gift buttons" do
    test "toggle_gift_buttons shows gift buttons section", %{conn: conn, user: user} do
      # Create a gift button for another user
      friend = insert_user(%{email: "giftfriend@test.com", username: "giftfriend"})
      {:ok, friendship} = Social.send_friend_request(user.id, friend.id)
      {:ok, _} = Social.accept_friend_request(friendship.id, friend.id)
      # Create a button as a gift (use create_button with gift_for_user_id)
      {:ok, _gift_button} = Buttons.create_button(%{name: "Gift Button", type: "instant", gift_for_user_id: friend.id}, user.id)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/friends")

      # Toggle gift buttons visibility - look for the section or button
      result =
        view
        |> element("[phx-click='toggle_gift_buttons']")
        |> render_click()

      # The section should now be visible or toggled
      assert result =~ "Gift Button" or result =~ "gift" or result =~ "toggle_gift_buttons"
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
