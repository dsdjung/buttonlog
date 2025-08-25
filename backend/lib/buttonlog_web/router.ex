defmodule ButtonLogWeb.Router do
  use ButtonLogWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ButtonLogWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug ButtonLogWeb.Plugs.AuthPlug
  end

    scope "/", ButtonLogWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/buttons", ButtonLive.Index, :index
    live "/buttons/:id", ButtonLive.Show, :show
    live "/buttons/:button_id/notifications", ButtonNotificationsLive, :index
    live "/notifications", NotificationsLive, :index
    live "/test", TestLive, :index
    live "/friends", FriendsLive, :index
    live "/friends/:id", FriendLive.Show, :show
    live "/account", AccountLive, :index
    live "/diary", DiaryLive, :index

    # Debug route to test basic connectivity
    get "/debug", PageController, :debug

    # OAuth test route
    get "/oauth-test", PageController, :oauth_test
  end

  scope "/auth", ButtonLogWeb do
    pipe_through :browser

    get "/login", AuthController, :login_page
    post "/login", AuthController, :login
    get "/register", AuthController, :register_page
    post "/register", AuthController, :register
    delete "/logout", AuthController, :logout

    # OAuth routes
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/:provider", AuthController, :delete
  end

  scope "/api", ButtonLogWeb do
    pipe_through [:api, :auth]

    # Button endpoints
    get "/buttons", API.ButtonController, :index
    post "/buttons", API.ButtonController, :create
    get "/buttons/:id", API.ButtonController, :show
    put "/buttons/:id", API.ButtonController, :update
    delete "/buttons/:id", API.ButtonController, :delete
    post "/buttons/:id/click", API.ButtonController, :click

    # User endpoints
    get "/users/profile", API.UserController, :profile
    put "/users/profile", API.UserController, :update_profile
    get "/users/:id/public-profile", API.UserController, :public_profile

    # Social endpoints
    get "/friends", API.SocialController, :friends
    post "/friends/request", API.SocialController, :send_friend_request
    put "/friends/:id/accept", API.SocialController, :accept_friend_request
    delete "/friends/:id", API.SocialController, :remove_friend
    get "/friends/:friend_id/permissions", API.SocialController, :get_permissions
    put "/friends/:friend_id/permissions", API.SocialController, :update_permissions

    # Notification endpoints
    get "/notifications", API.NotificationController, :index
    put "/notifications/:id/read", API.NotificationController, :mark_read
    delete "/notifications/:id", API.ButtonController, :delete
  end

  scope "/api", ButtonLogWeb do
    pipe_through :api

    # Public endpoints (no auth required)
    post "/auth/register", API.AuthController, :register
    post "/auth/login", API.AuthController, :login
    post "/auth/refresh", API.AuthController, :refresh
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:buttonlog, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ButtonLogWeb.Telemetry
    end
  end

end
