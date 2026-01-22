# ButtonLog Feature Test Plan

A comprehensive test plan covering all features across Backend, iOS, Android, and Web platforms.

## Test Coverage Status

| Platform | Current Coverage | Target Coverage |
|----------|-----------------|-----------------|
| Backend | ~20% | 80% |
| iOS | ~20% | 80% |
| Android | ~20% | 80% |
| Web (LiveView) | 0% | 70% |

---

## 1. Authentication & Account Management

### 1.1 User Registration

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Register with valid email/password | ⬜ | ⬜ | ⬜ | ⬜ |
| Register with invalid email format | ⬜ | ⬜ | ⬜ | ⬜ |
| Register with weak password | ⬜ | ⬜ | ⬜ | ⬜ |
| Register with existing email | ⬜ | ⬜ | ⬜ | ⬜ |
| Password confirmation mismatch | ⬜ | ⬜ | ⬜ | ⬜ |
| JWT token issued on success | ⬜ | ⬜ | ⬜ | N/A |
| User created in database | ⬜ | N/A | N/A | ⬜ |

### 1.2 User Login

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Login with valid credentials | ⬜ | ⬜ | ⬜ | ⬜ |
| Login with invalid password | ⬜ | ⬜ | ⬜ | ⬜ |
| Login with non-existent email | ⬜ | ⬜ | ⬜ | ⬜ |
| JWT token returned | ⬜ | ⬜ | ⬜ | N/A |
| Token stored securely | N/A | ⬜ | ⬜ | ⬜ |
| User session created | ⬜ | N/A | N/A | ⬜ |

### 1.3 OAuth Authentication

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Google OAuth flow | ⬜ | ⬜ | ⬜ | ⬜ |
| Facebook OAuth flow | ⬜ | N/A | N/A | ⬜ |
| Apple Sign-In | ⬜ | ⬜ | N/A | N/A |
| OAuth user creation | ⬜ | N/A | N/A | ⬜ |
| OAuth user linking | ⬜ | N/A | N/A | ⬜ |
| OAuth error handling | ⬜ | ⬜ | ⬜ | ⬜ |

### 1.4 Token Management

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Token refresh | ⬜ | ⬜ | ⬜ | N/A |
| Token expiration handling | ⬜ | ⬜ | ⬜ | N/A |
| Invalid token rejection | ⬜ | ⬜ | ⬜ | N/A |
| Logout clears token | ⬜ | ⬜ | ⬜ | ⬜ |

### 1.5 User Profile

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Get current user profile | ⬜ | ⬜ | ⬜ | ⬜ |
| Update display name | ⬜ | ⬜ | ⬜ | ⬜ |
| Update avatar | ⬜ | ⬜ | ⬜ | ⬜ |
| Update timezone | ⬜ | ⬜ | ⬜ | ⬜ |
| Update privacy settings | ⬜ | ⬜ | ⬜ | ⬜ |
| Complete onboarding | ⬜ | ⬜ | ⬜ | N/A |

---

## 2. Button Management

### 2.1 Button Creation

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Create instant button | ⬜ | ⬜ | ⬜ | ⬜ |
| Create toggle button | ⬜ | ⬜ | ⬜ | ⬜ |
| Create one-time button | ⬜ | ⬜ | ⬜ | ⬜ |
| Create workflow button | ⬜ | ⬜ | ⬜ | ⬜ |
| Create with custom icon | ⬜ | ⬜ | ⬜ | ⬜ |
| Create with custom color | ⬜ | ⬜ | ⬜ | ⬜ |
| Create with description | ⬜ | ⬜ | ⬜ | ⬜ |
| Validation: empty name | ⬜ | ⬜ | ⬜ | ⬜ |
| Validation: name too long | ⬜ | ⬜ | ⬜ | ⬜ |
| Subscription limit check | ⬜ | ⬜ | ⬜ | ⬜ |

