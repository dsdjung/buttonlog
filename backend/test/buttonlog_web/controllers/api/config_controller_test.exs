defmodule ButtonLogWeb.API.ConfigControllerTest do
  use ButtonLogWeb.ConnCase

  describe "GET /api/config" do
    test "returns app configuration without authentication", %{conn: conn} do
      conn = get(conn, "/api/config")

      assert %{
               "min_supported_version" => %{"ios" => _, "android" => _},
               "latest_version" => %{"ios" => _, "android" => _},
               "features" => features,
               "maintenance_mode" => false,
               "api_version" => "1",
               "server_time" => _
             } = json_response(conn, 200)

      # Verify feature flags are present
      assert is_boolean(features["push_notifications"])
      assert is_boolean(features["friend_alerts"])
      assert is_boolean(features["subscriptions"])
    end

    test "returns valid version strings", %{conn: conn} do
      conn = get(conn, "/api/config")

      response = json_response(conn, 200)

      # Verify version format (semver)
      assert response["min_supported_version"]["ios"] =~ ~r/^\d+\.\d+\.\d+$/
      assert response["min_supported_version"]["android"] =~ ~r/^\d+\.\d+\.\d+$/
      assert response["latest_version"]["ios"] =~ ~r/^\d+\.\d+\.\d+$/
      assert response["latest_version"]["android"] =~ ~r/^\d+\.\d+\.\d+$/
    end

    test "returns proper content type", %{conn: conn} do
      conn = get(conn, "/api/config")

      assert get_resp_header(conn, "content-type") |> hd() =~ "application/json"
    end

    test "returns ISO8601 server time", %{conn: conn} do
      conn = get(conn, "/api/config")

      response = json_response(conn, 200)

      # Verify server_time is valid ISO8601
      assert {:ok, _, _} = DateTime.from_iso8601(response["server_time"])
    end
  end
end
