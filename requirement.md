# ButtonLog Requirements

ButtonLog is a unified Phoenix application that serves both web and mobile clients through a single codebase.

## Authentication Requirements

### Local Authentication
- User registration with email, username, password
- User login with email/password
- Password hashing with Bcrypt
- Session-based authentication for web interface
- JWT token authentication for mobile API

### Social Network Authentication (OAuth)
- **Google OAuth** - Primary social login option
- **Facebook OAuth** - Secondary social login option  
- **GitHub OAuth** - Developer-focused login option
- **Apple OAuth** - iOS ecosystem integration
- OAuth users bypass password requirements
- Automatic email verification for OAuth users
- Unified user accounts (OAuth + local auth can be linked)
- Token refresh handling for OAuth providers

### Authentication Features
- Email verification status tracking
- Account linking (multiple OAuth providers to same email)
- Password reset for local users
- Account deletion with data cleanup
- Privacy controls for OAuth data sharing

## Core Features
- Button creation and management
- Button click tracking and analytics
- Social features (friends, permissions)
- Real-time notifications
- Mobile API endpoints
- Web interface with LiveView

## Technical Requirements
- Phoenix 1.7+ with LiveView
- PostgreSQL with TimescaleDB extension
- Redis for caching and sessions
- JWT for mobile authentication
- OAuth2 integration for social login
- Real-time updates via Phoenix Channels
- RESTful API for mobile clients
