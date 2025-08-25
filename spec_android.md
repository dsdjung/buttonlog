# Android Client Technical Specification (Kotlin + Phoenix API)

## Overview

**This is a separate native Android application that consumes the unified Phoenix backend API.** The Android app connects to the same Phoenix application that serves the web UI, ensuring consistent data and behavior.

## Technology Stack

### Core Framework
- **Kotlin 1.9+**: Modern programming language for Android
- **Jetpack Compose**: Declarative UI toolkit
- **MVVM Architecture**: Model-View-ViewModel pattern
- **Hilt**: Dependency injection framework

### Networking & Real-time
- **Retrofit + OkHttp + Moshi**: REST API client for Phoenix backend
- **Phoenix Channels**: WebSocket client for real-time updates via Socket.io
- **Kotlin Coroutines + Flow**: Asynchronous programming

### Data Management
- **Room Database**: Local SQLite database with offline support
- **DataStore**: Key-value storage for preferences
- **Hilt**: Dependency injection for data sources

### UI & UX
- **Material Design 3**: Modern Material Design components
- **Jetpack Compose**: Declarative UI framework
- **Coil**: Image loading and caching
- **Lottie**: Animation support

### Notifications & Background
- **Firebase Cloud Messaging (FCM)**: Push notifications
- **WorkManager**: Background task scheduling
- **AlarmManager**: Precise timing for button reminders

## Application Architecture

### MVVM Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │   UI Layer  │ │  ViewModel  │ │   State     │         │
│  │ (Compose)   │ │             │ │ Management  │         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │ Use Cases   │ │ Repositories│ │   Models    │         │
│  │             │ │             │ │             │         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │   Remote    │ │    Local    │ │   Cache     │         │
│  │   API       │ │  Database   │ │             │         │
│  └─────────────┘ └─────────────┘ └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### Package Structure

```
com.buttonlog.app/
├── data/                    # Data layer
│   ├── api/                # Phoenix API endpoints
│   ├── database/           # Room database
│   ├── local/              # Local data sources
│   ├── remote/             # Remote data sources
│   └── repository/         # Repository implementations
├── domain/                  # Domain layer
│   ├── model/              # Data models
│   ├── repository/          # Repository interfaces
│   └── usecase/            # Business logic use cases
├── presentation/            # Presentation layer
│   ├── ui/                 # UI components
│   │   ├── screens/        # Screen composables
│   │   ├── components/     # Reusable components
│   │   └── theme/          # App theme and styling
│   ├── viewmodel/          # ViewModels
│   └── navigation/         # Navigation components
├── di/                      # Dependency injection
├── service/                 # Background services
└── util/                    # Utility classes
```

## Core Implementation

### 1. Application Class

**File**: `app/src/main/java/com/buttonlog/app/ButtonLogApplication.kt`

```kotlin
@HiltAndroidApp
class ButtonLogApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
        
        // Initialize Phoenix Channels
        PhoenixChannelsManager.initialize(this)
        
        // Initialize WorkManager
        WorkManager.initialize(
            this,
            Configuration.Builder()
                .setMinimumLoggingLevel(if (BuildConfig.DEBUG) Log.DEBUG else Log.ERROR)
                .build()
        )
    }
}
```

### 2. Phoenix Channels Integration

**File**: `app/src/main/java/com/buttonlog/app/data/remote/PhoenixChannelsManager.kt`

