defmodule ButtonLogWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :buttonlog


  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: [
      store: :cookie,
      key: "_buttonlog_key",
      signing_salt: "OpMfVMm+KAaQxZE/1O3FoKPn9i9QCXRLuiK3/JmD5dd1KOfqQfw1+7cPXJksvAk4"
    ]]],
    longpoll: [connect_info: [session: [
      store: :cookie,
      key: "_buttonlog_key",
      signing_salt: "OpMfVMm+KAaQxZE/1O3FoKPn9i9QCXRLuiK3/JmD5dd1KOfqQfw1+7cPXJksvAk4"
    ]]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :buttonlog,
    gzip: false,
          only: ButtonLogWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

    plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]


  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length_limit: 100_000_000

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, [
    store: :cookie,
    key: "_buttonlog_key",
    signing_salt: "OpMfVMm+KAaQxZE/1O3FoKPn9i9QCXRLuiK3/JmD5dd1KOfqQfw1+7cPXJksvAk4"
  ]
  plug ButtonLogWeb.Router
end
