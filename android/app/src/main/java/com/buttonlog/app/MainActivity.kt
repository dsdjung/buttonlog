package com.buttonlog.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.repository.ButtonRepository
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.ui.screens.AccountScreen
import com.buttonlog.app.ui.screens.ButtonHistoryScreen
import com.buttonlog.app.ui.screens.ButtonsScreen
import com.buttonlog.app.ui.screens.DiaryScreen
import com.buttonlog.app.ui.screens.CreateButtonScreen
import com.buttonlog.app.ui.screens.CreateGiftButtonScreen
import com.buttonlog.app.ui.screens.CreatedGiftButtonsScreen
import com.buttonlog.app.ui.screens.EditButtonScreen
import com.buttonlog.app.ui.screens.FriendDetailScreen
import com.buttonlog.app.ui.screens.FriendsScreen
import com.buttonlog.app.ui.screens.LoginScreen
import com.buttonlog.app.ui.screens.NotificationsScreen
import com.buttonlog.app.ui.screens.NotificationNavigation
import com.buttonlog.app.ui.screens.SupportScreen
import com.buttonlog.app.ui.screens.SupportTicketScreen
import com.buttonlog.app.ui.screens.CreateTicketScreen
import com.buttonlog.app.ui.screens.TeamsScreen
import com.buttonlog.app.ui.screens.OrganizationsScreen
import com.buttonlog.app.ui.screens.SubscriptionScreen
import com.buttonlog.app.ui.screens.OnboardingScreen
import com.buttonlog.app.ui.screens.EditProfileScreen
import com.buttonlog.app.ui.screens.PrivacySettingsScreen
import com.buttonlog.app.ui.screens.NotificationSettingsScreen
import com.buttonlog.app.ui.screens.PasswordChangeScreen
import com.buttonlog.app.ui.screens.DataExportScreen
import com.buttonlog.app.ui.screens.AboutScreen
import com.buttonlog.app.ui.screens.WebhookSettingsScreen
import com.buttonlog.app.ui.viewmodels.ButtonsViewModel
import com.buttonlog.app.ui.viewmodels.FriendsViewModel
import com.buttonlog.app.ui.viewmodels.SupportViewModel
import com.buttonlog.app.ui.theme.ButtonLogTheme
import com.buttonlog.app.ui.viewmodels.AuthViewModel
import com.buttonlog.app.ui.viewmodels.NotificationsViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    // Store pending invite code for deep links
    private var pendingInviteCode: String? = null

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            android.util.Log.d("MainActivity", "Notification permission granted")
        } else {
            android.util.Log.w("MainActivity", "Notification permission denied")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Request notification permission for Android 13+
        requestNotificationPermission()

        // Handle deep link on initial launch
        handleDeepLink(intent)

        setContent {
            ButtonLogTheme {
                val authViewModel: AuthViewModel = hiltViewModel()
                val isLoggedIn by authViewModel.isLoggedIn.collectAsState()
                val onboardingCompleted by authViewModel.onboardingCompleted.collectAsState()

                // Track pending invite code
                var localPendingInviteCode by remember { mutableStateOf(pendingInviteCode) }

                // Update local state when activity gets new pending code
                LaunchedEffect(pendingInviteCode) {
                    localPendingInviteCode = pendingInviteCode
                }

                if (isLoggedIn) {
                    if (onboardingCompleted) {
                        MainScreen(
                            onLogout = { authViewModel.logout() },
                            pendingInviteCode = localPendingInviteCode,
                            onInviteCodeConsumed = {
                                pendingInviteCode = null
                                localPendingInviteCode = null
                            }
                        )
                    } else {
                        OnboardingScreen(
                            onComplete = { authViewModel.completeOnboarding() }
                        )
                    }
                } else {
                    LoginScreen(viewModel = authViewModel)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        val data = intent?.data ?: return

        // Handle buttonlog://invite/{code} deep links
        if (data.scheme == "buttonlog" && data.host == "invite") {
            val code = data.pathSegments.firstOrNull()
            if (!code.isNullOrEmpty()) {
                android.util.Log.d("MainActivity", "Deep link invite code: $code")
                pendingInviteCode = code
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    // Permission already granted
                    android.util.Log.d("MainActivity", "Notification permission already granted")
                }
                else -> {
                    // Request permission
                    requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    onLogout: () -> Unit = {},
    pendingInviteCode: String? = null,
    onInviteCodeConsumed: () -> Unit = {}
) {
    val navController = rememberNavController()
    var showCreateButton by remember { mutableStateOf(false) }
    var buttonToEdit by remember { mutableStateOf<Button?>(null) }
    var buttonToViewHistory by remember { mutableStateOf<Button?>(null) }
    var selectedFriend by remember { mutableStateOf<Friend?>(null) }
    var friendForGiftButton by remember { mutableStateOf<Friend?>(null) }
    var showSupportScreen by remember { mutableStateOf(false) }
    var selectedTicketId by remember { mutableStateOf<String?>(null) }
    var showCreateTicket by remember { mutableStateOf(false) }
    var showTeamsScreen by remember { mutableStateOf(false) }
    var showOrganizationsScreen by remember { mutableStateOf(false) }
    var showSubscriptionScreen by remember { mutableStateOf(false) }
    var showCreatedGiftButtonsScreen by remember { mutableStateOf(false) }
    var showEditProfileScreen by remember { mutableStateOf(false) }
    var showPrivacySettingsScreen by remember { mutableStateOf(false) }
    var showNotificationSettingsScreen by remember { mutableStateOf(false) }
    var showPasswordChangeScreen by remember { mutableStateOf(false) }
    var showDataExportScreen by remember { mutableStateOf(false) }
    var showAboutScreen by remember { mutableStateOf(false) }
    var showWebhookSettingsScreen by remember { mutableStateOf(false) }
    val buttonsViewModel: ButtonsViewModel = hiltViewModel()
    val friendsViewModel: FriendsViewModel = hiltViewModel()
    val notificationsViewModel: NotificationsViewModel = hiltViewModel()
    val friendsUiState by friendsViewModel.uiState.collectAsState()
    val buttonsUiState by buttonsViewModel.uiState.collectAsState()
    val notificationsUiState by notificationsViewModel.uiState.collectAsState()

    // Handle pending invite code from deep link
    LaunchedEffect(pendingInviteCode) {
        if (!pendingInviteCode.isNullOrEmpty()) {
            android.util.Log.d("MainScreen", "Processing pending invite code: $pendingInviteCode")
            friendsViewModel.acceptInvite(pendingInviteCode)
            onInviteCodeConsumed()
        }
    }

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                val pendingFriendRequestsCount = friendsUiState.pendingRequests.size
                val unreadNotificationsCount = notificationsUiState.unreadCount

                val items = listOf(
                    NavigationItem(
                        route = "home",
                        title = "Buttons",
                        icon = Icons.Default.GridView
                    ),
                    NavigationItem(
                        route = "friends",
                        title = "Friends",
                        icon = Icons.Default.People,
                        badgeCount = pendingFriendRequestsCount
                    ),
                    NavigationItem(
                        route = "diary",
                        title = "Diary",
                        icon = Icons.Default.Book
                    ),
                    NavigationItem(
                        route = "notifications",
                        title = "Logs",
                        icon = Icons.Default.Notifications,
                        badgeCount = unreadNotificationsCount
                    ),
                    NavigationItem(
                        route = "account",
                        title = "Account",
                        icon = Icons.Default.Person
                    )
                )

                items.forEach { item ->
                    val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true

                    NavigationBarItem(
                        icon = {
                            if (item.badgeCount > 0) {
                                BadgedBox(
                                    badge = {
                                        Badge {
                                            Text(
                                                text = if (item.badgeCount > 99) "99+" else item.badgeCount.toString(),
                                                style = MaterialTheme.typography.labelSmall
                                            )
                                        }
                                    }
                                ) {
                                    Icon(item.icon, contentDescription = item.title)
                                }
                            } else {
                                Icon(item.icon, contentDescription = item.title)
                            }
                        },
                        label = { Text(item.title) },
                        selected = selected,
                        onClick = {
                            navController.navigate(item.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Main content
            NavHost(
                navController = navController,
                startDestination = "home"
            ) {
                composable("home") {
                    ButtonsScreen(
                        onCreateButton = { showCreateButton = true },
                        onEditButton = { button -> buttonToEdit = button },
                        onViewHistory = { button -> buttonToViewHistory = button },
                        viewModel = buttonsViewModel
                    )
                }
                composable("friends") {
                    FriendsScreen(
                        onFriendSelected = { friend ->
                            selectedFriend = friend
                            friendsViewModel.selectFriend(friend)
                        },
                        onCreatedGiftButtonsClick = {
                            showCreatedGiftButtonsScreen = true
                        },
                        viewModel = friendsViewModel
                    )
                }
                composable("diary") {
                    DiaryScreen(viewModel = buttonsViewModel)
                }
                composable("notifications") {
                    NotificationsScreen(
                        viewModel = notificationsViewModel,
                        onNavigate = { destination ->
                            when (destination) {
                                is NotificationNavigation.Button -> {
                                    // Find the button and show history
                                    val button = buttonsUiState.buttons.find { it.id == destination.buttonId }
                                    if (button != null) {
                                        buttonToViewHistory = button
                                    }
                                }
                                is NotificationNavigation.Friend -> {
                                    // Navigate to specific friend's page
                                    val friend = friendsUiState.friends.find { it.friendId == destination.friendId }
                                    if (friend != null) {
                                        selectedFriend = friend
                                        friendsViewModel.selectFriend(friend)
                                    } else {
                                        // Fallback to friends list if friend not found
                                        navController.navigate("friends") {
                                            popUpTo(navController.graph.findStartDestination().id) {
                                                saveState = true
                                            }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                }
                                is NotificationNavigation.Friends -> {
                                    navController.navigate("friends") {
                                        popUpTo(navController.graph.findStartDestination().id) {
                                            saveState = true
                                        }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                                is NotificationNavigation.Support -> {
                                    showSupportScreen = true
                                }
                                is NotificationNavigation.SupportTicket -> {
                                    showSupportScreen = true
                                    selectedTicketId = destination.ticketId
                                }
                                is NotificationNavigation.None -> {
                                    // No navigation needed
                                }
                            }
                        }
                    )
                }
                composable("account") {
                    AccountScreen(
                        onLogout = onLogout,
                        onSupportClick = { showSupportScreen = true },
                        onTeamsClick = { showTeamsScreen = true },
                        onOrganizationsClick = { showOrganizationsScreen = true },
                        onSubscriptionClick = { showSubscriptionScreen = true },
                        onEditProfileClick = { showEditProfileScreen = true },
                        onPrivacySettingsClick = { showPrivacySettingsScreen = true },
                        onNotificationSettingsClick = { showNotificationSettingsScreen = true },
                        onPasswordChangeClick = { showPasswordChangeScreen = true },
                        onDataExportClick = { showDataExportScreen = true },
                        onAboutClick = { showAboutScreen = true },
                        onWebhookSettingsClick = { showWebhookSettingsScreen = true }
                    )
                }
            }
            
            // Floating + Button - only show on home screen
            if (currentDestination?.route == "home") {
                FloatingActionButton(
                    onClick = { showCreateButton = true },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 80.dp),
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                ) {
                    Icon(
                        Icons.Default.Add,
                        contentDescription = "Create Button",
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    }
    
    // Create Button Screen
    if (showCreateButton) {
        CreateButtonScreen(
            isLoading = buttonsUiState.isLoading,
            error = buttonsUiState.error,
            friends = friendsUiState.friends,
            onCreateButton = { formData ->
                buttonsViewModel.createButton(formData)
                showCreateButton = false
            },
            onNavigateBack = {
                showCreateButton = false
            }
        )
    }

    // Edit Button Screen
    buttonToEdit?.let { button ->
        val uiState by buttonsViewModel.uiState.collectAsState()

        // Load sharing settings when editing a button
        LaunchedEffect(button.id) {
            buttonsViewModel.loadButtonSharing(button.id)
        }

        EditButtonScreen(
            button = button,
            sharingSettings = uiState.buttonSharingSettings,
            isLoadingSharing = uiState.isLoadingSharing,
            onSave = { updatedButton, sharingSettings ->
                buttonsViewModel.updateButtonWithSharing(updatedButton, sharingSettings)
                buttonsViewModel.clearButtonSharing()
                buttonToEdit = null
            },
            onNavigateBack = {
                buttonsViewModel.clearButtonSharing()
                buttonToEdit = null
            }
        )
    }

    // Button History Screen
    buttonToViewHistory?.let { button ->
        ButtonHistoryScreen(
            button = button,
            buttonRepository = buttonsViewModel.buttonRepository,
            onNavigateBack = { buttonToViewHistory = null }
        )
    }

    // Friend Detail Screen
    selectedFriend?.let { friend ->
        FriendDetailScreen(
            friend = friend,
            uiState = friendsUiState,
            onNavigateBack = {
                selectedFriend = null
                friendsViewModel.selectFriend(null)
            },
            onRemoveFriend = { friendshipId ->
                friendsViewModel.removeFriend(friendshipId)
            },
            onUpdatePermissions = { friendId, permissions ->
                friendsViewModel.updateFriendPermissions(friendId, permissions)
            },
            onLoadMoreActivity = {
                friendsViewModel.loadMoreActivity(friend.friendId)
            },
            onCreateGiftButton = { friendToGift ->
                friendForGiftButton = friendToGift
            }
        )
    }

    // Create Gift Button Screen
    friendForGiftButton?.let { friend ->
        CreateGiftButtonScreen(
            friend = friend,
            isLoading = buttonsUiState.isLoading,
            error = buttonsUiState.error,
            onCreateButton = { formData, message ->
                buttonsViewModel.createButtonForFriend(friend.friendId, formData, message)
                friendForGiftButton = null
            },
            onNavigateBack = {
                friendForGiftButton = null
            }
        )
    }

    // Support Screen
    if (showSupportScreen) {
        val supportViewModel: SupportViewModel = hiltViewModel()

        SupportScreen(
            viewModel = supportViewModel,
            onTicketClick = { ticketId ->
                selectedTicketId = ticketId
            },
            onCreateTicket = {
                showCreateTicket = true
            },
            onBackClick = {
                showSupportScreen = false
            }
        )
    }

    // Support Ticket Detail Screen
    selectedTicketId?.let { ticketId ->
        val supportViewModel: SupportViewModel = hiltViewModel()

        SupportTicketScreen(
            ticketId = ticketId,
            viewModel = supportViewModel,
            onBackClick = {
                selectedTicketId = null
            }
        )
    }

    // Create Ticket Screen
    if (showCreateTicket) {
        val supportViewModel: SupportViewModel = hiltViewModel()

        CreateTicketScreen(
            viewModel = supportViewModel,
            onTicketCreated = {
                showCreateTicket = false
            },
            onBackClick = {
                showCreateTicket = false
            }
        )
    }

    // Teams Screen
    if (showTeamsScreen) {
        TeamsScreen(
            onTeamClick = { /* TODO: Navigate to team detail */ },
            onBackClick = { showTeamsScreen = false }
        )
    }

    // Organizations Screen
    if (showOrganizationsScreen) {
        OrganizationsScreen(
            onOrganizationClick = { /* TODO: Navigate to organization detail */ },
            onBackClick = { showOrganizationsScreen = false }
        )
    }

    // Subscription Screen
    if (showSubscriptionScreen) {
        SubscriptionScreen(
            onBackClick = { showSubscriptionScreen = false }
        )
    }

    // Created Gift Buttons Screen
    if (showCreatedGiftButtonsScreen) {
        CreatedGiftButtonsScreen(
            onNavigateBack = { showCreatedGiftButtonsScreen = false }
        )
    }

    // Edit Profile Screen
    if (showEditProfileScreen) {
        EditProfileScreen(
            onNavigateBack = { showEditProfileScreen = false }
        )
    }

    // Privacy Settings Screen
    if (showPrivacySettingsScreen) {
        PrivacySettingsScreen(
            onNavigateBack = { showPrivacySettingsScreen = false }
        )
    }

    // Notification Settings Screen
    if (showNotificationSettingsScreen) {
        NotificationSettingsScreen(
            onNavigateBack = { showNotificationSettingsScreen = false }
        )
    }

    // Password Change Screen
    if (showPasswordChangeScreen) {
        PasswordChangeScreen(
            onNavigateBack = { showPasswordChangeScreen = false }
        )
    }

    // Data Export Screen
    if (showDataExportScreen) {
        DataExportScreen(
            onNavigateBack = { showDataExportScreen = false }
        )
    }

    // About Screen
    if (showAboutScreen) {
        AboutScreen(
            onNavigateBack = { showAboutScreen = false }
        )
    }

    // Webhook Settings Screen
    if (showWebhookSettingsScreen) {
        WebhookSettingsScreen(
            onNavigateBack = { showWebhookSettingsScreen = false }
        )
    }

    // Invite Accepted Dialog
    if (friendsUiState.showInviteAcceptedDialog) {
        val acceptedFriend = friendsUiState.acceptedFriend
        AlertDialog(
            onDismissRequest = { friendsViewModel.clearInviteAcceptedDialog() },
            icon = {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(48.dp)
                )
            },
            title = {
                Text(
                    text = "You're now friends!",
                    style = MaterialTheme.typography.headlineSmall
                )
            },
            text = {
                Text(
                    text = if (acceptedFriend != null) {
                        "You and ${acceptedFriend.displayNameOrUsername} are now connected. You can share buttons and see each other's activity."
                    } else {
                        "You've successfully connected with a new friend. You can now share buttons and see each other's activity."
                    },
                    style = MaterialTheme.typography.bodyMedium
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        friendsViewModel.clearInviteAcceptedDialog()
                        // Navigate to friends screen
                        navController.navigate("friends") {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                ) {
                    Text("View Friends")
                }
            },
            dismissButton = {
                TextButton(onClick = { friendsViewModel.clearInviteAcceptedDialog() }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun PlaceholderScreen(title: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "$title Screen",
            style = MaterialTheme.typography.headlineMedium
        )
    }
}

data class NavigationItem(
    val route: String,
    val title: String,
    val icon: ImageVector,
    val badgeCount: Int = 0
)

