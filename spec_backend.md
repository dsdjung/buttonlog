# Unified Phoenix Application Specification (Backend + Web UI)

## Application Architecture

ButtonLog is built as a **single unified Elixir/Phoenix application** that serves both the backend API and web interface. This unified approach provides:
- **Shared codebase** for all business logic
- **LiveView web UI** built into the same application
- **REST API endpoints** for mobile applications
- **Real-time communication** via Phoenix Channels
- **Single deployment** and maintenance

```
┌─────────────────────────────────────────────────────────────┐
│              ButtonLog Unified Phoenix App                 │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │ User Service│ │Button Service│ │Social Service│         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │Notification │ │Analytics    │ │Integration  │         │
│  │Service      │ │Service      │ │Service      │         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
│  ┌─────────────┐ ┌─────────────┐                         │
│  │Payment      │ │Privacy      │                         │
│  │Service      │ │Service      │                         │
│  └─────────────┘ └─────────────┘                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │   Web UI    │ │   API       │ │  Real-time  │         │
│  │ (LiveView)  │ │Endpoints    │ │ (Channels)  │         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │   Shared    │ │PostgreSQL   │ │   Redis     │         │
│  │ Business    │ │ Database    │ │   Cache     │         │
│  │   Logic     │ │             │ │             │         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Core Framework
- **Elixir 1.18.3**: Functional programming language
- **Phoenix 1.7.21**: Web framework with real-time capabilities
- **Ecto 3.13.2**: Database wrapper and query builder
- **PostgreSQL**: Primary database with TimescaleDB extension
- **Redis**: Caching and session storage

## Unified Architecture Benefits

### Single Codebase Approach
- **Shared Models**: User, Button, and other schemas used by both web UI and API
- **Shared Services**: Business logic implemented once and used everywhere
- **Shared Database**: Single database connection pool and transaction management
- **Shared Authentication**: JWT tokens and auth logic work for web and mobile

### Web UI Integration
- **LiveView Routes**: Web interface routes are part of the same Phoenix router
- **Shared Templates**: Common UI components used across the application
- **Real-time Updates**: Web UI gets instant updates via the same Phoenix Channels
- **Session Management**: Web sessions and API tokens managed consistently

### API for Mobile Apps
- **REST Endpoints**: Mobile apps consume the same business logic via HTTP
- **WebSocket Support**: Mobile apps can also use Phoenix Channels for real-time
- **Consistent Data**: Same validation, business rules, and data models
- **Unified Deployment**: Single application to deploy and maintain

### Authentication & Security
- **JWT**: JSON Web Tokens for stateless authentication
- **Bcrypt**: Password hashing
- **Phoenix Authentication Plug**: Centralized auth handling

### Real-time Communication
- **Phoenix Channels**: WebSocket connections
- **Phoenix PubSub**: Event broadcasting and clustering
- **Phoenix LiveView**: Server-rendered real-time UI

### Additional Libraries
- **Swoosh**: Email handling
- **Redix**: Redis client
- **Telemetry**: Metrics and monitoring
- **Plug.Cowboy**: HTTP server adapter

## Application Structure

### File Organization
```
lib/buttonlog/                    # Business Logic (Shared)
├── accounts/                     # User management
├── buttons/                      # Button operations
├── social/                       # Social features
├── notifications/                # Notification handling
├── analytics/                    # Analytics and reporting
├── integrations/                 # External service connections
├── payments/                     # Subscription management
└── privacy/                      # Privacy controls

lib/buttonlog_web/               # Web Interface + API (Shared)
├── controllers/                  # API controllers for mobile
├── live/                        # LiveView modules for web UI
├── channels/                     # WebSocket channels (shared)
├── components/                   # UI components (web only)
└── router.ex                     # Routes for web + API

priv/                            # Database and assets
├── repo/                        # Database migrations
└── static/                      # Static assets for web
```

### Key Benefits of This Structure
- **No Code Duplication**: Business logic written once, used everywhere
- **Consistent API**: Web UI and mobile apps use the same underlying services
- **Unified Testing**: Test business logic once, verify it works everywhere
- **Single Deployment**: Deploy one application, serve all clients

## Service Implementation

### 1. User Service

**Technology Stack**: Elixir/Phoenix, Ecto, Bcrypt, Changesets, Phoenix Channels

**API Endpoints**:
```elixir
# Authentication
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout

# User Management
GET /api/users/profile
PUT /api/users/profile
GET /api/users/:id/public-profile
```

**Data Models**:
```elixir
defmodule ButtonLog.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :display_name, :string
    field :avatar, :string
    field :timezone, :string
    field :language, :string
    
    # Subscription info
    field :subscription_tier, Ecto.Enum, values: [:free, :premium, :enterprise]
    field :subscription_expires_at, :utc_datetime
    
    # Privacy settings
    field :default_history_sharing, :boolean, default: false
    field :allow_friend_requests, :boolean, default: true
    field :profile_visibility, Ecto.Enum, values: [:public, :friends, :private]
    field :activity_visibility, Ecto.Enum, values: [:public, :friends, :private]
    
    # Relationships
    has_many :buttons, ButtonLog.Buttons.Button
    has_many :button_clicks, ButtonLog.Buttons.ButtonClick
    has_many :friendships, ButtonLog.Social.Friendship
    has_many :friend_permissions, ButtonLog.Social.FriendPermission
    
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :display_name, :avatar, :timezone, :language])
    |> validate_required([:email, :username, :display_name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
```

### 2. Button Service

**Technology Stack**: Elixir/Phoenix, Ecto, Phoenix Channels, Phoenix PubSub

**API Endpoints**:
```elixir
# Button Management
GET /api/buttons
POST /api/buttons
GET /api/buttons/:id
PUT /api/buttons/:id
DELETE /api/buttons/:id

# Button Actions
POST /api/buttons/:id/click
GET /api/buttons/:id/history
```

**Data Models**:
```elixir
defmodule ButtonLog.Buttons.Button do
  use Ecto.Schema
  import Ecto.Changeset

  schema "buttons" do
    field :name, :string
    field :description, :string
    field :type, Ecto.Enum, values: [:instant, :timed, :state]
    field :icon, :string
    field :color, :string
    field :is_active, :boolean, default: true
    
    # Settings
    field :notifications_enabled, :boolean, default: true
    field :auto_stop_enabled, :boolean, default: false
    field :calendar_sync_enabled, :boolean, default: false
    
    belongs_to :user, ButtonLog.Accounts.User
    has_many :button_clicks, ButtonLog.Buttons.ButtonClick
    
    timestamps()
  end

  def changeset(button, attrs) do
    button
    |> cast(attrs, [:name, :description, :type, :icon, :color, :is_active, 
                    :notifications_enabled, :auto_stop_enabled, :calendar_sync_enabled])
    |> validate_required([:name, :type])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
  end
end

defmodule ButtonLog.Buttons.ButtonClick do
  use Ecto.Schema
  import Ecto.Changeset

  schema "button_clicks" do
    field :clicked_at, :utc_datetime
    field :duration, :integer  # For timed buttons
    field :location_lat, :float
    field :location_lng, :float
    field :device, :string
    field :platform, Ecto.Enum, values: [:web, :android, :iphone]
    
    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :user, ButtonLog.Accounts.User
    
    timestamps()
  end

  def changeset(button_click, attrs) do
    button_click
    |> cast(attrs, [:clicked_at, :duration, :location_lat, :location_lng, :device, :platform])
    |> validate_required([:clicked_at, :device, :platform])
    |> validate_number(:duration, greater_than: 0)
    |> validate_number(:location_lat, greater_than: -90, less_than: 90)
    |> validate_number(:location_lng, greater_than: -180, less_than: 180)
  end
end
```

### 3. Social Service

**Technology Stack**: Elixir/Phoenix, Ecto, Phoenix Channels, Phoenix PubSub

**API Endpoints**:
```elixir
# Friend Management
GET /api/friends
POST /api/friends/request
PUT /api/friends/:id/accept
DELETE /api/friends/:id

# Friend Permissions
GET /api/friends/:friend_id/permissions
PUT /api/friends/:friend_id/permissions

# Groups
GET /api/groups
POST /api/groups
GET /api/groups/:id
PUT /api/groups/:id
DELETE /api/groups/:id
```

**Data Models**:
```elixir
defmodule ButtonLog.Social.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "friendships" do
    field :status, Ecto.Enum, values: [:pending, :accepted, :blocked]
    
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User
    
    has_one :permissions, ButtonLog.Social.FriendPermission
    
    timestamps()
  end

  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:status])
    |> validate_required([:user_id, :friend_id, :status])
    |> unique_constraint([:user_id, :friend_id], name: :friendships_user_friend_index)
    |> check_constraint(:friend_id, name: :friendships_cannot_friend_self, 
                       message: "Cannot friend yourself")
  end
end