### 2.2 Button Retrieval

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| List all user buttons | ⬜ | ⬜ | ⬜ | ⬜ |
| Get single button by ID | ⬜ | ⬜ | ⬜ | ⬜ |
| List includes shared buttons | ⬜ | ⬜ | ⬜ | ⬜ |
| Filter by type | ⬜ | ⬜ | ⬜ | ⬜ |
| Filter by active status | ⬜ | ⬜ | ⬜ | ⬜ |
| Search by name | ⬜ | ⬜ | ⬜ | ⬜ |
| Search by description | ⬜ | ⬜ | ⬜ | ⬜ |
| Pagination support | ⬜ | ⬜ | ⬜ | ⬜ |

### 2.3 Button Update

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Update button name | ⬜ | ⬜ | ⬜ | ⬜ |
| Update button description | ⬜ | ⬜ | ⬜ | ⬜ |
| Update button icon | ⬜ | ⬜ | ⬜ | ⬜ |
| Update button color | ⬜ | ⬜ | ⬜ | ⬜ |
| Update active status | ⬜ | ⬜ | ⬜ | ⬜ |
| Cannot update non-owned button | ⬜ | ⬜ | ⬜ | ⬜ |
| Cannot change button type | ⬜ | ⬜ | ⬜ | ⬜ |

### 2.4 Button Deletion

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Delete owned button | ⬜ | ⬜ | ⬜ | ⬜ |
| Cannot delete non-owned button | ⬜ | ⬜ | ⬜ | ⬜ |
| Delete removes clicks | ⬜ | N/A | N/A | N/A |
| Delete removes shares | ⬜ | N/A | N/A | N/A |
| Confirmation dialog shown | N/A | ⬜ | ⬜ | ⬜ |

### 2.5 Button Settings

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Enable/disable alerts | ⬜ | ⬜ | ⬜ | ⬜ |
| Set auto-stop duration | ⬜ | ⬜ | ⬜ | ⬜ |
| Enable/disable calendar sync | ⬜ | ⬜ | ⬜ | ⬜ |

---

## 3. Click Tracking

### 3.1 Button Clicks

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Click instant button | ⬜ | ⬜ | ⬜ | ⬜ |
| Start toggle button | ⬜ | ⬜ | ⬜ | ⬜ |
| Stop toggle button | ⬜ | ⬜ | ⬜ | ⬜ |
| Complete one-time button | ⬜ | ⬜ | ⬜ | ⬜ |
| Advance workflow button | ⬜ | ⬜ | ⬜ | ⬜ |
| Click records timestamp | ⬜ | N/A | N/A | N/A |
| Click records device info | ⬜ | ⬜ | ⬜ | ⬜ |
| Click records location | ⬜ | ⬜ | ⬜ | N/A |
| Click count incremented | ⬜ | N/A | N/A | N/A |
| Monthly click limit enforced | ⬜ | ⬜ | ⬜ | ⬜ |

### 3.2 Toggle Button State

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Start sets state to active | ⬜ | ⬜ | ⬜ | ⬜ |
| Stop sets state to idle | ⬜ | ⬜ | ⬜ | ⬜ |
| Duration calculated on stop | ⬜ | N/A | N/A | N/A |
| Auto-stop triggers at timeout | ⬜ | N/A | N/A | N/A |
| Auto-stop notification sent | ⬜ | N/A | N/A | N/A |

### 3.3 One-Time Button

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Complete archives button | ⬜ | ⬜ | ⬜ | ⬜ |
| Cannot click archived button | ⬜ | ⬜ | ⬜ | ⬜ |
| Completion notification sent | ⬜ | N/A | N/A | N/A |

### 3.4 Button History

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Get click history for button | ⬜ | ⬜ | ⬜ | ⬜ |
| History includes all fields | ⬜ | ⬜ | ⬜ | ⬜ |
| Pagination support | ⬜ | ⬜ | ⬜ | ⬜ |
| Filter by date range | ⬜ | N/A | N/A | ⬜ |
| History respects plan limits | ⬜ | N/A | N/A | N/A |

