defmodule ButtonLogWeb.HealthControllerTest do
  use ButtonLogWeb.ConnCase

  describe "GET /health" do
    test "returns healthy status when database is connected", %{conn: conn} do
      conn = get(conn, "/health")

      assert %{
               "status" => "healthy",
               "timestamp" => _,
               "version" => _,
               "checks" => %{"database" => "ok"}
             } = json_response(conn, 200)
    end

    test "returns proper content type", %{conn: conn} do
      conn = get(conn, "/health")

      assert get_resp_header(conn, "content-type") |> hd() =~ "application/json"
    end
  end
end
