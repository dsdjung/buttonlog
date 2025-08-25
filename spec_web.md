# Web UI Specification (Phoenix LiveView - Part of Unified App)

## Overview

**This is NOT a separate web client - it's the web interface built into the unified Phoenix application.** The web UI shares the same codebase, database, and business logic as the backend API.

## Technology Stack

### Primary Framework
- **Phoenix LiveView**: Server-rendered real-time UI (same app as backend)
- **HEEx Templates**: HTML + Elixir templating
- **Phoenix Channels**: WebSocket connections for real-time updates (shared with mobile)
- **Tailwind CSS**: Utility-first CSS framework for styling

### Alternative Stack (React + Phoenix Backend)
- **React 18**: Component-based UI library
- **TypeScript**: Type-safe JavaScript
- **Phoenix Channels**: WebSocket client for real-time updates
- **Vite**: Fast build tool and dev server

## Unified Architecture Overview

**The web UI is built into the same Phoenix application that serves the backend API.** This unified approach provides:

- **Shared Codebase**: Web UI and backend services in the same Elixir application
- **Shared Database**: Same Ecto models and database connections
- **Shared Business Logic**: Same services, validation, and business rules
- **Shared Authentication**: Same JWT tokens and user sessions
- **Shared Real-time**: Same Phoenix Channels for all clients

### Benefits of Unified Approach
- **No API Duplication**: Web UI calls the same services as mobile apps
- **Consistent Behavior**: Same validation and business rules everywhere
- **Easier Testing**: Test business logic once, verify it works everywhere
- **Single Deployment**: Deploy one application, serve web + mobile

### How It Works
The web UI is built using Phoenix LiveView, which provides server-rendered real-time UI without complex JavaScript. This approach offers:

- **Real-time Updates**: Automatic UI updates through Phoenix Channels
- **Server-side Rendering**: SEO-friendly and fast initial page loads
- **Live Navigation**: Smooth page transitions without full page reloads
- **State Management**: Centralized state management on the server
- **Form Handling**: Real-time form validation and submission

## Application Structure

```
lib/buttonlog_web/
├── live/                    # LiveView modules
│   ├── button_live/        # Button management
│   ├── activity_live/      # Activity tracking
│   ├── friend_live/        # Social features
│   ├── group_live/         # Group management
│   └── profile_live/       # User profile
├── components/              # Reusable UI components
│   ├── layouts/            # Page layouts
│   ├── core_components.ex  # Core UI components
│   └── button_components.ex # Button-specific components
├── controllers/             # Traditional controllers
│   ├── page_controller.ex  # Static pages
│   └── api_controller.ex   # API endpoints
└── channels/                # WebSocket channels
    ├── user_channel.ex      # User-specific events
    └── button_channel.ex    # Button events
```

## Core LiveView Modules

### 1. Button Management (ButtonLive)

**File**: `lib/buttonlog_web/live/button_live/index.ex`

**Features**:
- Create, edit, and delete buttons
- Real-time button clicking
- Button type management (instant, timed, state)
- Button settings and customization

**Key Functions**:
```elixir
defmodule ButtonLogWeb.ButtonLive.Index do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Buttons
  alias ButtonLog.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ButtonLog.PubSub, "buttons")
    end

    {:ok, 
     socket
     |> assign(:buttons, [])
     |> assign(:current_user, nil)
     |> assign(:page_title, "Buttons")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, socket |> assign(:page_title, "Edit Button")}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket |> assign(:page_title, "Buttons")}
  end

  @impl true
  def handle_event("click", %{"id" => button_id}, socket) do
    user = socket.assigns.current_user
    
    case Buttons.click_button(button_id, user.id) do
      {:ok, click} ->
        # Broadcast to all connected clients
        Phoenix.PubSub.broadcast!(
          ButtonLog.PubSub,
          "buttons",
          {:button_clicked, click}
        )
        
        {:noreply, socket}
      
      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to click button: #{reason}")}
    end
  end

  @impl true
  def handle_info({:button_clicked, click}, socket) do
    {:noreply, socket |> put_flash(:info, "Button clicked!")}
  end
end
```

**Template**: `lib/buttonlog_web/live/button_live/index.html.heex`