---

## 4. Social Features

### 4.1 Friend Requests

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Send friend request | ⬜ | ⬜ | ⬜ | ⬜ |
| Accept friend request | ⬜ | ⬜ | ⬜ | ⬜ |
| Decline friend request | ⬜ | ⬜ | ⬜ | ⬜ |
| Cancel sent request | ⬜ | ⬜ | ⬜ | ⬜ |
| Cannot request self | ⬜ | ⬜ | ⬜ | ⬜ |
| Cannot duplicate request | ⬜ | ⬜ | ⬜ | ⬜ |
| Friend limit enforced | ⬜ | ⬜ | ⬜ | ⬜ |

### 4.2 Friend Management

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| List all friends | ⬜ | ⬜ | ⬜ | ⬜ |
| List pending requests | ⬜ | ⬜ | ⬜ | ⬜ |
| List sent requests | ⬜ | ⬜ | ⬜ | ⬜ |
| Remove friend | ⬜ | ⬜ | ⬜ | ⬜ |
| Bidirectional removal | ⬜ | N/A | N/A | N/A |

### 4.3 Friend Permissions

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Get permissions for friend | ⬜ | ⬜ | ⬜ | ⬜ |
| Update button visibility | ⬜ | ⬜ | ⬜ | ⬜ |
| Update history access | ⬜ | ⬜ | ⬜ | ⬜ |
| Update notification settings | ⬜ | ⬜ | ⬜ | ⬜ |

### 4.4 Friend Activity

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Get friend's visible buttons | ⬜ | ⬜ | ⬜ | ⬜ |
| Get friend's activity feed | ⬜ | ⬜ | ⬜ | ⬜ |
| Activity respects permissions | ⬜ | N/A | N/A | N/A |
| Pagination support | ⬜ | ⬜ | ⬜ | ⬜ |

---

## 5. Button Sharing

### 5.1 Sharing Settings

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Set sharing mode: private | ✅ | ⬜ | ⬜ | ⬜ |
| Set sharing mode: friends | ✅ | ⬜ | ⬜ | ⬜ |
| Set sharing mode: invite-only | ✅ | ⬜ | ⬜ | ⬜ |
| Set sharing mode: public | ✅ | ⬜ | ⬜ | ⬜ |

### 5.2 Collaborators

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Add collaborator | ✅ | ⬜ | ⬜ | ⬜ |
| Remove collaborator | ✅ | ⬜ | ⬜ | ⬜ |
| List collaborators | ✅ | ⬜ | ⬜ | ⬜ |
| Collaborator can click | ✅ | ⬜ | ⬜ | ⬜ |
| Non-collaborator blocked | ✅ | ⬜ | ⬜ | ⬜ |

### 5.3 Share Links

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Generate share token | ✅ | N/A | N/A | ⬜ |
| Token expiration | ✅ | N/A | N/A | N/A |
| Revoke share token | ✅ | N/A | N/A | ⬜ |
| Join via share link | ✅ | N/A | N/A | ⬜ |

---

## 6. Notifications & Alerts

### 6.1 In-App Alerts

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Alert on friend click | ✅ | ⬜ | ⬜ | ⬜ |
| Alert on gift received | ✅ | ⬜ | ⬜ | ⬜ |
| Alert on button shared | ⬜ | ⬜ | ⬜ | ⬜ |
| Alert on auto-stop | ⬜ | ⬜ | ⬜ | ⬜ |
| List all alerts | ⬜ | ⬜ | ⬜ | ⬜ |
| Mark alert as read | ⬜ | ⬜ | ⬜ | ⬜ |
| Mark all as read | ⬜ | ⬜ | ⬜ | ⬜ |
| Unread count | ⬜ | ⬜ | ⬜ | ⬜ |
| Delete alert | ⬜ | ⬜ | ⬜ | ⬜ |

