# ButtonLog App - High-Level Design Specification

## System Architecture Overview

ButtonLog is a comprehensive button logging application built with a unified Elixir/Phoenix backend that serves web, Android, and iPhone clients. The system uses real-time communication through Phoenix Channels and provides a robust, scalable foundation for button tracking and social interactions.

## Core Architecture Components

### 1. Unified Phoenix Application (Backend + Web UI)
**Single Elixir/Phoenix codebase serving both backend API and web interface:**

- **Backend Services**: User, Button, Social, Notification, Analytics, Integration, Payment, Privacy
- **Web Interface**: Phoenix LiveView-based responsive web UI
- **API Endpoints**: RESTful API for mobile apps
- **Real-time Communication**: Phoenix Channels for WebSocket connections
- **Shared Business Logic**: All services, models, and database operations

### 2. Data Layer
- **PostgreSQL Database**: Primary data storage with TimescaleDB extension
- **Redis**: Caching, session management, real-time data
- **Ecto ORM**: Database abstraction and migrations

### 3. Real-time Communication
- **Phoenix Channels**: WebSocket connections for real-time updates across all clients
- **Phoenix PubSub**: Event broadcasting and clustering
- **Phoenix LiveView**: Server-rendered real-time UI for web (part of the same app)

### 4. Client Applications
- **Web Client**: Built into the Phoenix app via LiveView (same codebase)
- **Android App**: Separate native Kotlin app consuming Phoenix API
- **iPhone App**: Separate native Swift app consuming Phoenix API

## Why Elixir/Phoenix for ButtonLog?

### Real-time Capabilities
- **Phoenix Channels**: Built-in WebSocket support for real-time button updates
- **Phoenix PubSub**: Efficient event broadcasting across all connected clients
- **LiveView**: Server-rendered real-time UI without complex JavaScript

### Scalability & Performance
- **BEAM VM**: Handles thousands of concurrent connections efficiently
- **Actor Model**: Natural concurrency for handling multiple button clicks
- **Hot Code Reloading**: Zero-downtime deployments and updates

### Mobile App Support
- **Phoenix Channels**: Works seamlessly with mobile WebSocket clients
- **RESTful APIs**: Standard HTTP endpoints for mobile app integration
- **Real-time Sync**: Instant updates across all platforms

### Cost Efficiency
- **Unified Application**: One Phoenix app serves web UI + mobile API
- **Reduced Infrastructure**: Less servers needed compared to microservices
- **Developer Productivity**: Faster development with LiveView and Channels
- **Shared Codebase**: Web UI and backend services in the same application

## Data Models