```kotlin
@Singleton
class PhoenixChannelsManager @Inject constructor(
    private val context: Context,
    private val authManager: AuthManager
) {
    private var socket: Socket? = null
    private val channels = mutableMapOf<String, Channel>()
    private val _connectionStatus = MutableStateFlow(ConnectionStatus.Disconnected)
    val connectionStatus: StateFlow<ConnectionStatus> = _connectionStatus.asStateFlow()
    
    fun initialize(context: Context) {
        // Initialize Socket.io client for Phoenix Channels
        val options = IO.Options().apply {
            auth = mapOf("token" to authManager.getAuthToken())
            transports = arrayOf("websocket", "polling")
        }
        
        socket = IO.socket("https://your-phoenix-backend.com/socket", options)
        setupSocketListeners()
    }
    
    private fun setupSocketListeners() {
        socket?.apply {
            on(Socket.EVENT_CONNECT) {
                _connectionStatus.value = ConnectionStatus.Connected
                Log.d("PhoenixChannels", "Connected to Phoenix backend")
            }
            
            on(Socket.EVENT_DISCONNECT) {
                _connectionStatus.value = ConnectionStatus.Disconnected
                Log.d("PhoenixChannels", "Disconnected from Phoenix backend")
            }
            
            on(Socket.EVENT_CONNECT_ERROR) { args ->
                _connectionStatus.value = ConnectionStatus.Error(args.firstOrNull()?.toString() ?: "Unknown error")
                Log.e("PhoenixChannels", "Connection error: ${args.firstOrNull()}")
            }
        }
        
        socket?.connect()
    }
    
    fun joinChannel(channelName: String, params: Map<String, Any> = emptyMap()): Channel? {
        val channel = socket?.channel(channelName, params)
        channel?.let {
            channels[channelName] = it
            setupChannelListeners(it, channelName)
        }
        return channel
    }
    
    private fun setupChannelListeners(channel: Channel, channelName: String) {
        channel.on("phx_reply") { args ->
            Log.d("PhoenixChannels", "Channel $channelName reply: $args")
        }
        
        channel.on("phx_error") { args ->
            Log.e("PhoenixChannels", "Channel $channelName error: $args")
        }
    }
    
    fun leaveChannel(channelName: String) {
        channels[channelName]?.leave()
        channels.remove(channelName)
    }
    
    fun disconnect() {
        channels.values.forEach { it.leave() }
        channels.clear()
        socket?.disconnect()
        socket = null
    }
    
    sealed class ConnectionStatus {
        object Connected : ConnectionStatus()
        object Disconnected : ConnectionStatus()
        data class Error(val message: String) : ConnectionStatus()
    }
}
```

### 3. Data Models

**File**: `app/src/main/java/com/buttonlog/app/domain/model/Button.kt`

```kotlin
@Entity(tableName = "buttons")
data class Button(
    @PrimaryKey
    val id: String,
    val name: String,
    val description: String?,
    val type: ButtonType,
    val icon: String?,
    val color: String,
    val isActive: Boolean,
    val notificationsEnabled: Boolean,
    val autoStopEnabled: Boolean,
    val calendarSyncEnabled: Boolean,
    val userId: String,
    val createdAt: Long,
    val updatedAt: Long
) {
    enum class ButtonType {
        INSTANT, TIMED, STATE
    }
}

@Entity(tableName = "button_clicks")
data class ButtonClick(
    @PrimaryKey
    val id: String,
    val buttonId: String,
    val userId: String,
    val clickedAt: Long,
    val duration: Int?,
    val locationLat: Double?,
    val locationLng: Double?,
    val device: String,
    val platform: String,
    val createdAt: Long
) {
    enum class Platform {
        WEB, ANDROID, IPHONE
    }
}

@Entity(tableName = "users")
data class User(
    @PrimaryKey
    val id: String,
    val email: String,
    val username: String,
    val displayName: String,
    val avatar: String?,
    val timezone: String,
    val language: String,
    val subscriptionTier: String,
    val subscriptionExpiresAt: Long?,
    val createdAt: Long,
    val updatedAt: Long
)
```

### 4. Repository Implementation

**File**: `app/src/main/java/com/buttonlog/app/data/repository/ButtonRepositoryImpl.kt`

