defmodule ButtonLogWeb.PageControllerTest do
  use ButtonLogWeb.ConnCase

  test "GET / redirects to /buttons", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn, 302) == "/buttons"
  end
end
