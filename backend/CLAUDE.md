# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ButtonLog is a Phoenix/Elixir web application for button tracking and social interactions. The backend serves a web interface and REST API for button management, user authentication, and real-time features via Phoenix Channels.

## Development Commands

### Setup and Dependencies
- `mix setup` - Install dependencies and setup database (runs deps.get, ecto.setup)
- `mix deps.get` - Install Elixir dependencies

### Database Operations
- `mix ecto.setup` - Create database, run migrations, and seed data
- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with migrations and seeds
- `mix ecto.rollback` - Rollback last migration

### Running the Application
- `mix phx.server` - Start Phoenix server (available at localhost:4000)
- `iex -S mix phx.server` - Start server in interactive Elixir shell

### Testing
- `mix test` - Run all tests (creates test DB, runs migrations, then tests)

## Architecture Overview

### Core Contexts
The application follows Phoenix contexts pattern:

- **ButtonLog.Accounts** - User management and authentication
- **ButtonLog.Buttons** - Button creation, management, and click tracking  
- **ButtonLog.Social** - Friend relationships and permissions
- **ButtonLog.Notifications** - User notifications system
- **ButtonLog.Mobile** - Mobile device connections
- **ButtonLog.Auth.Token** - JWT token handling

### Web Layer Structure
- **Controllers**: Separate API and web controllers
  - `ButtonLogWeb.API.*` - JSON API controllers for mobile/SPA
  - Regular controllers for web interface
- **Channels**: Real-time WebSocket communication
  - `UserChannel`, `ButtonChannel`, `LobbyChannel`
- **LiveView**: `ButtonLive.Index` for interactive button interface
- **Authentication**: `AuthPlug` for API authentication, separate auth pipeline

### Database Schema
Key entities based on migrations:
- Users (authentication, profiles)
- Buttons (various types: simple, timed, etc.)
- ButtonClicks (tracking button interactions)
- Social relationships (friendships, permissions)
- Notifications
- Mobile connections

### Authentication & Security
- JWT tokens for API authentication (`ButtonLog.Auth.Token`)
- Bcrypt for password hashing
- Session-based auth for web interface
- Auth pipeline in router protects API routes

### Real-time Features
- Phoenix PubSub for real-time updates
- WebSocket channels for live interactions
- Token-based socket authentication

## Key Configuration Files
- `config/config.exs` - Base configuration
- `config/dev.exs`, `config/prod.exs`, `config/test.exs` - Environment-specific configs
- `mix.exs` - Project dependencies and aliases

## Development Notes
- Database: PostgreSQL (configured for local development)
- Web server: Cowboy2 adapter
- Real-time: Phoenix Channels with PubSub
- Frontend assets: Located in `assets/` directory with Tailwind CSS
- LiveDashboard available in development at `/dev/dashboard`