# ButtonLog Mobile Apps

This directory contains the iOS and Android mobile applications for ButtonLog, providing feature parity with the Phoenix backend web application.

## 🏗️ Architecture Overview

Both mobile apps follow modern mobile development patterns:

- **iOS**: SwiftUI + Combine + MVVM
- **Android**: Jetpack Compose + Kotlin Coroutines + MVVM + Repository Pattern

## 📱 Feature Parity

The mobile apps implement all core features from the backend:

### ✅ Core Features
- **Button Management**: Create, edit, delete, and click buttons
- **Button Types**: Instant, Timed, and State buttons
- **Real-time Updates**: Live button state changes
- **User Authentication**: Login, registration, and profile management
- **Social Features**: Friends, permissions, and activity sharing
- **Notifications**: Push notifications for button activities
- **Search & Filtering**: Find buttons by name or description

### 🔄 Backend Integration
- **REST API**: Full integration with Phoenix backend endpoints
- **Real-time**: Phoenix Channels support (planned)
- **Authentication**: JWT token-based auth
- **Data Sync**: Automatic synchronization with backend

## 📱 iOS App (SwiftUI)

### 🏗️ Project Structure
```
iphone/ButtonLog/
├── ButtonLogApp.swift          # Main app entry point
├── Views/                      # UI Components
│   ├── ContentView.swift      # Main content with bottom navigation
│   ├── ButtonsView.swift      # Buttons list and search
│   └── CreateButtonView.swift # Button creation form
├── Models/                     # Data Models
│   ├── Button.swift           # Button data structure
│   └── User.swift             # User data structure
├── Services/                   # API Layer
│   └── APIService.swift       # HTTP client for backend
└── Managers/                   # Business Logic
    └── ButtonManager.swift    # Button operations manager
```

### 🚀 Key Features
- **Bottom Navigation**: Home, Friends, Notifications, Account
- **Prominent + Button**: Centered floating action button for creating buttons
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Async/Await**: Modern concurrency patterns

### 🛠️ Dependencies
- **SwiftUI**: Native iOS UI framework
- **Combine**: Reactive programming
- **Foundation**: Core iOS functionality

## 🤖 Android App (Jetpack Compose)

### 🏗️ Project Structure
```
android/app/src/main/java/com/buttonlog/app/
├── ButtonLogApplication.kt     # Main application class
├── MainActivity.kt            # Main activity with navigation
├── ui/                        # User Interface
│   ├── screens/               # Screen composables
│   │   └── ButtonsScreen.kt   # Main buttons screen
│   ├── components/            # Reusable components
│   │   └── ButtonCard.kt      # Button display component
│   └── viewmodels/            # ViewModels
│       └── ButtonsViewModel.kt # Buttons screen logic
├── data/                      # Data Layer
│   ├── api/                   # API Interface
│   │   └── APIService.kt      # Retrofit API service
│   ├── model/                 # Data Models
│   │   ├── Button.kt          # Button data structure
│   │   └── User.kt            # User data structure
│   └── repository/            # Data Repository
│       └── ButtonRepository.kt # Button data operations
```

### 🚀 Key Features
- **Bottom Navigation**: Material 3 design with 4 main tabs
- **Prominent + Button**: Floating action button above navigation
- **Jetpack Compose**: Modern declarative UI toolkit
- **MVVM Architecture**: Clean separation of concerns
- **Repository Pattern**: Data abstraction layer

### 🛠️ Dependencies
- **Jetpack Compose**: Modern Android UI toolkit
- **Hilt**: Dependency injection
- **Retrofit**: HTTP client for API calls
- **Room**: Local database for caching
- **Coroutines**: Asynchronous programming
- **Material 3**: Latest Material Design components

## 🔧 Setup & Development

### iOS Development
1. **Prerequisites**: Xcode 15+, iOS 17.0+
2. **Open Project**: Open `iphone/ButtonLog.xcodeproj` in Xcode
3. **Build & Run**: Select target device and run

### Android Development
1. **Prerequisites**: Android Studio Hedgehog+, Android SDK 34
2. **Open Project**: Open `android/` folder in Android Studio
3. **Sync Gradle**: Let Gradle sync dependencies
4. **Build & Run**: Select target device and run

## 🌐 Backend Configuration

Both apps are configured to connect to the Phoenix backend:

- **Development**: `http://localhost:4000/api` (iOS), `http://10.0.2.2:4000/api` (Android)
- **Production**: Update API base URLs in respective configuration files

## 📱 Navigation Structure

### Bottom Navigation Tabs
1. **Home** - Button list and management
2. **Friends** - Social connections and permissions
3. **Notifications** - Activity and friend notifications
4. **Account** - User profile and settings

### Prominent + Button
- **Position**: Centered above bottom navigation
- **Function**: Create new buttons
- **Design**: Large, prominent, always visible

## 🔐 Authentication Flow

1. **Login/Register**: Email/password authentication
2. **JWT Tokens**: Secure API communication
3. **Token Refresh**: Automatic token renewal
4. **Secure Storage**: Encrypted credential storage

## 📊 Data Models

### Button Model
```swift/kotlin
struct Button {
    let id: String
    let name: String
    let description: String?
    let type: ButtonType        // instant, timed, state
    let icon: String
    let color: String
    let isActive: Bool
    let currentState: ButtonState // idle, active
    let notificationsEnabled: Bool
    let autoStopEnabled: Bool
    let calendarSyncEnabled: Bool
}
```

### User Model
```swift/kotlin
struct User {
    let id: String
    let email: String
    let username: String
    let displayName: String
    let subscriptionTier: SubscriptionTier
    let profileVisibility: ProfileVisibility
    let activityVisibility: ActivityVisibility
}
```

## 🚀 Future Enhancements

### Planned Features
- **Phoenix Channels**: Real-time WebSocket communication
- **Push Notifications**: Firebase Cloud Messaging integration
- **Offline Support**: Local data caching and sync
- **Dark Mode**: Theme switching support
- **Accessibility**: VoiceOver and TalkBack support
- **Widgets**: iOS and Android home screen widgets

### Technical Improvements
- **Unit Testing**: Comprehensive test coverage
- **UI Testing**: Automated UI testing
- **Performance**: Memory and battery optimization
- **Security**: Certificate pinning and encryption
- **Analytics**: User behavior tracking

## 🐛 Troubleshooting

### Common Issues

#### iOS
- **Build Errors**: Ensure Xcode 15+ and iOS 17.0+
- **Simulator Issues**: Reset simulator or use physical device
- **Dependency Issues**: Clean build folder and rebuild

#### Android
- **Gradle Sync**: Invalidate caches and restart
- **Build Errors**: Clean project and rebuild
- **Emulator Issues**: Use physical device or different emulator

### Backend Connection
- **Network Errors**: Verify backend is running on correct port
- **Authentication**: Check JWT token validity
- **API Endpoints**: Verify endpoint URLs match backend

## 📚 Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)
- [Phoenix Framework](https://hexdocs.pm/phoenix/overview.html)

### Development Tools
- **iOS**: Xcode, iOS Simulator, Instruments
- **Android**: Android Studio, Android Emulator, Layout Inspector

## 🤝 Contributing

1. **Fork** the repository
2. **Create** feature branch
3. **Implement** changes with tests
4. **Submit** pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: Both mobile apps are designed to work seamlessly with the Phoenix backend. Ensure the backend is running and properly configured before testing mobile functionality.