### User (Simplified & Robust)
```json
{
  "id": "uuid",
  "email": "string",
  "username": "string",
  "passwordHash": "string",
  "displayName": "string",
  "avatar": "url",
  "timezone": "string",
  "language": "string",
  "subscription": {
    "tier": "free|premium|enterprise",
    "expiresAt": "timestamp"
  },
  "privacy": {
    "defaultHistorySharing": false,
    "allowFriendRequests": true,
    "profileVisibility": "public|friends|private",
    "activityVisibility": "public|friends|private"
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Button
```json
{
  "id": "uuid",
  "userId": "uuid",
  "name": "string",
  "description": "string",
  "type": "instant|timed|state",
  "icon": "string",
  "color": "string",
  "isActive": "boolean",
  "settings": {
    "notifications": "boolean",
    "autoStop": "boolean",
    "calendarSync": "boolean"
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Button Click
```json
{
  "id": "uuid",
  "buttonId": "uuid",
  "userId": "uuid",
  "clickedAt": "timestamp",
  "duration": "integer|null",
  "metadata": {
    "location": "coordinates|null",
    "device": "string",
    "platform": "web|android|iphone"
  }
}
```

### Friend Relationship
```json
{
  "id": "uuid",
  "userId": "uuid",
  "friendId": "uuid",
  "status": "pending|accepted|blocked",
  "permissions": {
    "canViewHistory": "boolean",
    "canReceiveNotifications": "boolean",
    "canViewButtons": "boolean"
  },
  "createdAt": "timestamp"
}
```

## Security Architecture

### Authentication & Authorization
- **JWT Tokens**: Secure stateless authentication
- **Phoenix Authentication Plug**: Centralized auth handling
- **Friend-based Permissions**: Granular privacy controls
- **Role-based Access**: User, premium, enterprise tiers

### Privacy Controls
- **Activity History Sharing**: User-selectable friends/groups
- **Button Notifications**: Separate from history sharing permissions
- **Profile Visibility**: Public, friends-only, or private
- **Data Export**: User control over personal data

### Data Protection
- **Password Hashing**: Bcrypt for secure password storage
- **HTTPS Only**: All communications encrypted
- **Input Validation**: Ecto changesets for data sanitization
- **SQL Injection Protection**: Parameterized queries via Ecto

## Scalability & Performance

### Horizontal Scaling
- **Phoenix PubSub**: Automatic clustering across multiple nodes
- **Database Sharding**: User-based partitioning for large scale
- **CDN Integration**: Static asset delivery optimization
- **Load Balancing**: Multiple Phoenix instances behind load balancer

### Performance Optimization
- **Database Indexing**: Optimized queries for button clicks and history
- **Redis Caching**: Frequently accessed data and session storage
- **Background Jobs**: Async processing for notifications and analytics
- **Connection Pooling**: Efficient database connection management

### Real-time Performance
- **Phoenix Channels**: Efficient WebSocket handling
- **Event Broadcasting**: Optimized PubSub for real-time updates
- **Mobile Optimization**: Efficient data sync for mobile clients

## Integration Points

### External Services
- **Calendar APIs**: Google Calendar, Outlook, Apple Calendar
- **Push Notifications**: FCM for Android, APNs for iPhone
- **Email Services**: Swoosh for transactional emails
- **Payment Processing**: Stripe integration for subscriptions

### Mobile App Integration
- **Phoenix Channels**: WebSocket connections for real-time sync
- **RESTful APIs**: Standard HTTP endpoints for CRUD operations
- **Offline Support**: Local data storage with sync when online
- **Push Notifications**: Real-time updates for button activities

## Deployment & DevOps

### Infrastructure
- **Cloud Platform**: Railway (development), DigitalOcean (production)
- **Containerization**: Docker for consistent deployment
- **Database**: PostgreSQL with TimescaleDB extension
- **Caching**: Redis for session and data caching

### Monitoring & Observability
- **Telemetry**: Built-in Phoenix metrics and monitoring
- **Logging**: Structured logging with metadata
- **Health Checks**: Endpoint monitoring and alerting
- **Performance Metrics**: Response times, throughput, error rates

### CI/CD Pipeline
- **GitHub Actions**: Automated testing and deployment
- **Test Coverage**: Comprehensive test suite for all components
- **Code Quality**: Automated linting and formatting
- **Security Scanning**: Dependency vulnerability checks

## Success Metrics & KPIs

### Technical Metrics
- **Response Time**: < 500ms for button clicks
- **Uptime**: 99.9% availability target
- **Throughput**: 1000+ concurrent button clicks per minute
- **Error Rate**: < 0.1% error rate target

### Business Metrics
- **User Engagement**: Daily active users, button click frequency
- **Platform Adoption**: Web vs mobile usage distribution
- **Feature Usage**: Button types, social features, integrations
- **Subscription Conversion**: Free to premium tier conversion rate

## Development Timeline

### Phase 1: Core Foundation (Weeks 1-4)
- Unified Phoenix application setup (backend + web UI)
- Database setup and core services
- Basic user authentication and button management
- Phoenix Channels for real-time communication
- Web interface via LiveView (same codebase)

### Phase 2: Mobile Apps (Weeks 5-8)
- Android app with Phoenix Channels integration
- iPhone app with Phoenix Channels integration
- Offline support and data synchronization
- Push notification implementation

### Phase 3: Social Features (Weeks 9-12)
- Friend management and permissions
- Activity sharing and privacy controls
- Group functionality and collaborative buttons
- Advanced notification system

### Phase 4: Advanced Features (Weeks 13-16)
- Calendar integration and automation
- Analytics and insights dashboard
- Payment processing and subscriptions
- Performance optimization and scaling

This architecture provides a solid foundation for building a scalable, real-time button logging application that serves web and mobile clients efficiently while maintaining excellent developer productivity and operational efficiency.