```heex
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  <div class="py-8">
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900">My Buttons</h1>
      <button phx-click="new" class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
        New Button
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <%= for button <- @buttons do %>
        <div class="bg-white rounded-lg shadow-md p-6 border border-gray-200">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center space-x-3">
              <div class="w-10 h-10 rounded-full flex items-center justify-center text-white text-lg font-bold"
                   style="background-color: <%= button.color %>">
                <%= button.icon %>
              </div>
              <div>
                <h3 class="text-lg font-semibold text-gray-900"><%= button.name %></h3>
                <p class="text-sm text-gray-500"><%= button.type %></p>
              </div>
            </div>
            <div class="flex space-x-2">
              <button phx-click="edit" phx-value-id={button.id} 
                      class="text-gray-400 hover:text-gray-600">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                </svg>
              </button>
              <button phx-click="delete" phx-value-id={button.id}
                      class="text-red-400 hover:text-red-600">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                </svg>
              </button>
            </div>
          </div>
          
          <p class="text-gray-600 mb-4"><%= button.description %></p>
          
          <div class="flex justify-between items-center">
            <div class="flex space-x-2">
              <%= if button.notifications_enabled do %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  Notifications
                </span>
              <% end %>
              <%= if button.auto_stop_enabled do %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  Auto-stop
                </span>
              <% end %>
            </div>
            
            <button phx-click="click" phx-value-id={button.id}
                    class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors">
              Click!
            </button>
          </div>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

### 2. Activity Tracking (ActivityLive)

**File**: `lib/buttonlog_web/live/activity_live/index.ex`

**Features**:
- Real-time activity feed
- Button click history
- Activity analytics and insights
- Social activity sharing

**Key Functions**:
```elixir
defmodule ButtonLogWeb.ActivityLive.Index do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Activities

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ButtonLog.PubSub, "activities")
    end

    {:ok, 
     socket
     |> assign(:activities, [])
     |> assign(:page_title, "Activity Feed")}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    activities = Activities.get_user_activities(socket.assigns.current_user.id, limit: 20)
    {:noreply, socket |> assign(:activities, activities)}
  end

  @impl true
  def handle_info({:activity_created, activity}, socket) do
    activities = [activity | socket.assigns.activities]
    {:noreply, socket |> assign(:activities, activities)}
  end
end
```

### 3. Social Features (FriendLive)

**File**: `lib/buttonlog_web/live/friend_live/index.ex`

**Features**:
- Friend management
- Friend requests
- Activity sharing permissions
- Social interactions

**Key Functions**:
```elixir
defmodule ButtonLogWeb.FriendLive.Index do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Social

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ButtonLog.PubSub, "friends:#{socket.assigns.current_user.id}")
    end

    {:ok, 
     socket
     |> assign(:friends, [])
     |> assign(:pending_requests, [])
     |> assign(:page_title, "Friends")}
  end

  @impl true
  def handle_event("send_request", %{"username" => username}, socket) do
    case Social.send_friend_request(socket.assigns.current_user.id, username) do
      {:ok, _request} ->
        {:noreply, socket |> put_flash(:info, "Friend request sent!")}
      
      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to send request: #{reason}")}
    end
  end

  @impl true
  def handle_event("accept_request", %{"id" => request_id}, socket) do
    case Social.accept_friend_request(request_id) do
      {:ok, _friendship} ->
        {:noreply, socket |> put_flash(:info, "Friend request accepted!")}
      
      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to accept request: #{reason}")}
    end
  end
end
```

## Enhanced Real-time Features (Simplified)

### Simple Connection Status

**File**: `lib/buttonlog_web/components/connection_status.ex`

```elixir
defmodule ButtonLogWeb.Components.ConnectionStatus do
  use Phoenix.Component
  import Phoenix.HTML

  def connection_status(assigns) do
    ~H"""
    <div class="fixed top-4 right-4 z-50">
      <div class={[
        "px-3 py-2 rounded-lg text-sm font-medium shadow-lg",
        if(@is_connected, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800")
      ]}>
        <div class="flex items-center space-x-2">
          <div class={[
            "w-2 h-2 rounded-full",
            if(@is_connected, do: "bg-green-500", else: "bg-red-500")
          ]}></div>
          <span>
            <%= if @is_connected, do: "Connected", else: "Disconnected" %>
          </span>
        </div>
      </div>
    </div>
    """
  end
end
```

**Usage in LiveView**:
```elixir
defmodule ButtonLogWeb.ButtonLive.Index do
  use ButtonLogWeb, :live_view
  
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ButtonLog.PubSub, "connection_status")
    end

    {:ok, 
     socket
     |> assign(:is_connected, true)
     |> assign(:page_title, "Buttons")}
  end

  @impl true
  def handle_info({:connection_status, status}, socket) do
    {:noreply, socket |> assign(:is_connected, status.connected)}
  end