defmodule ButtonLog.Social.FriendPermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "friend_permissions" do
    field :can_view_history, :boolean, default: false
    field :can_receive_notifications, :boolean, default: true
    field :can_view_buttons, :boolean, default: true
    
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User
    
    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:user_id, :friend_id, :can_view_history, :can_receive_notifications, :can_view_buttons])
    |> validate_required([:user_id, :friend_id])
    |> unique_constraint([:user_id, :friend_id], name: :friend_permissions_user_friend_index)
  end
end
```

### 4. Notification Service

**Technology Stack**: Elixir/Phoenix, Swoosh, Phoenix Channels, Phoenix PubSub

**API Endpoints**:
```elixir
# Push Notifications
POST /api/notifications/push
GET /api/notifications/history
PUT /api/notifications/settings

# In-App Notifications
GET /api/notifications/in-app
PUT /api/notifications/:id/read
DELETE /api/notifications/:id
```

**Data Models**:
```elixir
defmodule ButtonLog.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :title, :string
    field :body, :string
    field :type, Ecto.Enum, values: [:button_click, :friend_request, :achievement, :reminder]
    field :is_read, :boolean, default: false
    field :data, :map  # Additional notification data
    
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :sender, ButtonLog.Accounts.User
    
    timestamps()
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :body, :type, :is_read, :data])
    |> validate_required([:title, :body, :type])
    |> validate_length(:title, max: 100)
    |> validate_length(:body, max: 500)
  end
end
```

### 5. Analytics Service

**Technology Stack**: Elixir/Phoenix, Ecto, TimescaleDB, Phoenix Channels

**API Endpoints**:
```elixir
# User Analytics
GET /api/analytics/user/:user_id/summary
GET /api/analytics/user/:user_id/buttons
GET /api/analytics/user/:user_id/activity

# Button Analytics
GET /api/analytics/buttons/:button_id/stats
GET /api/analytics/buttons/:button_id/trends

# Social Analytics
GET /api/analytics/social/friends
GET /api/analytics/social/groups
```

### 6. Integration Service

**Technology Stack**: Elixir/Phoenix, HTTPoison, OAuth2, Phoenix Channels

**API Endpoints**:
```elixir
# Calendar Integration
GET /api/integrations/calendar
POST /api/integrations/calendar/connect
DELETE /api/integrations/calendar/disconnect

# External Services
GET /api/integrations/external
POST /api/integrations/external/connect
DELETE /api/integrations/external/:id
```

### 7. Enhanced Privacy Controls (Simplified)

**Technology Stack**: Elixir/Phoenix, Ecto, Phoenix Channels

**API Endpoints**:
```elixir
# Privacy Settings
GET /api/privacy/settings
PUT /api/privacy/settings

# Data Export
GET /api/privacy/export
DELETE /api/privacy/account
```

**Data Models**:
```elixir
defmodule ButtonLog.Privacy.PrivacySettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "privacy_settings" do
    field :default_history_sharing, :boolean, default: false
    field :allow_friend_requests, :boolean, default: true
    field :profile_visibility, Ecto.Enum, values: [:public, :friends, :private]
    field :activity_visibility, Ecto.Enum, values: [:public, :friends, :private]
    field :location_sharing, :boolean, default: false
    field :data_retention_days, :integer, default: 365
    
    belongs_to :user, ButtonLog.Accounts.User
    
    timestamps()
  end

  def changeset(privacy_settings, attrs) do
    privacy_settings
    |> cast(attrs, [:default_history_sharing, :allow_friend_requests, :profile_visibility, 
                    :activity_visibility, :location_sharing, :data_retention_days])
    |> validate_required([:user_id])
    |> validate_number(:data_retention_days, greater_than: 30, less_than: 3650)
  end
end
```

### 8. Mobile Optimization (Simplified)

**Technology Stack**: Elixir/Phoenix, Phoenix Channels, Phoenix PubSub

**API Endpoints**:
```elixir
# Connection Management
POST /api/mobile/connections/register
PUT /api/mobile/connections/:id/status

# Offline Support
GET /api/mobile/offline/queue/:user_id
POST /api/mobile/offline/queue/:user_id
```

**Data Models**:
```elixir
defmodule ButtonLog.Mobile.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mobile_connections" do
    field :device_token, :string
    field :platform, Ecto.Enum, values: [:android, :iphone]
    field :app_version, :string
    field :os_version, :string
    field :is_active, :boolean, default: true
    field :last_seen_at, :utc_datetime
    
    belongs_to :user, ButtonLog.Accounts.User
    
    timestamps()
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:device_token, :platform, :app_version, :os_version, :is_active, :last_seen_at])
    |> validate_required([:device_token, :platform, :user_id])
    |> unique_constraint(:device_token)
  end
