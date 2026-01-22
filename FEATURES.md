# ButtonLog Feature Listing

A comprehensive list of all features in the ButtonLog application across all platforms.

## Platform Legend
- **B** = Backend (Phoenix/Elixir)
- **i** = iOS (SwiftUI)
- **A** = Android (Jetpack Compose)
- **W** = Web (Phoenix LiveView)

---

## User Authentication & Account Management

### Authentication
| Feature | Platforms |
|---------|-----------|
| Email/password registration | B, i, A, W |
| Email/password login | B, i, A, W |
| OAuth: Google | B, i, A, W |
| OAuth: Facebook | B, W |
| OAuth: Apple | B, i |
| OAuth: GitHub | B, W |
| JWT token authentication | B, i, A |
| Token refresh | B, i, A |
| Session management | B, W |
| Email verification | B, W |
| Password reset | B, W |

### User Profile
| Feature | Platforms |
|---------|-----------|
| Display name | B, i, A, W |
| Avatar upload | B, i, A, W |
| Timezone settings | B, i, A, W |
| Language preferences | B, W |
| Privacy settings | B, i, A, W |
| Onboarding flow | B, i, A |
| Public profile viewing | B, W |

### Admin Features
| Feature | Platforms |
|---------|-----------|
| Admin dashboard | B, W |
| User management | B, W |
| Support ticket admin | B, W |
| System statistics | B, W |

---

## Button Management

### Button Types
| Type | Description | Platforms |
|------|-------------|-----------|
| Instant | Single click tracking | B, i, A, W |
| Toggle | Start/stop with duration | B, i, A, W |
| One-Time | Self-archiving single use | B, i, A, W |
| Workflow | Predefined state sequence | B, i, A, W |

### Button Properties
| Feature | Platforms |
|---------|-----------|
| Custom name | B, i, A, W |
| Description | B, i, A, W |
| Custom icon (20 options) | B, i, A, W |
| Custom color (hex) | B, i, A, W |
| Active/inactive toggle | B, i, A, W |
| State tracking | B, i, A, W |

### Button Operations
| Feature | Platforms |
|---------|-----------|
| Create button | B, i, A, W |
| Edit button | B, i, A, W |
| Delete button | B, i, A, W |
| Archive button | B, i, A, W |
| Search/filter buttons | i, A, W |

### Button Settings
| Feature | Platforms |
|---------|-----------|
| Alert notifications toggle | B, i, A, W |
| Auto-stop duration (15-480 min) | B, i, A, W |
| Calendar sync enable | B, i, A, W |

---

## Click Tracking & History

### Click Recording
| Feature | Platforms |
|---------|-----------|
| Record click with timestamp | B, i, A, W |
| Track device info | B, i, A |
| Location tracking | B, i, A |
| Duration for toggle buttons | B, i, A, W |
| Action types (click, start, stop, complete, auto_stop) | B, i, A, W |

### History Features
| Feature | Platforms |
|---------|-----------|
| View click history | B, i, A, W |
| Paginated history | B, i, A, W |
| Date range filtering | B, W |
| Export history | B, W |
| Latest click display | B, i, A, W |

### Analytics
| Feature | Platforms |
|---------|-----------|
| Click statistics | B, W |
| Usage trends | B, W |
| Monthly click count | B, i, A |
| Activity timeline | B, W |

---

## Social Features

### Friend Management
| Feature | Platforms |
|---------|-----------|
| Send friend request | B, i, A, W |
| Accept/decline request | B, i, A, W |
| View friends list | B, i, A, W |
| Remove friend | B, i, A, W |
| Pending requests view | B, i, A, W |
| Sent requests view | B, i, A, W |

### Friend Permissions
| Feature | Platforms |
|---------|-----------|
| Button visibility control | B, i, A, W |
| History viewing permission | B, i, A, W |
| Per-friend notification settings | B, i, A, W |

### Friend Activity
| Feature | Platforms |
|---------|-----------|
| Friend activity feed | B, i, A, W |
| Friend's latest clicks | B, i, A |
| Friend's button list | B, i, A, W |

---

## Button Sharing & Collaboration

### Sharing Modes
| Mode | Description | Platforms |
|------|-------------|-----------|
| Private | Owner only | B, i, A, W |
| Friends | All friends | B, i, A, W |
| Invite Only | Explicit collaborators | B, i, A, W |
| Public | Anyone with link | B, W |

### Collaborator Management
| Feature | Platforms |
|---------|-----------|
| Add collaborators | B, i, A, W |
| Remove collaborators | B, i, A, W |
| View collaborators | B, i, A, W |
| Permission tracking | B |