```kotlin
@Singleton
class ButtonRepositoryImpl @Inject constructor(
    private val buttonApi: ButtonApi,
    private val buttonDao: ButtonDao,
    private val buttonClickDao: ButtonClickDao,
    private val phoenixChannelsManager: PhoenixChannelsManager,
    private val networkManager: NetworkManager
) : ButtonRepository {
    
    override suspend fun getButtons(): Flow<List<Button>> {
        return buttonDao.getAllButtons()
    }
    
    override suspend fun createButton(button: Button): Result<Button> {
        return try {
            if (networkManager.isNetworkAvailable()) {
                // Create button on server
                val response = buttonApi.createButton(button.toCreateRequest())
                if (response.isSuccessful) {
                    val createdButton = response.body()!!
                    buttonDao.insertButton(createdButton)
                    Result.success(createdButton)
                } else {
                    Result.failure(Exception("Failed to create button"))
                }
            } else {
                // Store locally for later sync
                buttonDao.insertButton(button.copy(id = UUID.randomUUID().toString()))
                Result.success(button)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun clickButton(buttonId: String): Result<ButtonClick> {
        return try {
            val click = ButtonClick(
                id = UUID.randomUUID().toString(),
                buttonId = buttonId,
                userId = getCurrentUserId(),
                clickedAt = System.currentTimeMillis(),
                device = Build.MODEL,
                platform = "android",
                createdAt = System.currentTimeMillis()
            )
            
            if (networkManager.isNetworkAvailable()) {
                // Send click to server via Phoenix Channels
                val channel = phoenixChannelsManager.joinChannel("button:$buttonId")
                channel?.emit("click", mapOf("button_id" to buttonId))
                
                // Also store locally
                buttonClickDao.insertButtonClick(click)
                Result.success(click)
            } else {
                // Store locally for later sync
                buttonClickDao.insertButtonClick(click)
                Result.success(click)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun syncOfflineData() {
        if (!networkManager.isNetworkAvailable()) return
        
        // Sync offline buttons
        val offlineButtons = buttonDao.getOfflineButtons()
        offlineButtons.forEach { button ->
            try {
                buttonApi.createButton(button.toCreateRequest())
                buttonDao.markAsSynced(button.id)
            } catch (e: Exception) {
                Log.e("ButtonRepository", "Failed to sync button: ${button.id}", e)
            }
        }
        
        // Sync offline clicks
        val offlineClicks = buttonClickDao.getOfflineClicks()
        offlineClicks.forEach { click ->
            try {
                buttonApi.recordClick(click.toClickRequest())
                buttonClickDao.markAsSynced(click.id)
            } catch (e: Exception) {
                Log.e("ButtonRepository", "Failed to sync click: ${click.id}", e)
            }
        }
    }
    
    private fun getCurrentUserId(): String {
        // Get from AuthManager
        return "current_user_id"
    }
}
```

### 5. ViewModel Implementation

**File**: `app/src/main/java/com/buttonlog/app/presentation/viewmodel/ButtonsViewModel.kt`

```kotlin
@HiltViewModel
class ButtonsViewModel @Inject constructor(
    private val buttonRepository: ButtonRepository,
    private val phoenixChannelsManager: PhoenixChannelsManager
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ButtonsUiState())
    val uiState: StateFlow<ButtonsUiState> = _uiState.asStateFlow()
    
    private val _connectionStatus = phoenixChannelsManager.connectionStatus
    val connectionStatus: StateFlow<PhoenixChannelsManager.ConnectionStatus> = _connectionStatus
    
    init {
        loadButtons()
        observePhoenixChannels()
    }
    
    private fun loadButtons() {
        viewModelScope.launch {
            buttonRepository.getButtons()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message
                    )
                }
                .collect { buttons ->
                    _uiState.value = _uiState.value.copy(
                        buttons = buttons,
                        isLoading = false,
                        error = null
                    )
                }
        }
    }
    
    private fun observePhoenixChannels() {
        viewModelScope.launch {
            _connectionStatus.collect { status ->
                when (status) {
                    is PhoenixChannelsManager.ConnectionStatus.Connected -> {
                        // Reconnect to button channels
                        _uiState.value.buttons.forEach { button ->
                            phoenixChannelsManager.joinChannel("button:${button.id}")
                        }
                    }
                    is PhoenixChannelsManager.ConnectionStatus.Disconnected -> {
                        // Handle disconnection
                    }
                    is PhoenixChannelsManager.ConnectionStatus.Error -> {
                        _uiState.value = _uiState.value.copy(
                            error = "Connection error: ${status.message}"
                        )
                    }
                }
            }
        }
    }
    
    fun createButton(name: String, type: Button.ButtonType, color: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            val button = Button(
                id = UUID.randomUUID().toString(),
                name = name,
                description = null,
                type = type,
                icon = "star",
                color = color,
                isActive = true,
                notificationsEnabled = true,
                autoStopEnabled = false,
                calendarSyncEnabled = false,
                userId = "current_user_id",
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis()
            )
            
            when (val result = buttonRepository.createButton(button)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(isLoading = false)
                    // Button will be added to the list via Flow
                }
                is Result.Failure -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = result.exceptionOrNull()?.message ?: "Unknown error"
                    )
                }
            }
        }
    }
    
    fun clickButton(buttonId: String) {
        viewModelScope.launch {
            when (val result = buttonRepository.clickButton(buttonId)) {
                is Result.Success -> {
                    // Click recorded successfully
                    // Real-time updates will come via Phoenix Channels
                }
                is Result.Failure -> {
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to record click: ${result.exceptionOrNull()?.message}"
                    )
                }
            }
        }
    }
    
    fun deleteButton(buttonId: String) {
        viewModelScope.launch {
            buttonRepository.deleteButton(buttonId)
            // Button will be removed from the list via Flow
        }
    }
    
    fun syncOfflineData() {
        viewModelScope.launch {
            buttonRepository.syncOfflineData()
        }
    }
    
    data class ButtonsUiState(
        val buttons: List<Button> = emptyList(),
        val isLoading: Boolean = true,
        val error: String? = null
    )
}
```

