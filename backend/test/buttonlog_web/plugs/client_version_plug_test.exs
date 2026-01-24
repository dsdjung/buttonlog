defmodule ButtonLogWeb.Plugs.ClientVersionPlugTest do
  use ButtonLogWeb.ConnCase

  alias ButtonLogWeb.Plugs.ClientVersionPlug

  describe "call/2" do
    test "extracts all client headers when present", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-app-version", "1.2.3")
        |> put_req_header("x-platform", "ios")
        |> put_req_header("x-device-id", "device-123")
        |> ClientVersionPlug.call([])

      assert conn.assigns.client_version == "1.2.3"
      assert conn.assigns.client_platform == "ios"
      assert conn.assigns.client_device_id == "device-123"
    end

    test "handles missing headers gracefully", %{conn: conn} do
      conn = ClientVersionPlug.call(conn, [])

      assert conn.assigns.client_version == nil
      assert conn.assigns.client_platform == nil
      assert conn.assigns.client_device_id == nil
    end

    test "extracts partial headers", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-app-version", "2.0.0")
        |> ClientVersionPlug.call([])

      assert conn.assigns.client_version == "2.0.0"
      assert conn.assigns.client_platform == nil
      assert conn.assigns.client_device_id == nil
    end

    test "handles android platform", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-app-version", "1.0.0")
        |> put_req_header("x-platform", "android")
        |> ClientVersionPlug.call([])

      assert conn.assigns.client_version == "1.0.0"
      assert conn.assigns.client_platform == "android"
    end
  end

  describe "integration with API pipeline" do
    test "client version headers are available in API endpoints", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-app-version", "1.5.0")
        |> put_req_header("x-platform", "ios")
        |> get("/api/config")

      # The plug runs before the controller, so assigns should be available
      assert conn.assigns.client_version == "1.5.0"
      assert conn.assigns.client_platform == "ios"

      # Request should still succeed
      assert json_response(conn, 200)
    end
  end
end