### Share Links
| Feature | Platforms |
|---------|-----------|
| Generate share link | B, W |
| Token expiration | B |
| Revoke share link | B, W |
| Join via link | B, W |

### Per-Friend Sharing
| Feature | Platforms |
|---------|-----------|
| Control per-button visibility | B, i, A, W |
| Bulk sharing settings | B, i, A, W |

---

## Notifications & Alerts

### In-App Alerts
| Alert Type | Platforms |
|------------|-----------|
| Friend clicked your button | B, i, A |
| Gift button received | B, i, A |
| Gift button clicked | B, i, A |
| Button shared with you | B, i, A |
| Collaborator clicked | B, i, A |
| Button auto-stopped | B, i, A |
| One-time button completed | B, i, A |

### Alert Management
| Feature | Platforms |
|---------|-----------|
| Mark as read | B, i, A |
| Mark all as read | B, i, A |
| Unread count | B, i, A |
| Delete alerts | B, i, A |

### Alert Preferences
| Feature | Platforms |
|---------|-----------|
| Per-button settings | B, i, A, W |
| Per-friend enable/disable | B, i, A, W |
| Select all / deselect all | B, i, A, W |

### Push Notifications
| Feature | Platforms |
|---------|-----------|
| Device registration | B, i, A |
| Firebase Cloud Messaging | B, A |
| Apple Push Notifications | B, i |
| Device management | B, i, A |

### Webhooks
| Feature | Platforms |
|---------|-----------|
| User-level webhooks | B, W |
| Button-level webhooks | B, W |
| Event delivery | B |
| Retry mechanism | B |
| Test webhook | B, W |

---

## Subscription & Billing

### Subscription Plans
| Plan | Features | Platforms |
|------|----------|-----------|
| Free | 5 buttons, 10 friends, 1K clicks/mo, 30 day history | B, i, A, W |
| Premium ($9.99/mo) | 50 buttons, 100 friends, 10K clicks/mo, 365 day history, advanced analytics, calendar sync, API access | B, i, A, W |
| Enterprise ($29.99/mo) | Unlimited everything, priority support, white-label, team features | B, i, A, W |

### Billing Features
| Feature | Platforms |
|---------|-----------|
| Monthly/yearly billing | B, W |
| Trial periods (14/30 day) | B, W |
| Subscription pause/resume | B, W |
| Usage tracking | B, i, A, W |
| Usage reset (monthly) | B |

### Payment Management
| Feature | Platforms |
|---------|-----------|
| Add payment method | B, W |
| Remove payment method | B, W |
| View billing history | B, W |
| Download invoices | B, W |
| Apply coupon codes | B, W |
| Stripe integration | B, W |

---

## Team Management

### Team Operations
| Feature | Platforms |
|---------|-----------|
| Create team | B, i, A, W |
| List teams | B, i, A, W |
| Update team | B, i, A, W |
| Delete team | B, i, A, W |
| Transfer ownership | B, W |

### Team Members
| Feature | Platforms |
|---------|-----------|
| Add members | B, i, A, W |
| Remove members | B, i, A, W |
| Update roles (owner, admin, member) | B, i, A, W |
| View members | B, i, A, W |

### Team Invitations
| Feature | Platforms |
|---------|-----------|
| Send invitations | B, i, A, W |
| Accept/decline | B, i, A, W |
| Cancel invitation | B, i, A, W |
| View pending invitations | B, i, A, W |

### Team Buttons
| Feature | Platforms |
|---------|-----------|
| Assign buttons to team | B, i, A, W |
| View team buttons | B, i, A, W |
| Remove from team | B, i, A, W |

---

## Organization Management (Enterprise)

### Organization Operations
| Feature | Platforms |
|---------|-----------|
| Create organization | B, i, A, W |
| List organizations | B, i, A, W |
| Update organization | B, W |
| Delete organization | B, W |
| Transfer ownership | B, W |

### Organization Members
| Feature | Platforms |
|---------|-----------|
| Add members | B, i, A, W |
| Remove members | B, W |
| Update roles | B, W |
| View members | B, i, A, W |

### Organization Teams
| Feature | Platforms |
|---------|-----------|
| Add teams | B, W |
| Remove teams | B, W |
| View teams | B, i, A, W |

### Organization Features
| Feature | Platforms |
|---------|-----------|
| Seat-based billing | B, W |
| Audit logs | B, W |
| Organization-level subscription | B, W |

---

## Support System

