# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ButtonLog is a comprehensive multi-platform application built with:
- **Backend**: Phoenix/Elixir web application serving REST API and web interface
- **Mobile Apps**: Native iOS (SwiftUI) and Android (Jetpack Compose) applications
- **Architecture**: Full-stack social button tracking with real-time features, subscription system, and OAuth authentication

## Development Commands

### Backend (Phoenix/Elixir) - `/backend/` directory

#### Setup and Dependencies
- `mix setup` - Install dependencies and setup database (runs deps.get, ecto.setup)
- `mix deps.get` - Install Elixir dependencies

#### Database Operations
- `mix ecto.setup` - Create database, run migrations, and seed data
- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with migrations and seeds
- `mix ecto.rollback` - Rollback last migration

#### Running the Application
- `mix phx.server` - Start Phoenix server (available at localhost:14015)
- `iex -S mix phx.server` - Start server in interactive Elixir shell

**IMPORTANT: The local development server runs on port 14015, NOT 4000.**

#### Testing
- `mix test` - Run all tests (creates test DB, runs migrations, then tests)

#### Assets
- `cd assets && npm run build` - Build JavaScript assets
- `cd assets && npm run build:css` - Build and watch Tailwind CSS

### Android App - `/android/` directory

#### Build Commands
- `./gradlew build` - Build the Android application
- `./gradlew assembleDebug` - Build debug APK
- `./gradlew assembleRelease` - Build release APK
- `./gradlew test` - Run unit tests
- `./gradlew connectedAndroidTest` - Run instrumentation tests

#### Development
- Open `android/` in Android Studio
- Sync Gradle dependencies automatically
- Use Android Studio's built-in build and run tools

### iOS App - `/iphone/` directory

#### Development
- Open `iphone/ButtonLog.xcodeproj` in Xcode
- Build and run using Xcode's interface (⌘R)
- Run tests using Xcode's test navigator (⌘U)

## Architecture Overview

### Multi-Platform Structure
The application consists of three main components:
1. **Phoenix Backend** (`backend/`) - API server and web interface
2. **Android App** (`android/`) - Jetpack Compose mobile client
3. **iOS App** (`iphone/`) - SwiftUI mobile client

### Backend Architecture (Phoenix/Elixir)

#### Core Contexts
- **ButtonLog.Accounts** - User management and authentication
- **ButtonLog.Buttons** - Button creation, management, and click tracking  
- **ButtonLog.Social** - Friend relationships and permissions
- **ButtonLog.Notifications** - User notifications system
- **ButtonLog.Subscriptions** - Feature-based subscription tiers and usage tracking
- **ButtonLog.Mobile** - Mobile device connections
- **ButtonLog.Auth.Token** - JWT token handling

#### Web Layer Structure
- **API Controllers**: JSON API endpoints for mobile apps (`ButtonLogWeb.API.*`)
- **Web Controllers**: HTML controllers for web interface
- **Live Views**: Real-time interactive interfaces (`ButtonLive.Index`, `ButtonNotificationsLive`)
- **Channels**: WebSocket real-time communication (`UserChannel`, `ButtonChannel`)
- **Authentication**: `AuthPlug` for API auth, OAuth support (Google, Facebook, Apple)

#### Key Features
- **Subscription System**: Feature-based pricing with Free, Premium, and Enterprise tiers
- **Real-time Updates**: Phoenix Channels with PubSub for live button state changes
- **OAuth Authentication**: Multi-provider OAuth (Google, Facebook, Apple) integration
- **JWT API Authentication**: Secure token-based mobile API access

### Mobile Apps Architecture

#### iOS App (SwiftUI)
- **MVVM Pattern**: SwiftUI views with Combine for reactive data flow
- **APIService**: HTTP client for backend communication
- **ButtonManager**: Business logic for button operations
- **Navigation**: Bottom tab navigation with prominent + button