### 6. UI Implementation with Jetpack Compose

**File**: `app/src/main/java/com/buttonlog/app/presentation/ui/screens/buttons/ButtonsScreen.kt`

```kotlin
@Composable
fun ButtonsScreen(
    viewModel: ButtonsViewModel = hiltViewModel(),
    onNavigateToButton: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val connectionStatus by viewModel.connectionStatus.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "My Buttons",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            
            Button(
                onClick = { /* Show create button dialog */ },
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add Button"
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("New Button")
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Connection Status
        ConnectionStatusIndicator(connectionStatus)
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Buttons Grid
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (uiState.buttons.isEmpty()) {
            EmptyState()
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(uiState.buttons) { button ->
                    ButtonCard(
                        button = button,
                        onButtonClick = { viewModel.clickButton(button.id) },
                        onButtonEdit = { onNavigateToButton(button.id) },
                        onButtonDelete = { viewModel.deleteButton(button.id) }
                    )
                }
            }
        }
        
        // Error Display
        uiState.error?.let { error ->
            Spacer(modifier = Modifier.height(16.dp))
            ErrorMessage(
                message = error,
                onDismiss = { /* Clear error */ }
            )
        }
    }
}

@Composable
fun ButtonCard(
    button: Button,
    onButtonClick: () -> Unit,
    onButtonEdit: () -> Unit,
    onButtonDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // Button Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                // Button Icon and Info
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .background(
                                color = Color(android.graphics.Color.parseColor(button.color)),
                                shape = CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = button.icon ?: "★",
                            color = Color.White,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Column {
                        Text(
                            text = button.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = button.type.name.lowercase().capitalize(),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                
                // Action Buttons
                Row {
                    IconButton(onClick = onButtonEdit) {
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = "Edit Button",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    IconButton(onClick = onButtonDelete) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Delete Button",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Button Description
            button.description?.let { description ->
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            // Button Features
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (button.notificationsEnabled) {
                    FeatureChip(
                        text = "Notifications",
                        backgroundColor = MaterialTheme.colorScheme.primaryContainer,
                        textColor = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
                
                if (button.autoStopEnabled) {
                    FeatureChip(
                        text = "Auto-stop",
                        backgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                        textColor = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Click Button
            Button(
                onClick = onButtonClick,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text("Click!")
            }
        }
    }
}

@Composable
fun ConnectionStatusIndicator(
    connectionStatus: PhoenixChannelsManager.ConnectionStatus
) {
    val (backgroundColor, textColor, text) = when (connectionStatus) {
        is PhoenixChannelsManager.ConnectionStatus.Connected -> {
            Triple(
                MaterialTheme.colorScheme.primaryContainer,
                MaterialTheme.colorScheme.onPrimaryContainer,
                "Connected"
            )
        }
        is PhoenixChannelsManager.ConnectionStatus.Disconnected -> {
            Triple(
                MaterialTheme.colorScheme.errorContainer,
                MaterialTheme.colorScheme.onErrorContainer,
                "Disconnected"
            )
        }
        is PhoenixChannelsManager.ConnectionStatus.Error -> {
            Triple(
                MaterialTheme.colorScheme.errorContainer,
                MaterialTheme.colorScheme.onErrorContainer,
                "Connection Error"
            )
        }
    }
    
    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(8.dp),
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(
                        color = textColor,
                        shape = CircleShape
                    )
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                color = textColor,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
fun FeatureChip(
    text: String,
    backgroundColor: Color,
    textColor: Color
) {
    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(16.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = textColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}
```