### 6.2 Alert Preferences

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Get alert preferences | ⬜ | ⬜ | ⬜ | ⬜ |
| Update per-button settings | ⬜ | ⬜ | ⬜ | ⬜ |
| Update per-friend settings | ⬜ | ⬜ | ⬜ | ⬜ |
| Select all | ⬜ | ⬜ | ⬜ | ⬜ |
| Deselect all | ⬜ | ⬜ | ⬜ | ⬜ |

### 6.3 Push Notifications

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Register device | ⬜ | ⬜ | ⬜ | N/A |
| List devices | ⬜ | ⬜ | ⬜ | N/A |
| Unregister device | ⬜ | ⬜ | ⬜ | N/A |
| Push delivery on click | ⬜ | ⬜ | ⬜ | N/A |
| Push delivery on gift | ⬜ | ⬜ | ⬜ | N/A |

### 6.4 Webhooks

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Configure webhook URL | ✅ | N/A | N/A | ⬜ |
| Webhook delivery on event | ✅ | N/A | N/A | N/A |
| Webhook retry on failure | ✅ | N/A | N/A | N/A |
| Test webhook | ⬜ | N/A | N/A | ⬜ |

---

## 7. Subscriptions

### 7.1 Plans

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| List available plans | ✅ | ⬜ | ⬜ | ⬜ |
| Get plan details | ✅ | ⬜ | ⬜ | ⬜ |
| Plan feature comparison | ✅ | ⬜ | ⬜ | ⬜ |

### 7.2 Subscription Management

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Subscribe to plan | ✅ | ⬜ | ⬜ | ⬜ |
| Cancel subscription | ✅ | ⬜ | ⬜ | ⬜ |
| Pause subscription | ✅ | ⬜ | ⬜ | ⬜ |
| Resume subscription | ✅ | ⬜ | ⬜ | ⬜ |
| Change plan | ✅ | ⬜ | ⬜ | ⬜ |
| Trial period | ✅ | ⬜ | ⬜ | ⬜ |

### 7.3 Usage Tracking

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Track button count | ✅ | ⬜ | ⬜ | ⬜ |
| Track friend count | ✅ | ⬜ | ⬜ | ⬜ |
| Track monthly clicks | ✅ | ⬜ | ⬜ | ⬜ |
| Monthly reset | ✅ | N/A | N/A | N/A |
| Limit enforcement | ✅ | ⬜ | ⬜ | ⬜ |

### 7.4 Billing

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Add payment method | ✅ | N/A | N/A | ⬜ |
| Remove payment method | ✅ | N/A | N/A | ⬜ |
| Set default payment | ✅ | N/A | N/A | ⬜ |
| View invoices | ✅ | N/A | N/A | ⬜ |
| Apply coupon | ✅ | N/A | N/A | ⬜ |
| Stripe webhook handling | ✅ | N/A | N/A | N/A |

---

## 8. Teams

### 8.1 Team Management

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Create team | ✅ | ⬜ | ⬜ | ⬜ |
| Update team | ✅ | ⬜ | ⬜ | ⬜ |
| Delete team | ✅ | ⬜ | ⬜ | ⬜ |
| List user's teams | ✅ | ⬜ | ⬜ | ⬜ |
| Transfer ownership | ✅ | N/A | N/A | ⬜ |

### 8.2 Team Members

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Add member | ✅ | ⬜ | ⬜ | ⬜ |
| Remove member | ✅ | ⬜ | ⬜ | ⬜ |
| Update role | ✅ | ⬜ | ⬜ | ⬜ |
| List members | ✅ | ⬜ | ⬜ | ⬜ |

### 8.3 Team Invitations

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Send invitation | ✅ | ⬜ | ⬜ | ⬜ |
| Accept invitation | ✅ | ⬜ | ⬜ | ⬜ |
| Decline invitation | ✅ | ⬜ | ⬜ | ⬜ |
| Cancel invitation | ✅ | ⬜ | ⬜ | ⬜ |
| List pending invitations | ✅ | ⬜ | ⬜ | ⬜ |