end
```

## Simple Real-time Architecture

### Phoenix Channels Implementation

```elixir
defmodule ButtonLogWeb.UserSocket do
  use Phoenix.Socket

  channel "user:*", ButtonLogWeb.UserChannel
  channel "button:*", ButtonLogWeb.ButtonChannel
  channel "lobby", ButtonLogWeb.LobbyChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}
      {:error, _reason} ->
        :error
    end
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end

defmodule ButtonLogWeb.ButtonChannel do
  use ButtonLogWeb, :channel

  def join("button:" <> button_id, _params, socket) do
    if authorized?(socket.assigns.user_id, button_id) do
      {:ok, assign(socket, :button_id, button_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("click", _params, socket) do
    user_id = socket.assigns.user_id
    button_id = socket.assigns.button_id
    
    case ButtonLog.Buttons.click_button(button_id, user_id) do
      {:ok, click} ->
        broadcast!(socket, "button_clicked", %{
          user_id: user_id,
          button_id: button_id,
          clicked_at: click.clicked_at
        })
        {:reply, :ok, socket}
      
      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end
end
```

### Phoenix PubSub for Real-time Updates

```elixir
defmodule ButtonLog.RealTime.ButtonBroadcaster do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:button_clicked, button_id, user_id, metadata}, state) do
    # Broadcast to all users subscribed to this button
    ButtonLogWeb.Endpoint.broadcast!(
      "button:#{button_id}",
      "button_clicked",
      %{
        user_id: user_id,
        button_id: button_id,
        metadata: metadata,
        timestamp: DateTime.utc_now()
      }
    )
    
    # Broadcast to user's friends if they have permission
    broadcast_to_friends(user_id, button_id, metadata)
    
    {:noreply, state}
  end

  defp broadcast_to_friends(user_id, button_id, metadata) do
    friends = ButtonLog.Social.get_user_friends(user_id)
    
    Enum.each(friends, fn friend ->
      if ButtonLog.Social.can_receive_notifications?(user_id, friend.id) do
        ButtonLogWeb.Endpoint.broadcast!(
          "user:#{friend.id}",
          "friend_button_clicked",
          %{
            user_id: user_id,
            button_id: button_id,
            metadata: metadata
          }
        )
      end
    end)
  end
end
```

## Database Schema

### Core Tables

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  avatar TEXT,
  timezone VARCHAR(50) DEFAULT 'UTC',
  language VARCHAR(10) DEFAULT 'en',
  subscription_tier VARCHAR(20) DEFAULT 'free',
  subscription_expires_at TIMESTAMP,
  default_history_sharing BOOLEAN DEFAULT FALSE,
  allow_friend_requests BOOLEAN DEFAULT TRUE,
  profile_visibility VARCHAR(20) DEFAULT 'public',
  activity_visibility VARCHAR(20) DEFAULT 'public',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Buttons table
CREATE TABLE buttons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  type VARCHAR(20) NOT NULL CHECK (type IN ('instant', 'timed', 'state')),
  icon VARCHAR(100),
  color VARCHAR(7),
  is_active BOOLEAN DEFAULT TRUE,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  auto_stop_enabled BOOLEAN DEFAULT FALSE,
  calendar_sync_enabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Button clicks table (TimescaleDB hypertable)
CREATE TABLE button_clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  button_id UUID NOT NULL REFERENCES buttons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  clicked_at TIMESTAMP NOT NULL,
  duration INTEGER,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  device VARCHAR(100),
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('web', 'android', 'iphone')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('button_clicks', 'clicked_at');

-- Friendships table
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Friend permissions table
CREATE TABLE friend_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  can_view_history BOOLEAN DEFAULT FALSE,
  can_receive_notifications BOOLEAN DEFAULT TRUE,
  can_view_buttons BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  data JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Mobile connections table
CREATE TABLE mobile_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_token VARCHAR(500) UNIQUE NOT NULL,
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'iphone')),
  app_version VARCHAR(50),
  os_version VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  last_seen_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Indexes for Performance

```sql
-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_subscription_tier ON users(subscription_tier);

-- Button indexes
CREATE INDEX idx_buttons_user_id ON buttons(user_id);
CREATE INDEX idx_buttons_type ON buttons(type);
CREATE INDEX idx_buttons_is_active ON buttons(is_active);

-- Button click indexes (TimescaleDB)
CREATE INDEX idx_button_clicks_button_id ON button_clicks(button_id);
CREATE INDEX idx_button_clicks_user_id ON button_clicks(user_id);
CREATE INDEX idx_button_clicks_clicked_at ON button_clicks(clicked_at DESC);

