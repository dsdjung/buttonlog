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
import com.buttonlog.app.ui.screens.AccountScreen
import com.buttonlog.app.ui.screens.ButtonHistoryScreen
import com.buttonlog.app.ui.screens.ButtonsScreen
import com.buttonlog.app.ui.screens.EditButtonScreen
import com.buttonlog.app.ui.screens.LoginScreen
import com.buttonlog.app.ui.viewmodels.ButtonsViewModel
import com.buttonlog.app.ui.theme.ButtonLogTheme
import com.buttonlog.app.ui.viewmodels.AuthViewModel
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
    val buttonsViewModel: ButtonsViewModel = hiltViewModel()

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                val items = listOf(
                    NavigationItem(
                        route = "home",
                        title = "Home",
                        icon = Icons.Default.Home
                    ),
                    NavigationItem(
                        route = "friends",
                        title = "Friends",
                        icon = Icons.Default.People
                    ),
                    NavigationItem(
                        route = "notifications",
                        title = "Notifications",
                        icon = Icons.Default.Notifications
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
                        icon = { Icon(item.icon, contentDescription = item.title) },
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
                    PlaceholderScreen("Friends")
                }
                composable("notifications") {
                    PlaceholderScreen("Notifications")
                }
                composable("account") {
                    AccountScreen(onLogout = onLogout)
                }
            }
            
            // Floating + Button
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
        EditButtonScreen(
            button = button,
            onSave = { updatedButton ->
                buttonsViewModel.updateButton(updatedButton)
                buttonToEdit = null
            },
            onNavigateBack = { buttonToEdit = null }
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
    val icon: ImageVector
)