## Enhanced Mobile Features (Simplified)

### Simple Connection Status

**File**: `app/src/main/java/com/buttonlog/app/service/ConnectionStatusManager.kt`

```kotlin
@Singleton
class ConnectionStatusManager @Inject constructor(
    private val networkManager: NetworkManager
) {
    private val _isConnected = MutableStateFlow(true)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()
    
    private val _isOnline = MutableStateFlow(true)
    val isOnline: StateFlow<Boolean> = _isOnline.asStateFlow()
    
    init {
        observeNetworkChanges()
    }
    
    private fun observeNetworkChanges() {
        networkManager.networkState
            .onEach { networkState ->
                _isOnline.value = networkState.isConnected
            }
            .launchIn(CoroutineScope(Dispatchers.IO))
    }
    
    fun updateConnectionStatus(connected: Boolean) {
        _isConnected.value = connected
    }
}
```

### Simple Notification Service

**File**: `app/src/main/java/com/buttonlog/app/service/NotificationService.kt`

```kotlin
@Singleton
class NotificationService @Inject constructor(
    private val context: Context
) {
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    init {
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val buttonClickChannel = NotificationChannel(
                CHANNEL_BUTTON_CLICK,
                "Button Clicks",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for button clicks"
                enableLights(true)
                lightColor = Color.BLUE
            }
            
            val friendActivityChannel = NotificationChannel(
                CHANNEL_FRIEND_ACTIVITY,
                "Friend Activity",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for friend activities"
                enableLights(true)
                lightColor = Color.GREEN
            }
            
            notificationManager.createNotificationChannels(
                listOf(buttonClickChannel, friendActivityChannel)
            )
        }
    }
    
    fun showButtonClickNotification(buttonName: String, friendName: String? = null) {
        val title = if (friendName != null) {
            "$friendName clicked $buttonName"
        } else {
            "Button clicked: $buttonName"
        }
        
        val notification = NotificationCompat.Builder(context, CHANNEL_BUTTON_CLICK)
            .setContentTitle(title)
            .setContentText("Tap to view details")
            .setSmallIcon(R.drawable.ic_notification)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        
        notificationManager.notify(
            System.currentTimeMillis().toInt(),
            notification
        )
    }
    
    companion object {
        const val CHANNEL_BUTTON_CLICK = "button_click"
        const val CHANNEL_FRIEND_ACTIVITY = "friend_activity"
    }
}
```

### Simple Offline Support

**File**: `app/src/main/java/com/buttonlog/app/service/OfflineQueueManager.kt`

```kotlin
@Singleton
class OfflineQueueManager @Inject constructor(
    private val context: Context,
    private val workManager: WorkManager
) {
    
    fun queueButtonClick(buttonId: String, metadata: Map<String, Any>) {
        val data = workDataOf(
            "button_id" to buttonId,
            "metadata" to metadata.toString(),
            "timestamp" to System.currentTimeMillis()
        )
        
        val offlineWork = OneTimeWorkRequestBuilder<OfflineSyncWorker>()
            .setInputData(data)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()
        
        workManager.enqueue(offlineWork)
    }
    
    fun queueButtonCreation(buttonData: Map<String, Any>) {
        val data = workDataOf(
            "action" to "create_button",
            "button_data" to buttonData.toString()
        )
        
        val offlineWork = OneTimeWorkRequestBuilder<OfflineSyncWorker>()
            .setInputData(data)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()
        
        workManager.enqueue(offlineWork)
    }
}

class OfflineSyncWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    
    override suspend fun doWork(): Result {
        return try {
            val action = inputData.getString("action")
            
            when (action) {
                "create_button" -> {
                    // Sync button creation
                    val buttonData = inputData.getString("button_data")
                    // Implementation for syncing button creation
                }
                else -> {
                    // Sync button click
                    val buttonId = inputData.getString("button_id")
                    val metadata = inputData.getString("metadata")
                    // Implementation for syncing button click
                }
            }
            
            Result.success()
        } catch (e: Exception) {
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}
```