### 8.4 Team Buttons

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Assign button to team | ✅ | ⬜ | ⬜ | ⬜ |
| Remove button from team | ✅ | ⬜ | ⬜ | ⬜ |
| List team buttons | ✅ | ⬜ | ⬜ | ⬜ |

---

## 9. Organizations

### 9.1 Organization Management

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Create organization | ✅ | ⬜ | ⬜ | ⬜ |
| Update organization | ✅ | N/A | N/A | ⬜ |
| Delete organization | ✅ | N/A | N/A | ⬜ |
| List organizations | ✅ | ⬜ | ⬜ | ⬜ |
| Transfer ownership | ✅ | N/A | N/A | ⬜ |

### 9.2 Organization Members

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Add member | ✅ | ⬜ | ⬜ | ⬜ |
| Remove member | ✅ | N/A | N/A | ⬜ |
| Update role | ✅ | N/A | N/A | ⬜ |
| List members | ✅ | ⬜ | ⬜ | ⬜ |

### 9.3 Organization Teams

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Add team to org | ✅ | N/A | N/A | ⬜ |
| Remove team from org | ✅ | N/A | N/A | ⬜ |
| List org teams | ✅ | ⬜ | ⬜ | ⬜ |

---

## 10. Support System

### 10.1 Tickets

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Create ticket | ✅ | ⬜ | ⬜ | ⬜ |
| View ticket details | ✅ | ⬜ | ⬜ | ⬜ |
| Add message | ✅ | ⬜ | ⬜ | ⬜ |
| List user tickets | ✅ | ⬜ | ⬜ | ⬜ |
| Close ticket | ✅ | ⬜ | ⬜ | ⬜ |

### 10.2 Admin Support

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| List all tickets | ✅ | N/A | N/A | ⬜ |
| Assign ticket | ✅ | N/A | N/A | ⬜ |
| Update status | ✅ | N/A | N/A | ⬜ |
| Support statistics | ✅ | N/A | N/A | ⬜ |

---

## 11. Gift Buttons

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Create gift button | ✅ | ⬜ | ⬜ | N/A |
| Gift received notification | ✅ | ⬜ | ⬜ | N/A |
| Click gift button | ✅ | ⬜ | ⬜ | N/A |
| Gift click notification | ✅ | ⬜ | ⬜ | N/A |
| Delete gift button | ✅ | ⬜ | ⬜ | N/A |
| One-time gift completes | ✅ | ⬜ | ⬜ | N/A |

---

## 12. Real-Time Features

### 12.1 WebSocket Channels

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| User channel connection | ⬜ | N/A | N/A | ⬜ |
| Button channel connection | ⬜ | N/A | N/A | ⬜ |
| Token authentication | ⬜ | N/A | N/A | ⬜ |
| Broadcast on click | ⬜ | N/A | N/A | ⬜ |
| Broadcast on state change | ⬜ | N/A | N/A | ⬜ |

### 12.2 LiveView Features

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Button list live update | N/A | N/A | N/A | ⬜ |
| Click counter live update | N/A | N/A | N/A | ⬜ |
| Friend activity live | N/A | N/A | N/A | ⬜ |

---

## 13. UI/UX Tests

### 13.1 Navigation

| Test Case | iOS | Android | Web |
|-----------|:---:|:-------:|:---:|
| Tab navigation works | ⬜ | ⬜ | ⬜ |
| Back navigation works | ⬜ | ⬜ | ⬜ |
| Deep linking works | ⬜ | ⬜ | ⬜ |

### 13.2 Forms

| Test Case | iOS | Android | Web |
|-----------|:---:|:-------:|:---:|
| Form validation | ⬜ | ⬜ | ⬜ |
| Error display | ⬜ | ⬜ | ⬜ |
| Loading states | ⬜ | ⬜ | ⬜ |
| Success feedback | ⬜ | ⬜ | ⬜ |