### Support Tickets
| Feature | Platforms |
|---------|-----------|
| Create ticket | B, i, A, W |
| View ticket details | B, i, A, W |
| Add messages | B, i, A, W |
| Track status | B, i, A, W |
| View history | B, i, A, W |

### Admin Support
| Feature | Platforms |
|---------|-----------|
| Assign tickets | B, W |
| Update status | B, W |
| Support statistics | B, W |
| Live support view | B, W |

---

## Special Features

### Gift Buttons
| Feature | Platforms |
|---------|-----------|
| Create gift button for friend | B, i, A |
| Include gift message | B, i, A |
| Gift received notification | B, i, A |
| Gift clicked notification | B, i, A |

### Auto-Stop
| Feature | Platforms |
|---------|-----------|
| Configure auto-stop duration | B, i, A, W |
| Automatic button stopping | B |
| Auto-stop notifications | B, i, A |

### Calendar Sync
| Feature | Platforms |
|---------|-----------|
| Enable/disable per button | B, i, A, W |
| Calendar integration | Planned |

### Diary/Activity Log
| Feature | Platforms |
|---------|-----------|
| Personal activity feed | B, W |
| Historical viewing | B, W |
| Pagination | B, W |

---

## Real-Time Features

### WebSocket Channels
| Channel | Purpose | Platforms |
|---------|---------|-----------|
| User channel | Personal notifications | B, W |
| Button channel | Collaborative updates | B, W |
| Lobby channel | General broadcasts | B, W |

### Real-Time Updates
| Feature | Platforms |
|---------|-----------|
| Button state changes | B, W |
| Collaborator broadcasts | B, W |
| Friend activity updates | B, W |

---

## Platform-Specific Features

### iOS App
- Tab-based navigation with 5 tabs
- Floating action button (+) for quick creation
- SF Symbols for icons
- Keychain for secure token storage
- Onboarding flow
- Splash screen
- Design system with BLSpacing, BLRadius, BLShadow
- Pull-to-refresh

### Android App
- Material Design 3 UI
- Bottom navigation
- Material Icons
- MVVM + Repository architecture
- Hilt dependency injection
- Room database for offline caching
- Onboarding flow
- Design system with BLSpacing, BLRadius, BLElevation

### Web Interface
- Phoenix LiveView for real-time UI
- Responsive design
- Admin panel
- Webhook configuration
- Full analytics dashboard
- Tailwind CSS with design tokens

---

## Button Icon Options

Both iOS and Android support the following button icons:
- star, heart, bolt, flame, leaf, drop
- sun, moon, cloud, snowflake
- car, airplane, gamecontroller
- book, pencil, scissors
- wrench, hammer, gear, lock

---

## Button Color Options

Preset colors available:
- Red (#EF5350)
- Orange (#FF9800)
- Yellow (#FFC107)
- Green (#4CAF50)
- Teal (#00BFA5)
- Blue (#2196F3)
- Indigo (#3F51B5)
- Purple (#9C27B0)
- Pink (#E91E63)

Custom hex colors also supported.

---

## API Summary

The ButtonLog API provides:
- RESTful JSON endpoints
- JWT token authentication
- Comprehensive error handling
- Request metadata (timestamp, request_id)
- Cursor-based pagination
- Rate limiting (based on subscription tier)

---

## Feature Support Matrix

| Category | Backend | iOS | Android | Web |
|----------|:-------:|:---:|:-------:|:---:|
| Authentication | ✓ | ✓ | ✓ | ✓ |
| Button Management | ✓ | ✓ | ✓ | ✓ |
| Click Tracking | ✓ | ✓ | ✓ | ✓ |
| Social/Friends | ✓ | ✓ | ✓ | ✓ |
| Sharing | ✓ | ✓ | ✓ | ✓ |
| In-App Alerts | ✓ | ✓ | ✓ | ✓ |
| Push Notifications | ✓ | ✓ | ✓ | - |
| Subscriptions | ✓ | ✓ | ✓ | ✓ |
| Teams | ✓ | ✓ | ✓ | ✓ |
| Organizations | ✓ | ✓ | ✓ | ✓ |
| Support Tickets | ✓ | ✓ | ✓ | ✓ |
| Webhooks | ✓ | - | - | ✓ |
| Full Analytics | ✓ | - | - | ✓ |
| Admin Features | ✓ | - | - | ✓ |
| Gift Buttons | ✓ | ✓ | ✓ | - |
| Auto-Stop | ✓ | ✓ | ✓ | ✓ |
| Diary/Activity | ✓ | - | - | ✓ |
| Real-Time Updates | ✓ | - | - | ✓ |

---

*Last updated: January 2026*