end
```

**Template**:
```heex
<.connection_status is_connected={@is_connected} />
```

### Simple Notification Service

**File**: `lib/buttonlog_web/components/notification_service.ex`

```elixir
defmodule ButtonLogWeb.Components.NotificationService do
  use Phoenix.Component
  import Phoenix.HTML

  def notification_toast(assigns) do
    ~H"""
    <div class="fixed top-4 left-4 z-50 space-y-2">
      <%= for notification <- @notifications do %>
        <div class={[
          "px-4 py-3 rounded-lg shadow-lg max-w-sm",
          notification_class(notification.type)
        ]}>
          <div class="flex items-start space-x-3">
            <div class="flex-shrink-0">
              <%= notification_icon(notification.type) %>
            </div>
            <div class="flex-1">
              <p class="text-sm font-medium text-white">
                <%= notification.title %>
              </p>
              <p class="text-sm text-white opacity-90">
                <%= notification.message %>
              </p>
            </div>
            <button phx-click="dismiss_notification" phx-value-id={notification.id}
                    class="text-white opacity-70 hover:opacity-100">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp notification_class(:success), do: "bg-green-600"
  defp notification_class(:error), do: "bg-red-600"
  defp notification_class(:info), do: "bg-blue-600"
  defp notification_class(:warning), do: "bg-yellow-600"

  defp notification_icon(:success) do
    ~H"""
    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
    </svg>
    """
  end

  defp notification_icon(:error) do
    ~H"""
    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
    </svg>
    """
  end

  defp notification_icon(:info) do
    ~H"""
    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
    </svg>
    """
  end

  defp notification_icon(:warning) do
    ~H"""
    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
    </svg>
    """
  end
end
```

### Simple Offline Support

**File**: `lib/buttonlog_web/components/offline_support.ex`

```elixir
defmodule ButtonLogWeb.Components.OfflineSupport do
  use Phoenix.Component
  import Phoenix.HTML

  def offline_indicator(assigns) do
    ~H"""
    <div class="fixed bottom-4 left-4 z-50">
      <%= if not @is_online do %>
        <div class="bg-yellow-600 text-white px-4 py-3 rounded-lg shadow-lg">
          <div class="flex items-center space-x-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
            </svg>
            <span class="text-sm font-medium">You're offline</span>
          </div>
          <p class="text-xs mt-1 opacity-90">Some features may be limited</p>
        </div>
      <% end %>
    </div>
    """
  end
end
```

## Phoenix LiveView Alternative

For teams preferring React, here's how to integrate with Phoenix backend:

### React + Phoenix Backend

**Technology Stack**:
- **React 18**: Component-based UI
- **TypeScript**: Type safety
- **Phoenix Channels**: WebSocket client
- **Vite**: Build tool

**Phoenix Channels Client**:
```typescript
// hooks/usePhoenixChannel.ts
import { useEffect, useRef, useState } from 'react';
import { Socket, Channel } from 'phoenix';

export const usePhoenixChannel = (channelName: string, params: any = {}) => {
  const [channel, setChannel] = useState<Channel | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    // Connect to Phoenix backend
    const socket = new Socket('/socket', {
      params: { token: localStorage.getItem('auth_token') }
    });

    socket.connect();
    socketRef.current = socket;

    // Join channel
    const channel = socket.channel(channelName, params);
    channel.join()
      .receive('ok', () => {
        setChannel(channel);
        setIsConnected(true);
      })
      .receive('error', (resp) => {
        console.error('Failed to join channel:', resp);
      });

    return () => {
      channel.leave();
      socket.disconnect();
    };
  }, [channelName, params]);

  return { channel, isConnected };
};
```

**Button Component with Real-time Updates**:
```typescript
// components/Button.tsx
import React, { useState, useEffect } from 'react';
import { usePhoenixChannel } from '../hooks/usePhoenixChannel';

interface ButtonProps {
  id: string;
  name: string;
  type: 'instant' | 'timed' | 'state';
  icon: string;
  color: string;
  onDelete: (id: string) => void;
}

export const Button: React.FC<ButtonProps> = ({ id, name, type, icon, color, onDelete }) => {
  const [clickCount, setClickCount] = useState(0);
  const { channel, isConnected } = usePhoenixChannel(`button:${id}`);

  useEffect(() => {
    if (channel) {
      // Listen for button click events
      channel.on('button_clicked', (payload) => {
        setClickCount(prev => prev + 1);
      });

      return () => {
        channel.off('button_clicked');
      };
    }
  }, [channel]);

  const handleClick = () => {
    if (channel && isConnected) {
      channel.push('click', { button_id: id });
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div 
            className="w-10 h-10 rounded-full flex items-center justify-center text-white text-lg font-bold"
            style={{ backgroundColor: color }}
          >
            {icon}
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">{name}</h3>
            <p className="text-sm text-gray-500">{type}</p>
          </div>
        </div>
        <button 
          onClick={() => onDelete(id)}
          className="text-red-400 hover:text-red-600"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" 
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
          </svg>
        </button>
      </div>
      
      <div className="flex justify-between items-center">
        <div className="text-sm text-gray-500">
          Clicks: {clickCount}
        </div>
        
        <button 
          onClick={handleClick}
          disabled={!isConnected}
          className={`px-4 py-2 rounded-lg transition-colors ${
            isConnected 
              ? 'bg-green-600 text-white hover:bg-green-700' 
              : 'bg-gray-400 text-gray-200 cursor-not-allowed'
          }`}
        >
          {isConnected ? 'Click!' : 'Connecting...'}
        </button>
      </div>
    </div>
  );
};
```

## Styling and UI Components

### Tailwind CSS Configuration

**File**: `assets/css/app.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn-primary {
    @apply bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors;
  }
  
  .btn-secondary {
    @apply bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors;
  }
  
  .btn-danger {
    @apply bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors;
  }
  
  .card {
    @apply bg-white rounded-lg shadow-md p-6 border border-gray-200;
  }
  
  .input-field {
    @apply w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
  }
}
```

### Core UI Components

**File**: `lib/buttonlog_web/components/core_components.ex`

```elixir
defmodule ButtonLogWeb.CoreComponents do
  use Phoenix.Component
  import Phoenix.HTML

  def button(assigns) do
    ~H"""
    <button class={[
      "px-4 py-2 rounded-lg font-medium transition-colors",
      "focus:outline-none focus:ring-2 focus:ring-offset-2",
      case @variant do
        :primary -> "bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500"
        :secondary -> "bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500"
        :danger -> "bg-red-600 text-white hover:bg-red-700 focus:ring-red-500"
        :success -> "bg-green-600 text-white hover:bg-green-700 focus:ring-green-500"
      end
    ]} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def input(assigns) do
    ~H"""
    <input class="input-field" {@rest} />
    """
  end

  def card(assigns) do
    ~H"""
    <div class="card">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto">
      <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                  <%= @title %>
                </h3>
                <div class="mt-2">
                  <%= render_slot(@inner_block) %>
                </div>
              </div>
            </div>
          </div>
          
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <%= render_slot(@actions) %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
```

## Performance Optimization

### LiveView Optimization

- **Efficient Assigns**: Only assign necessary data to the socket
- **Conditional Rendering**: Use `if` and `case` for conditional UI elements
- **Streams**: Use `Phoenix.LiveView.stream` for large lists
- **Debouncing**: Implement debouncing for frequent events

### Channel Optimization

- **Message Size**: Keep WebSocket messages small and focused
- **Connection Management**: Properly handle connection lifecycle
- **Error Handling**: Graceful fallbacks for connection issues

### Asset Optimization

- **Code Splitting**: Split JavaScript bundles by route
- **Image Optimization**: Use WebP format and proper sizing
- **CSS Purging**: Remove unused CSS with Tailwind's purge option

## Testing Strategy

### LiveView Testing

```elixir
defmodule ButtonLogWeb.ButtonLiveTest do
  use ButtonLogWeb.ConnCase
  import Phoenix.LiveViewTest
  alias ButtonLog.{Accounts, Buttons}

  setup do
    user = insert(:user)
    button = insert(:button, user: user)
    
    {:ok, view, _html} = live(conn, "/buttons")
    
    {:ok, view: view, user: user, button: button}
  end

  test "clicking button creates activity", %{view: view, button: button} do
    assert view |> element("button", "Click!") |> render_click()
    
    # Verify the button click was recorded
    assert_redirect(view, "/buttons")
  end

  test "real-time updates work", %{view: view, button: button} do
    # Simulate button click from another client
    Phoenix.PubSub.broadcast!(
      ButtonLog.PubSub,
      "buttons",
      {:button_clicked, %{button_id: button.id, user_id: button.user_id}}
    )
    
    # Verify the UI updates
    assert view |> has_element?(".notification", "Button clicked!")
  end
end
```

### Component Testing

```elixir
defmodule ButtonLogWeb.CoreComponentsTest do
  use ButtonLogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "button component renders correctly" do
    html = render_component(&ButtonLogWeb.CoreComponents.button/1, %{
      variant: :primary,
      inner_block: "Click me"
    })
    
    assert html =~ "Click me"
    assert html =~ "bg-blue-600"
  end
end
```

## Deployment Configuration

### Build Configuration

**File**: `assets/package.json`

```json
{
  "name": "buttonlog-assets",
  "version": "1.0.0",
  "scripts": {
    "build": "vite build",
    "dev": "vite",
    "watch": "vite build --watch"
  },
  "dependencies": {
    "phoenix": "^1.7.0",
    "phoenix_live_view": "^0.19.0"
  },
  "devDependencies": {
    "vite": "^4.0.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0"
  }
}
```

**File**: `assets/vite.config.js`

```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: '../priv/static/assets',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        app: './src/main.jsx'
      }
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/socket': 'http://localhost:4000',
      '/api': 'http://localhost:4000'
    }
  }
})
```

This web client specification provides a comprehensive foundation for building the ButtonLog web interface using Phoenix LiveView, with alternatives for React-based development and detailed implementation examples for all core features.
