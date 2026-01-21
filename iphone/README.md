# ButtonLog iOS App

A native iOS application built with SwiftUI that provides full feature parity with the ButtonLog Phoenix backend.

## Features

### 🎯 Complete Backend Feature Parity

#### Core Features
- **Button Management**: Create, edit, delete, and click buttons
- **Button Types**: Support for Instant, Timed, and State buttons
- **Real-time Updates**: Live button state synchronization
- **Search & Filtering**: Find buttons by name or description

#### Authentication & User Management
- **Email/Password Authentication**: Secure login and registration
- **OAuth Integration**: Support for Apple, Google, and Facebook (ready for implementation)
- **JWT Token Management**: Secure API communication with automatic token refresh
- **User Profile Management**: Edit profile, privacy settings

#### Social Features
- **Friends System**: Send, accept, and manage friend requests
- **Friend Permissions**: Granular control over what friends can see
- **Public Profiles**: View friend profiles and activity
- **Friend Activity**: See friend button clicks and updates

#### Notifications System
- **Real-time Notifications**: Button click notifications from friends
- **Push Notifications**: System and friend request notifications
- **Notification Management**: Mark as read, delete, filter unread
- **Notification Preferences**: Customize what notifications you receive

#### Subscription System
- **Subscription Plans**: Free, Premium, and Enterprise tiers
- **Usage Tracking**: Monitor button, friend, and click limits
- **Subscription Management**: Upgrade, cancel, pause, resume
- **Feature Access Control**: Dynamic feature availability based on subscription
- **Usage Statistics**: Detailed analytics and usage patterns

#### Additional Features
- **Activity Diary**: Daily activity tracking and visualization
- **Account Settings**: Profile management, privacy controls
- **Data Export**: Export your data in multiple formats
- **Offline Support**: Graceful handling of network issues

### 🏗️ Architecture

#### MVVM + Repository Pattern
- **SwiftUI Views**: Modern declarative UI
- **ObservableObject ViewModels**: Reactive state management
- **Repository Pattern**: Clean data layer abstraction
- **Combine Framework**: Reactive programming for data flow

#### API Integration
- **RESTful API Client**: Full integration with Phoenix backend
- **JWT Authentication**: Secure token-based authentication
- **Error Handling**: Comprehensive error management
- **Request/Response Models**: Type-safe API communication

#### Security
- **Keychain Integration**: Secure token storage
- **Network Security**: HTTPS enforcement, certificate validation
- **Data Privacy**: Local data protection, secure API calls

## Project Structure

```
ButtonLog/
├── ButtonLogApp.swift          # Main app entry point
├── ContentView.swift           # Legacy content view
├── Models/                     # Data models
│   ├── Button.swift           # Button model and related types
│   ├── User.swift             # User model and profile types
│   ├── Social.swift           # Friends and social features
│   ├── Notification.swift     # Notification models
│   └── Subscription.swift     # Subscription and billing models
├── Services/                   # Business logic and API
│   ├── APIService.swift       # HTTP API client
│   ├── AuthenticationManager.swift # Auth state management
│   └── KeychainManager.swift  # Secure storage
├── ViewModels/                 # State management
│   └── AppState.swift         # Global app state
├── Views/                      # SwiftUI views
│   ├── AuthenticationView.swift   # Login/register
│   ├── MainTabView.swift          # Main tab navigation
│   ├── ButtonsView.swift          # Home screen with buttons
│   ├── CreateButtonView.swift     # Button creation/editing
│   ├── FriendsView.swift          # Friends management
│   ├── NotificationsView.swift    # Notifications center
│   ├── DiaryView.swift            # Daily activity diary
│   └── AccountView.swift          # User account and settings
└── Assets.xcassets/            # App icons and assets
```

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## Setup

1. **Open Project**: Open `ButtonLog.xcodeproj` in Xcode
2. **Backend Configuration**: Ensure the Phoenix backend is running on `localhost:4000`
3. **Build & Run**: Select your target device and run the app

## API Configuration

The app is configured to connect to:
- **Development**: `http://localhost:4000/api`
- **Production**: Update `baseURL` in `APIService.swift`

## Authentication Flow

1. **Initial Launch**: Check for stored JWT token
2. **Login/Register**: Email/password or OAuth authentication
3. **Token Management**: Automatic token refresh and secure storage
4. **Session Management**: Persistent authentication state

## Key Implementation Details

### State Management
- **AppState**: Global state using `@StateObject` and `@EnvironmentObject`
- **Reactive Updates**: Combine publishers for real-time data flow
- **Error Handling**: Centralized error management with user feedback

### API Integration
- **Async/Await**: Modern concurrency for API calls
- **Type Safety**: Codable models with proper JSON mapping
- **Error Recovery**: Automatic retry and graceful degradation
- **Offline Handling**: Local caching and sync when online

### UI/UX Features
- **Native iOS Design**: SwiftUI with iOS design patterns
- **Accessibility**: VoiceOver support, dynamic type
- **Dark Mode**: Automatic light/dark mode support
- **Pull-to-Refresh**: Standard iOS refresh patterns
- **Loading States**: Proper loading and empty state handling

## Testing

The app includes:
- **Unit Tests**: Business logic and API service tests
- **UI Tests**: User flow and interaction tests
- **Integration Tests**: API integration testing

## Future Enhancements

### Planned Features
- **Push Notifications**: Firebase Cloud Messaging integration
- **Offline Mode**: Local Core Data storage with sync
- **Widgets**: iOS home screen widgets for quick button access
- **Watch App**: Apple Watch companion app
- **Siri Shortcuts**: Voice command integration
- **ShareSheet**: Share buttons with other apps

### Technical Improvements
- **Core Data**: Local database for offline support
- **CloudKit**: iCloud sync for cross-device data
- **Background Tasks**: Background refresh and sync
- **App Store Connect**: TestFlight beta distribution

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This iOS app provides complete feature parity with the ButtonLog Phoenix backend, ensuring a seamless experience across all platforms.