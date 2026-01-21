# OAuth Implementation Guide for ButtonLog

## Overview
This document outlines the implementation of social network authentication (OAuth) for ButtonLog.

## Current Status: ✅ READY FOR OAuth

### Database Schema ✅
- **OAuth fields added** to users table
- **Migration created** for OAuth support
- **User schema updated** with OAuth fields
- **Validation logic** for OAuth vs local users

### Missing Dependencies (To be added)
```elixir
# mix.exs
defp deps do
  [
    # ... existing deps ...
    
    # OAuth support
    {:ueberauth, "~> 0.10"},
    {:ueberauth_google, "~> 0.12"},
    {:ueberauth_facebook, "~> 0.8"},
    {:ueberauth_github, "~> 0.8"},
    {:ueberauth_apple, "~> 0.3"},
    
    # OAuth2 client
    {:oauth2, "~> 2.0"}
  ]
end
```

## Implementation Steps

### 1. Install Dependencies
```bash
mix deps.get
```

### 2. Configure OAuth Providers
```elixir
# config/config.exs
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [
      client_id: System.get_env("GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
    ]},
    facebook: {Ueberauth.Strategy.Facebook, [
      client_id: System.get_env("FACEBOOK_CLIENT_ID"),
      client_secret: System.get_env("FACEBOOK_CLIENT_SECRET")
    ]},
    github: {Ueberauth.Strategy.Github, [
      client_id: System.get_env("GITHUB_CLIENT_ID"),
      client_secret: System.get_env("GITHUB_CLIENT_SECRET")
    ]},
    apple: {Ueberauth.Strategy.Apple, [
      client_id: System.get_env("APPLE_CLIENT_ID"),
      client_secret: System.get_env("APPLE_CLIENT_SECRET")
    ]}
  ]
```

### 3. Add OAuth Routes
```elixir
# lib/buttonlog_web/router.ex
scope "/auth", ButtonLogWeb do
  pipe_through :browser
  
  # Existing routes
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
```

### 4. Update AuthController
```elixir
# lib/buttonlog_web/controllers/auth_controller.ex
def request(conn, %{"provider" => provider}) do
  redirect(conn, external: Ueberauth.authorize_url(provider))
end

def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => provider}) do
  case handle_oauth_callback(auth, provider) do
    {:ok, user} ->
      conn
      |> put_session(:user_id, user.id)
      |> put_flash(:info, "Successfully authenticated with #{provider}!")
      |> redirect(to: ~p"/buttons")
      
    {:error, reason} ->
      conn
      |> put_flash(:error, "OAuth authentication failed: #{reason}")
      |> redirect(to: ~p"/auth/login")
  end
end

defp handle_oauth_callback(auth, provider) do
  # Check if user exists
  case find_or_create_oauth_user(auth, provider) do
    {:ok, user} -> {:ok, user}
    {:error, reason} -> {:error, reason}
  end
end
```

### 5. Add OAuth User Management
```elixir
# lib/buttonlog/accounts.ex
def find_or_create_oauth_user(auth, provider) do
  case find_oauth_user(auth.uid, provider) do
    nil -> create_oauth_user(auth, provider)
    user -> {:ok, user}
  end
end

def find_oauth_user(uid, provider) do
  Repo.get_by(User, provider: provider, provider_uid: uid)
end

def create_oauth_user(auth, provider) do
  attrs = %{
    email: auth.info.email,
    username: generate_unique_username(auth.info.name),
    display_name: auth.info.name,
    avatar: auth.info.image,
    provider: provider,
    provider_uid: auth.uid,
    provider_token: auth.credentials.token,
    provider_refresh_token: auth.credentials.refresh_token,
    provider_expires_at: auth.credentials.expires_at,
    email_verified: true
  }
  
  %User{}
  |> User.oauth_registration_changeset(attrs)
  |> Repo.insert()
end
```

## Testing OAuth (Local Development)

### Google OAuth Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add `http://localhost:4001/auth/google/callback` to authorized redirect URIs
6. Set environment variables:
   ```bash
   export GOOGLE_CLIENT_ID="your_client_id"
   export GOOGLE_CLIENT_SECRET="your_client_secret"
   ```

### Testing Flow
1. Visit `/auth/google` - redirects to Google
2. User authorizes ButtonLog
3. Google redirects to `/auth/google/callback`
4. User is created/logged in and redirected to `/buttons`

## Security Considerations

### OAuth Security
- **HTTPS required** in production
- **State parameter** for CSRF protection
- **PKCE** for public clients (mobile apps)
- **Token validation** and refresh handling
- **Scope limiting** (only request needed permissions)

### Data Privacy
- **Minimal data collection** from OAuth providers
- **User consent** for data sharing
- **GDPR compliance** for EU users
- **Data portability** and deletion options

## Production Deployment

### Environment Variables
```bash
# Required for OAuth
GOOGLE_CLIENT_ID=your_production_client_id
GOOGLE_CLIENT_SECRET=your_production_client_secret
FACEBOOK_CLIENT_ID=your_production_client_id
FACEBOOK_CLIENT_SECRET=your_production_client_secret
GITHUB_CLIENT_ID=your_production_client_id
GITHUB_CLIENT_SECRET=your_production_client_secret
APPLE_CLIENT_ID=your_production_client_id
APPLE_CLIENT_SECRET=your_production_client_secret

# OAuth callback URLs
OAUTH_CALLBACK_BASE_URL=https://yourdomain.com/auth
```

### SSL/TLS Requirements
- **HTTPS mandatory** for OAuth callbacks
- **Valid SSL certificate** required
- **HSTS headers** recommended
- **Secure cookie settings** for sessions

## Monitoring and Analytics

### OAuth Metrics
- **Authentication success/failure rates**
- **Provider usage statistics**
- **Token refresh patterns**
- **User linking behavior**

### Error Handling
- **OAuth provider downtime** detection
- **Token expiration** warnings
- **Rate limiting** for OAuth endpoints
- **User feedback** for auth failures