### 13.3 Responsive Design

| Test Case | iOS | Android | Web |
|-----------|:---:|:-------:|:---:|
| iPhone SE layout | ⬜ | N/A | N/A |
| iPhone Pro Max layout | ⬜ | N/A | N/A |
| iPad layout | ⬜ | N/A | N/A |
| Small Android layout | N/A | ⬜ | N/A |
| Tablet layout | N/A | ⬜ | N/A |
| Desktop layout | N/A | N/A | ⬜ |
| Mobile web layout | N/A | N/A | ⬜ |

### 13.4 Accessibility

| Test Case | iOS | Android | Web |
|-----------|:---:|:-------:|:---:|
| VoiceOver support | ⬜ | N/A | N/A |
| TalkBack support | N/A | ⬜ | N/A |
| Screen reader support | N/A | N/A | ⬜ |
| Color contrast | ⬜ | ⬜ | ⬜ |
| Touch targets | ⬜ | ⬜ | ⬜ |

---

## 14. Error Handling

### 14.1 Network Errors

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Handle timeout | ⬜ | ⬜ | ⬜ | ⬜ |
| Handle no connection | N/A | ⬜ | ⬜ | ⬜ |
| Handle server error (5xx) | ⬜ | ⬜ | ⬜ | ⬜ |
| Retry mechanism | N/A | ⬜ | ⬜ | ⬜ |

### 14.2 Authentication Errors

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Handle 401 Unauthorized | ⬜ | ⬜ | ⬜ | ⬜ |
| Handle 403 Forbidden | ⬜ | ⬜ | ⬜ | ⬜ |
| Token expiration recovery | N/A | ⬜ | ⬜ | N/A |

### 14.3 Validation Errors

| Test Case | Backend | iOS | Android | Web |
|-----------|:-------:|:---:|:-------:|:---:|
| Handle 400 Bad Request | ⬜ | ⬜ | ⬜ | ⬜ |
| Handle 422 Unprocessable | ⬜ | ⬜ | ⬜ | ⬜ |
| Display field errors | ⬜ | ⬜ | ⬜ | ⬜ |

---

## Test Legend

- ✅ = Test exists and passes
- ⬜ = Test needed (not implemented)
- N/A = Not applicable for this platform

---

## Implementation Priority

### Tier 1 - Critical (Implement First)

1. **Authentication Tests** (All platforms)
   - Registration, login, logout
   - Token management
   - OAuth flows

2. **Button Core Tests** (All platforms)
   - CRUD operations
   - Click tracking
   - State management

3. **API Controller Tests** (Backend)
   - All 20+ API endpoints
   - Error responses
   - Authorization checks

### Tier 2 - High Priority

4. **Social Features Tests** (All platforms)
   - Friend requests
   - Permissions
   - Activity feeds

5. **Notification Tests** (All platforms)
   - Alert delivery
   - Push notifications
   - Preferences

6. **UI/UX Tests** (iOS, Android, Web)
   - Navigation
   - Form validation
   - Loading states

### Tier 3 - Medium Priority

7. **Subscription Tests** (All platforms)
   - Plan management
   - Usage tracking
   - Billing

8. **Team/Org Tests** (All platforms)
   - Member management
   - Invitations
   - Permissions

9. **Real-Time Tests** (Backend, Web)
   - WebSocket channels
   - LiveView updates

### Tier 4 - Lower Priority

10. **Accessibility Tests** (All platforms)
11. **Performance Tests** (All platforms)
12. **Edge Case Tests** (All platforms)

---

## Running Tests

### Backend
```bash
cd backend
source .env && mix test
```

### iOS
```bash
cd iphone
xcodebuild test -project ButtonLog.xcodeproj -scheme ButtonLog -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Android
```bash
cd android
./gradlew test          # Unit tests
./gradlew connectedTest # Instrumentation tests
```

---

*Last updated: January 2026*
