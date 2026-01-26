defmodule ButtonLogWeb.PageController do
  use ButtonLogWeb, :controller

  def home(conn, _params) do
    # Redirect to the buttons interface
    redirect(conn, to: ~p"/buttons")
  end

  def debug(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ButtonLog debug endpoint reached successfully!")
  end

  def oauth_test(conn, _params) do
    render(conn, :oauth_test)
  end
end
