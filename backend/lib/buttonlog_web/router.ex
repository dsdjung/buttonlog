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

  pipeline :admin do
    plug ButtonLogWeb.Plugs.AdminPlug
  end

  pipeline :require_authenticated_admin do
    plug :fetch_session
    plug ButtonLogWeb.Plugs.BrowserAuthPlug
    plug ButtonLogWeb.Plugs.AdminPlug
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
    live "/support", SupportLive, :index
    live "/support/:id", SupportLive, :show

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
    post "/buttons/gift", API.ButtonController, :create_for_friend
    get "/buttons/:id", API.ButtonController, :show
    put "/buttons/:id", API.ButtonController, :update
    delete "/buttons/:id", API.ButtonController, :delete
    post "/buttons/:id/click", API.ButtonController, :click
    get "/buttons/:id/history", API.ButtonController, :history
    get "/buttons/:id/sharing", API.ButtonController, :sharing
    put "/buttons/:id/sharing", API.ButtonController, :update_sharing

    # Button sharing/collaborator endpoints
    put "/buttons/:id/sharing-mode", API.ButtonController, :update_sharing_mode
    post "/buttons/:id/share-link", API.ButtonController, :generate_share_link
    delete "/buttons/:id/share-link", API.ButtonController, :revoke_share_link
    get "/buttons/:id/collaborators", API.ButtonController, :list_collaborators
    post "/buttons/:id/collaborators", API.ButtonController, :add_collaborator
    delete "/buttons/:id/collaborators/:user_id", API.ButtonController, :remove_collaborator
    post "/buttons/join/:token", API.ButtonController, :join_by_token

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
    get "/friends/:friend_id/buttons", API.SocialController, :friend_buttons
    get "/friends/:friend_id/activity", API.SocialController, :friend_activity

    # Notification endpoints
    get "/notifications", API.NotificationController, :index
    put "/notifications/:id/read", API.NotificationController, :mark_read
    delete "/notifications/:id", API.ButtonController, :delete

    # Device/Push notification endpoints
    post "/devices/register", API.MobileController, :register_device
    delete "/devices/unregister", API.MobileController, :unregister_device
    get "/devices", API.MobileController, :list_devices

    # Subscription endpoints
    get "/subscriptions", API.SubscriptionController, :index
    get "/subscriptions/current", API.SubscriptionController, :show
    post "/subscriptions", API.SubscriptionController, :create
    delete "/subscriptions", API.SubscriptionController, :cancel
    post "/subscriptions/pause", API.SubscriptionController, :pause
    post "/subscriptions/resume", API.SubscriptionController, :resume
    get "/subscriptions/stats", API.SubscriptionController, :stats
    post "/subscriptions/check-permission", API.SubscriptionController, :check_permission

    # Support ticket endpoints (user)
    get "/support/tickets", API.SupportController, :index
    post "/support/tickets", API.SupportController, :create
    get "/support/tickets/:id", API.SupportController, :show
    post "/support/tickets/:id/messages", API.SupportController, :add_message
  end

  # Admin API routes
  scope "/api/admin", ButtonLogWeb.API.Admin do
    pipe_through [:api, :auth, :admin]

    # Support ticket management (admin)
    get "/support/tickets", SupportController, :index
    get "/support/tickets/:id", SupportController, :show
    put "/support/tickets/:id", SupportController, :update
    post "/support/tickets/:id/messages", SupportController, :add_message
    get "/support/stats", SupportController, :stats
  end

  # Admin web panel
  scope "/admin", ButtonLogWeb do
    pipe_through [:browser, :require_authenticated_admin]

    live "/", AdminLive.Dashboard, :index
    live "/support", AdminLive.Support, :index
    live "/support/:id", AdminLive.Support, :show
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
