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
    plug ButtonLogWeb.Plugs.ClientVersionPlug
  end

  # Strict rate limiting for auth endpoints (5 requests per minute per IP per endpoint)
  pipeline :auth_rate_limit do
    plug ButtonLogWeb.Plugs.RateLimitPlug, scale_ms: 60_000, limit: 5, bucket_prefix: "auth"
  end

  # Standard rate limiting for API endpoints (100 requests per minute per IP)
  pipeline :api_rate_limit do
    plug ButtonLogWeb.Plugs.RateLimitPlug, scale_ms: 60_000, limit: 100, bucket_prefix: "api"
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
    live "/teams", TeamsLive, :index
    live "/teams/:id", TeamLive.Show, :show
    live "/organizations", OrganizationsLive, :index
    live "/organizations/:id", OrganizationLive.Show, :show
    live "/account", AccountLive, :index
    live "/account/webhooks", WebhookSettingsLive, :index
    live "/diary", DiaryLive, :index
    live "/support", SupportLive, :index
    live "/support/:id", SupportLive, :show
    live "/pricing", PricingLive, :index
    live "/about", AboutLive, :index
    live "/terms", TermsLive, :index
    live "/privacy", PrivacyLive, :index

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
    pipe_through [:api, :api_rate_limit, :auth]

    # Diary endpoint
    get "/diary", API.ButtonController, :diary

    # Button endpoints
    get "/buttons", API.ButtonController, :index
    get "/buttons/created-gifts", API.ButtonController, :created_gift_buttons
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

    # Button alert preferences endpoints
    get "/buttons/:id/alerts", API.ButtonController, :alert_preferences
    post "/buttons/:id/alerts/:friend_id/toggle", API.ButtonController, :toggle_alert_preference
    put "/buttons/:id/alerts/:friend_id", API.ButtonController, :set_alert_preference
    post "/buttons/:id/alerts/select-all", API.ButtonController, :select_all_alerts
    post "/buttons/:id/alerts/deselect-all", API.ButtonController, :deselect_all_alerts

    # User endpoints
    get "/users/profile", API.UserController, :profile
    put "/users/profile", API.UserController, :update_profile
    post "/users/complete-onboarding", API.UserController, :complete_onboarding
    get "/users/:id/public-profile", API.UserController, :public_profile
    get "/users/notification-preferences", API.UserController, :notification_preferences
    put "/users/notification-preferences", API.UserController, :update_notification_preferences
    put "/users/password", API.PasswordController, :change_password

    # Data export endpoints
    get "/users/export", API.ExportController, :export
    get "/users/export/info", API.ExportController, :export_info

    # Social endpoints
    get "/friends", API.SocialController, :friends
    post "/friends/request", API.SocialController, :send_friend_request
    put "/friends/:id/accept", API.SocialController, :accept_friend_request
    delete "/friends/:id", API.SocialController, :remove_friend
    get "/friends/:friend_id/permissions", API.SocialController, :get_permissions
    put "/friends/:friend_id/permissions", API.SocialController, :update_permissions
    get "/friends/:friend_id/buttons", API.SocialController, :friend_buttons
    get "/friends/:friend_id/activity", API.SocialController, :friend_activity

    # Alert endpoints (in-app friend alerts - formerly "notifications")
    get "/alerts", API.AlertController, :index
    get "/alerts/unread", API.AlertController, :unread
    get "/alerts/unread/count", API.AlertController, :unread_count
    put "/alerts/:id/read", API.AlertController, :mark_read
    put "/alerts/read-all", API.AlertController, :mark_all_read
    get "/alerts/from/:friend_id", API.AlertController, :from_friend

    # Webhook notification endpoints (external integrations)
    get "/notifications/settings", API.WebhookNotificationController, :show_settings
    put "/notifications/settings", API.WebhookNotificationController, :update_settings
    get "/notifications/deliveries", API.WebhookNotificationController, :list_deliveries
    post "/notifications/deliveries/:id/retry", API.WebhookNotificationController, :retry_delivery
    post "/notifications/test", API.WebhookNotificationController, :test_webhook
    get "/buttons/:id/notifications", API.WebhookNotificationController, :show_button_settings
    put "/buttons/:id/notifications", API.WebhookNotificationController, :update_button_settings

    # Legacy notification endpoints (deprecated, use /alerts instead)
    get "/notifications", API.NotificationController, :index
    put "/notifications/:id/read", API.NotificationController, :mark_read

    # Device/Push notification endpoints
    post "/devices/register", API.MobileController, :register_device
    delete "/devices/unregister", API.MobileController, :unregister_device
    get "/devices", API.MobileController, :list_devices
    post "/devices/test-notification", API.MobileController, :send_test_notification

    # Subscription endpoints
    get "/subscriptions", API.SubscriptionController, :index
    get "/subscriptions/current", API.SubscriptionController, :show
    post "/subscriptions", API.SubscriptionController, :create
    delete "/subscriptions", API.SubscriptionController, :cancel
    post "/subscriptions/pause", API.SubscriptionController, :pause
    post "/subscriptions/resume", API.SubscriptionController, :resume
    get "/subscriptions/stats", API.SubscriptionController, :stats
    post "/subscriptions/check-permission", API.SubscriptionController, :check_permission

    # Subscription payment endpoints (Stripe)
    post "/subscriptions/checkout", API.SubscriptionController, :create_checkout_session
    post "/subscriptions/portal", API.SubscriptionController, :create_portal_session
    post "/subscriptions/setup-intent", API.SubscriptionController, :create_setup_intent

    # Payment method endpoints
    get "/payment-methods", API.SubscriptionController, :list_payment_methods
    post "/payment-methods", API.SubscriptionController, :add_payment_method
    delete "/payment-methods/:id", API.SubscriptionController, :remove_payment_method
    put "/payment-methods/:id/default", API.SubscriptionController, :set_default_payment_method

    # Invoice endpoints
    get "/invoices", API.SubscriptionController, :list_invoices
    get "/invoices/:id", API.SubscriptionController, :show_invoice

    # Coupon endpoints
    post "/coupons/apply", API.SubscriptionController, :apply_coupon

    # Support ticket endpoints (user)
    get "/support/tickets", API.SupportController, :index
    post "/support/tickets", API.SupportController, :create
    get "/support/tickets/:id", API.SupportController, :show
    post "/support/tickets/:id/messages", API.SupportController, :add_message

    # Team endpoints
    get "/teams", API.TeamController, :index
    post "/teams", API.TeamController, :create
    get "/teams/invitations", API.TeamController, :my_invitations
    get "/teams/:id", API.TeamController, :show
    put "/teams/:id", API.TeamController, :update
    delete "/teams/:id", API.TeamController, :delete

    # Team member endpoints
    get "/teams/:team_id/members", API.TeamController, :list_members
    put "/teams/:team_id/members/:user_id/role", API.TeamController, :update_member_role
    delete "/teams/:team_id/members/:user_id", API.TeamController, :remove_member
    post "/teams/:team_id/leave", API.TeamController, :leave
    post "/teams/:team_id/transfer-ownership", API.TeamController, :transfer_ownership

    # Team button endpoints
    get "/teams/:team_id/buttons", API.TeamController, :list_buttons
    post "/teams/:team_id/buttons", API.TeamController, :add_button
    put "/teams/:team_id/buttons/:button_id", API.TeamController, :update_button_permission
    delete "/teams/:team_id/buttons/:button_id", API.TeamController, :remove_button

    # Team invitation endpoints
    get "/teams/:team_id/invitations", API.TeamController, :list_invitations
    post "/teams/:team_id/invitations", API.TeamController, :create_invitation
    delete "/teams/:team_id/invitations/:id", API.TeamController, :cancel_invitation
    post "/teams/invitations/:id/accept", API.TeamController, :accept_invitation
    post "/teams/invitations/:id/decline", API.TeamController, :decline_invitation

    # Organization endpoints
    get "/organizations", API.OrganizationController, :index
    post "/organizations", API.OrganizationController, :create
    get "/organizations/invitations", API.OrganizationController, :my_invitations
    get "/organizations/:id", API.OrganizationController, :show
    put "/organizations/:id", API.OrganizationController, :update
    delete "/organizations/:id", API.OrganizationController, :delete

    # Organization member endpoints
    get "/organizations/:org_id/members", API.OrganizationController, :list_members
    put "/organizations/:org_id/members/:user_id/role", API.OrganizationController, :update_member_role
    delete "/organizations/:org_id/members/:user_id", API.OrganizationController, :remove_member
    post "/organizations/:org_id/leave", API.OrganizationController, :leave
    post "/organizations/:org_id/transfer-ownership", API.OrganizationController, :transfer_ownership

    # Organization team endpoints
    get "/organizations/:org_id/teams", API.OrganizationController, :list_teams
    post "/organizations/:org_id/teams/:team_id", API.OrganizationController, :add_team
    delete "/organizations/:org_id/teams/:team_id", API.OrganizationController, :remove_team

    # Organization invitation endpoints
    get "/organizations/:org_id/invitations", API.OrganizationController, :list_invitations
    post "/organizations/:org_id/invitations", API.OrganizationController, :create_invitation
    delete "/organizations/:org_id/invitations/:id", API.OrganizationController, :cancel_invitation
    post "/organizations/invitations/:id/accept", API.OrganizationController, :accept_invitation
    post "/organizations/invitations/:id/decline", API.OrganizationController, :decline_invitation

    # Organization subscription endpoints
    get "/organizations/:org_id/subscription", API.OrganizationController, :show_subscription

    # Organization audit log endpoints
    get "/organizations/:org_id/audit-logs", API.OrganizationController, :audit_logs
  end

  # Admin API routes
  scope "/api/admin", ButtonLogWeb.API.Admin do
    pipe_through [:api, :api_rate_limit, :auth, :admin]

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

  # Auth endpoints with strict rate limiting (5 req/min to prevent brute force)
  scope "/api", ButtonLogWeb do
    pipe_through [:api, :auth_rate_limit]

    post "/auth/register", API.AuthController, :register
    post "/auth/login", API.AuthController, :login
    post "/auth/refresh", API.AuthController, :refresh
    post "/auth/oauth/callback", API.AuthController, :oauth_callback
    post "/auth/logout", API.AuthController, :logout
  end

  # Public API endpoints (no auth, standard rate limiting)
  scope "/api", ButtonLogWeb do
    pipe_through [:api, :api_rate_limit]

    # Public subscription plans (pricing page)
    get "/subscriptions/plans", API.SubscriptionController, :index

    # App configuration (public - used by mobile apps on startup)
    get "/config", API.ConfigController, :index
  end

  # Webhook endpoints (no rate limiting - uses signature verification)
  scope "/api", ButtonLogWeb do
    pipe_through :api

    # Stripe webhook endpoint (no auth - uses signature verification)
    post "/webhooks/stripe", API.StripeWebhookController, :handle
  end

  # Health check endpoint (no auth, no pipeline)
  scope "/", ButtonLogWeb do
    get "/health", HealthController, :check
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