-- Friendship indexes
CREATE INDEX idx_friendships_user_id ON friendships(user_id);
CREATE INDEX idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- Notification indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Mobile connection indexes
CREATE INDEX idx_mobile_connections_user_id ON mobile_connections(user_id);
CREATE INDEX idx_mobile_connections_device_token ON mobile_connections(device_token);
CREATE INDEX idx_mobile_connections_platform ON mobile_connections(platform);
```

## API Response Format

### Standard Response Structure

```json
{
  "success": true,
  "data": {
    // Response data here
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_123456789"
  }
}
```

### Error Response Structure

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_123456789"
  }
}
```

## Authentication & Authorization

### JWT Token Structure

```elixir
defmodule ButtonLog.Auth.Token do
  use Joken.Config

  def token_config do
    default_claims(
      iss: "buttonlog",
      aud: "buttonlog_users",
      default_ttl: {24, :hour}
    )
  end

  def create_token(user_id) do
    {:ok, token, _claims} = encode_and_sign(%{"user_id" => user_id})
    token
  end

  def verify_token(token) do
    case decode_and_verify(token) do
      {:ok, claims} -> {:ok, claims["user_id"]}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

### Authentication Plug

```elixir
defmodule ButtonLogWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_auth_token(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()
      
      token ->
        case ButtonLog.Auth.Token.verify_token(token) do
          {:ok, user_id} ->
            user = ButtonLog.Accounts.get_user!(user_id)
            assign(conn, :current_user, user)
          
          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token"})
            |> halt()
        end
    end
  end

  defp get_auth_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
```

## Testing Strategy

### Unit Tests

```elixir
defmodule ButtonLog.ButtonsTest do
  use ButtonLog.DataCase
  alias ButtonLog.Buttons

  describe "buttons" do
    alias ButtonLog.Buttons.Button

    @valid_attrs %{name: "Test Button", type: :instant, icon: "star", color: "#FF0000"}
    @invalid_attrs %{name: nil, type: nil}

    test "create_button/1 with valid data creates a button" do
      user = insert(:user)
      assert {:ok, %Button{} = button} = Buttons.create_button(@valid_attrs, user.id)
      assert button.name == "Test Button"
      assert button.type == :instant
      assert button.user_id == user.id
    end

    test "create_button/1 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Buttons.create_button(@invalid_attrs, user.id)
    end
  end
end
```

### Integration Tests

```elixir
defmodule ButtonLogWeb.API.ButtonControllerTest do
  use ButtonLogWeb.ConnCase
  alias ButtonLog.{Accounts, Buttons}

  setup do
    user = insert(:user)
    conn = build_conn()
    |> put_req_header("authorization", "Bearer #{generate_token(user.id)}")
    {:ok, conn: conn, user: user}
  end

  describe "POST /api/buttons" do
    test "creates button with valid data", %{conn: conn} do
      button_data = %{
        name: "Test Button",
        type: "instant",
        icon: "star",
        color: "#FF0000"
      }

      conn = post(conn, "/api/buttons", button_data)
      assert json_response(conn, 201)
      
      response = json_response(conn, 201)
      assert response["data"]["name"] == "Test Button"
      assert response["data"]["type"] == "instant"
    end
  end
end
```

## Performance Considerations

### Database Optimization

- **Connection Pooling**: Configure Ecto with appropriate pool size
- **Query Optimization**: Use Ecto's `preload` and `join` efficiently
- **Indexing Strategy**: Strategic indexes for common query patterns
- **TimescaleDB**: Use hypertables for time-series button click data

### Caching Strategy

- **Redis Caching**: Cache frequently accessed user data and button stats
- **Ecto Query Caching**: Cache complex queries with Redis
- **Session Storage**: Store user sessions in Redis for scalability

### Real-time Performance

- **Channel Optimization**: Efficient Phoenix Channel message handling
- **PubSub Clustering**: Use Phoenix PubSub for multi-node deployments
- **WebSocket Management**: Proper connection lifecycle management

This unified Phoenix application specification provides a comprehensive foundation for building ButtonLog with a single codebase that serves both web UI and mobile API. This approach ensures:

- **Code Efficiency**: No duplication between web and API implementations
- **Consistency**: Same business logic, validation, and data models everywhere
- **Maintainability**: Single application to deploy, monitor, and update
- **Scalability**: Shared resources and efficient real-time communication
- **Developer Experience**: Work on one codebase, serve all client types

The unified architecture makes ButtonLog both powerful and simple to maintain, while providing excellent real-time capabilities across all platforms.