#### Android App (Jetpack Compose)
- **MVVM + Repository Pattern**: Clean architecture with dependency injection (Hilt)
- **Retrofit**: HTTP client with Gson for JSON parsing
- **Room**: Local database for offline caching
- **Coroutines**: Asynchronous programming for network operations

### Database Schema
Key entities:
- **Users**: Authentication profiles with OAuth support
- **Buttons**: Various types (instant, timed, state) with customization
- **ButtonClicks**: Click tracking with timestamps and actions
- **Social**: Friend relationships with granular permissions
- **Notifications**: User notification preferences and history
- **Subscriptions**: User subscription tracking with usage limits
- **Mobile Connections**: Device registration for push notifications

## Development Workflow

### Backend Development
1. **Environment Setup**: Copy `backend/env_template.txt` to `.env` and configure
2. **Database Setup**: Run `mix setup` to create and migrate database
3. **Start Server**: Use `mix phx.server` or `iex -S mix phx.server`
4. **Live Dashboard**: Available at `/dev/dashboard` in development

### Mobile Development
1. **Backend First**: Ensure Phoenix backend is running on localhost:14015
2. **API Configuration**:
   - iOS: Uses `http://localhost:14015/api`
   - Android: Uses `http://10.0.2.2:14015/api` (Android emulator networking)
3. **Build**: Use native IDE build tools (Xcode for iOS, Android Studio for Android)

### Testing Strategy
- **Backend**: Phoenix tests with database setup (`mix test`)
- **Mobile**: Unit tests for business logic, UI tests for user flows
- **Integration**: Test API endpoints with mobile apps connected

## Configuration Files

### Backend Configuration
- `backend/config/config.exs` - Base configuration
- `backend/config/dev.exs`, `backend/config/prod.exs` - Environment-specific
- `backend/mix.exs` - Dependencies and project configuration
- `backend/assets/package.json` - Frontend asset build configuration
- `backend/assets/tailwind.config.js` - Tailwind CSS configuration

### Mobile Configuration
- `android/app/build.gradle.kts` - Android build configuration
- `iphone/ButtonLog.xcodeproj` - iOS project configuration

## Key Dependencies

### Backend (Elixir/Phoenix)
- **Phoenix Framework**: Web application framework
- **Ecto**: Database wrapper and query generator
- **Phoenix LiveView**: Real-time server-rendered HTML
- **Joken**: JWT token handling
- **Ueberauth**: OAuth authentication framework
- **Bcrypt**: Password hashing
- **Swoosh**: Email delivery
- **Phoenix PubSub**: Real-time messaging

### Android
- **Jetpack Compose**: Modern UI toolkit
- **Hilt**: Dependency injection
- **Retrofit**: HTTP client
- **Room**: Local database
- **Kotlin Coroutines**: Asynchronous programming

### iOS
- **SwiftUI**: Native iOS UI framework
- **Combine**: Reactive programming
- **Foundation**: Core iOS functionality

## API Structure

### Public Endpoints (No Auth)
- `POST /api/auth/login` - User authentication
- `POST /api/auth/register` - User registration
- `GET /api/subscriptions` - Public subscription plans

### Authenticated API Endpoints
- **Buttons**: `/api/buttons/*` - Button CRUD and click operations
- **Social**: `/api/friends/*` - Friend management and permissions
- **Notifications**: `/api/notifications/*` - Notification management
- **Subscriptions**: `/api/subscriptions/*` - Subscription management and usage tracking
- **Users**: `/api/users/*` - Profile management

## Development Notes

### Real-time Features
- Phoenix Channels for WebSocket communication
- PubSub for broadcasting updates across sessions
- Token-based authentication for WebSocket connections

### Subscription System
- Feature-based access control with usage tracking
- Monthly limits reset automatically
- Runtime permission checks for all protected features

### OAuth Integration
- Multi-provider support (Google, Facebook, Apple)
- Secure token exchange and user profile sync
- Web and mobile authentication flows

### Security
- JWT tokens for API authentication
- Bcrypt for password hashing
- OAuth provider integration
- CSRF protection for web interface