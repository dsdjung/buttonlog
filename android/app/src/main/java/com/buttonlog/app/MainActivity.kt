package com.buttonlog.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
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
import com.buttonlog.app.ui.screens.CreateGiftButtonScreen
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
import com.buttonlog.app.ui.viewmodels.ButtonsViewModel
import com.buttonlog.app.ui.viewmodels.FriendsViewModel
import com.buttonlog.app.ui.viewmodels.SupportViewModel
import com.buttonlog.app.ui.theme.ButtonLogTheme
import com.buttonlog.app.ui.viewmodels.AuthViewModel
import com.buttonlog.app.ui.viewmodels.NotificationsViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            ButtonLogTheme {
                val authViewModel: AuthViewModel = hiltViewModel()
                val isLoggedIn by authViewModel.isLoggedIn.collectAsState()

                if (isLoggedIn) {
                    MainScreen(onLogout = { authViewModel.logout() })
                } else {
                    LoginScreen(viewModel = authViewModel)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(onLogout: () -> Unit = {}) {
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
    val buttonsViewModel: ButtonsViewModel = hiltViewModel()
    val friendsViewModel: FriendsViewModel = hiltViewModel()
    val notificationsViewModel: NotificationsViewModel = hiltViewModel()
    val friendsUiState by friendsViewModel.uiState.collectAsState()
    val buttonsUiState by buttonsViewModel.uiState.collectAsState()
    val notificationsUiState by notificationsViewModel.uiState.collectAsState()

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
                        title = "Home",
                        icon = Icons.Default.Home
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
                        title = "Alerts",
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
                        viewModel = friendsViewModel
                    )
                }
                composable("diary") {
                    DiaryScreen(viewModel = buttonsViewModel)
                }
                composable("notifications") {
                    NotificationsScreen(
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
                        onOrganizationsClick = { showOrganizationsScreen = true }
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
    
    // Create Button Dialog - TODO: Implement
    if (showCreateButton) {
        AlertDialog(
            onDismissRequest = { showCreateButton = false },
            title = { Text("Create Button") },
            text = { Text("Button creation will be implemented here.") },
            confirmButton = {
                TextButton(onClick = { showCreateButton = false }) {
                    Text("OK")
                }
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