## Testing Strategy

### Unit Tests

```kotlin
@RunWith(MockitoJUnitRunner::class)
class ButtonsViewModelTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    @Mock
    private lateinit var buttonRepository: ButtonRepository
    
    @Mock
    private lateinit var phoenixChannelsManager: PhoenixChannelsManager
    
    private lateinit var viewModel: ButtonsViewModel
    
    @Before
    fun setup() {
        viewModel = ButtonsViewModel(buttonRepository, phoenixChannelsManager)
    }
    
    @Test
    fun `when createButton is called, button is created successfully`() = runTest {
        // Given
        val button = Button(
            id = "test_id",
            name = "Test Button",
            type = Button.ButtonType.INSTANT,
            color = "#FF0000",
            userId = "user_id"
        )
        
        whenever(buttonRepository.createButton(any())).thenReturn(Result.success(button))
        
        // When
        viewModel.createButton("Test Button", Button.ButtonType.INSTANT, "#FF0000")
        
        // Then
        verify(buttonRepository).createButton(any())
    }
    
    @Test
    fun `when clickButton is called, click is recorded successfully`() = runTest {
        // Given
        val click = ButtonClick(
            id = "click_id",
            buttonId = "button_id",
            userId = "user_id",
            clickedAt = System.currentTimeMillis(),
            device = "test_device",
            platform = "android"
        )
        
        whenever(buttonRepository.clickButton(any())).thenReturn(Result.success(click))
        
        // When
        viewModel.clickButton("button_id")
        
        // Then
        verify(buttonRepository).clickButton("button_id")
    }
}
```

### Integration Tests

```kotlin
@RunWith(AndroidJUnit4::class)
class ButtonRepositoryIntegrationTest {
    
    private lateinit var database: ButtonLogDatabase
    private lateinit var buttonDao: ButtonDao
    private lateinit var buttonClickDao: ButtonClickDao
    private lateinit var repository: ButtonRepositoryImpl
    
    @Before
    fun createDb() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(
            context, ButtonLogDatabase::class.java
        ).build()
        buttonDao = database.buttonDao()
        buttonClickDao = database.buttonClickDao()
        
        repository = ButtonRepositoryImpl(
            mock(), buttonDao, buttonClickDao, mock(), mock()
        )
    }
    
    @After
    fun closeDb() {
        database.close()
    }
    
    @Test
    fun insertAndRetrieveButton() = runTest {
        // Given
        val button = Button(
            id = "test_id",
            name = "Test Button",
            type = Button.ButtonType.INSTANT,
            color = "#FF0000",
            userId = "user_id"
        )
        
        // When
        repository.createButton(button)
        val buttons = repository.getButtons().first()
        
        // Then
        assertThat(buttons).contains(button)
    }
}
```

## Performance Considerations

### Database Optimization

- **Room Indexing**: Strategic database indexes for common queries
- **Query Optimization**: Efficient Room queries with proper joins
- **Background Operations**: Database operations on background threads

### Network Optimization

- **Phoenix Channels**: Efficient WebSocket connection management
- **Request Batching**: Batch multiple API requests when possible
- **Caching**: Implement proper caching strategies for API responses

### UI Performance

- **Compose Optimization**: Efficient Compose recomposition
- **Lazy Loading**: Lazy loading for large lists
- **Image Optimization**: Efficient image loading and caching

This Android specification provides a comprehensive foundation for building the ButtonLog Android app with modern Android development practices, Phoenix Channels integration, and robust offline support.
