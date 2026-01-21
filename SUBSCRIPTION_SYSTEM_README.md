# ButtonLog Subscription System

## Overview

The ButtonLog subscription system provides a flexible, feature-based pricing model that allows users to access different levels of functionality based on their subscription tier. The system is designed to be scalable, maintainable, and easily extensible for future features.

## Architecture

### Core Components

1. **SubscriptionPlan** - Defines subscription tiers with features and limits
2. **UserSubscription** - Tracks individual user subscriptions and usage
3. **SubscriptionService** - Business logic for subscription management
4. **SubscriptionController** - API endpoints for subscription operations

### Database Schema

```
subscription_plans
├── id (UUID)
├── name, slug, description
├── pricing (monthly/yearly)
├── feature_limits (buttons, friends, clicks, etc.)
├── feature_flags (analytics, calendar_sync, etc.)
└── trial_settings

user_subscriptions
├── id (UUID)
├── user_id, subscription_plan_id
├── status, billing_cycle, amount
├── period_dates (start, end, trial)
├── payment_provider_details
└── usage_tracking

subscription_events (audit trail)
billing_events (payment tracking)
```

## Subscription Tiers

### 🆓 Free Plan
- **Price**: $0/month
- **Limits**:
  - 5 buttons
  - 10 friends
  - 1,000 button clicks/month
  - 30 days analytics history
  - 30 days export history
- **Features**: Basic functionality only

### ⭐ Premium Plan
- **Price**: $9.99/month or $99.99/year
- **Limits**:
  - 50 buttons
  - 100 friends
  - 10,000 button clicks/month
  - 365 days analytics history
  - 365 days export history
- **Features**:
  - ✅ Advanced analytics
  - ✅ Calendar sync
  - ✅ API access
  - ✅ Custom themes
  - 14-day trial (credit card required)

### 🚀 Enterprise Plan
- **Price**: $29.99/month or $299.99/year
- **Limits**: Unlimited across all categories
- **Features**:
  - ✅ All Premium features
  - ✅ Priority support
  - ✅ Team features
  - ✅ White-label options
  - 30-day trial (credit card required)

## Feature System

### Feature Flags
The system uses boolean flags to control access to specific features:

```elixir
# Example feature check
def can_access_analytics(user_id, days_back) do
  SubscriptionService.can_perform_action(user_id, :access_analytics, %{days_back: days_back})
end
```

### Usage Tracking
Real-time tracking of resource usage:

- **Button Creation**: Increments `buttons_used` counter
- **Friend Addition**: Increments `friends_used` counter
- **Button Clicks**: Monthly `clicks_this_month` counter (resets monthly)

### Dynamic Limits
Limits are enforced at runtime:

```elixir
# Check if user can create another button
can_create = SubscriptionService.can_perform_action(
  user_id, 
  :create_button, 
  %{current_button_count: user_button_count}
)
```

## API Endpoints

### Public Endpoints
- `GET /api/subscriptions` - List all available plans

### Authenticated Endpoints
- `GET /api/subscriptions/current` - Get user's current subscription
- `POST /api/subscriptions` - Create new subscription
- `DELETE /api/subscriptions` - Cancel subscription
- `POST /api/subscriptions/pause` - Pause subscription
- `POST /api/subscriptions/resume` - Resume subscription
- `GET /api/subscriptions/stats` - Get subscription statistics
- `POST /api/subscriptions/check-permission` - Check feature access

## Implementation Examples

### Creating a Subscription

```elixir
# In your controller or service
subscription_params = %{
  plan_slug: "premium",
  billing_cycle: "monthly",
  payment_details: %{
    provider: "stripe",
    subscription_id: "sub_123",
    customer_id: "cus_456"
  }
}

case SubscriptionService.create_subscription(user_id, subscription_params) do
  {:ok, subscription} -> 
    # Handle success
  {:error, message} -> 
    # Handle error
end
```

### Checking Feature Access

```elixir
# Before allowing button creation
def create_button(conn, params) do
  user_id = conn.assigns.current_user.id
  
  if SubscriptionService.can_perform_action(user_id, :create_button, %{
    current_button_count: get_user_button_count(user_id)
  }) do
    # Proceed with button creation
    track_usage(user_id, :create_button)
    # ... create button logic
  else
    # Return upgrade prompt
    conn
    |> put_status(:forbidden)
    |> json(%{error: "Upgrade required", limit: "max_buttons"})
  end
end
```

### Usage Tracking

```elixir
# After successful button click
def click_button(conn, %{"id" => button_id}) do
  user_id = conn.assigns.current_user.id
  
  # Check if user can click (respects monthly limits)
  if SubscriptionService.can_perform_action(user_id, :click_button, %{user_id: user_id}) do
    # Track usage for paid users
    SubscriptionService.track_usage(user_id, :click_button)
    
    # ... button click logic
  else
    # Return limit exceeded message
    conn
    |> put_status(:too_many_requests)
    |> json(%{error: "Monthly click limit exceeded"})
  end
end
```

## Integration Points

### Button Management
- Check limits before creation
- Track usage after creation
- Enforce limits in UI

### Friend System
- Check friend limits before adding
- Track friend count usage
- Show upgrade prompts when limits reached

### Analytics & Export
- Check data access permissions
- Enforce history limits
- Show feature upgrade prompts

### Payment Integration
The system is designed to work with any payment provider:

```elixir
# Example Stripe integration
def handle_stripe_webhook(event) do
  case event.type do
    "customer.subscription.created" ->
      create_subscription_from_stripe(event.data)
    
    "customer.subscription.updated" ->
      update_subscription_from_stripe(event.data)
    
    "customer.subscription.deleted" ->
      cancel_subscription_from_stripe(event.data)
  end
end
```

## Security & Privacy

### Data Protection
- Subscription data is isolated per user
- Payment details are not stored (only provider IDs)
- Audit trail for all subscription changes

### Access Control
- All subscription endpoints require authentication
- Users can only access their own subscription data
- Feature checks happen at the service layer

## Monitoring & Analytics

### Key Metrics
- Subscription conversion rates
- Feature usage patterns
- Churn analysis
- Revenue tracking

### Audit Trail
- All subscription changes are logged
- Billing events are tracked
- Usage patterns are monitored

## Future Enhancements

### Planned Features
- **Usage Analytics**: Detailed usage breakdowns
- **A/B Testing**: Different pricing strategies
- **Dynamic Pricing**: Location-based pricing
- **Bulk Discounts**: Team/enterprise pricing
- **Feature Flags**: Gradual feature rollouts

### Scalability Considerations
- **Database Sharding**: User-based partitioning
- **Caching**: Subscription plan caching
- **Background Jobs**: Usage reset and billing
- **Webhooks**: Real-time payment updates

## Testing

### Unit Tests
```elixir
# Test subscription service
test "can_perform_action/3 with premium plan" do
  user = insert(:user)
  subscription = insert(:user_subscription, user: user, plan: :premium)
  
  assert SubscriptionService.can_perform_action(user.id, :create_button, %{current_button_count: 25})
  refute SubscriptionService.can_perform_action(user.id, :create_button, %{current_button_count: 51})
end
```

### Integration Tests
```elixir
# Test API endpoints
test "POST /api/subscriptions creates subscription" do
  user = insert(:user)
  conn = authenticated_conn(user)
  
  params = %{
    plan_slug: "premium",
    billing_cycle: "monthly",
    payment_details: %{provider: "stripe", subscription_id: "sub_123"}
  }
  
  conn = post(conn, "/api/subscriptions", params)
  assert json_response(conn, 201)
end
```

## Deployment

### Environment Variables
```bash
# Payment provider configuration
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Subscription settings
SUBSCRIPTION_TRIAL_DAYS=14
SUBSCRIPTION_GRACE_PERIOD_DAYS=7
```

### Database Migration
```bash
# Run subscription system migration
mix ecto.migrate
```

### Monitoring Setup
- Set up alerts for failed payments
- Monitor subscription conversion rates
- Track feature usage patterns

## Support & Troubleshooting

### Common Issues
1. **Subscription not activating**: Check payment provider webhooks
2. **Usage limits not enforced**: Verify service layer integration
3. **Trial periods not working**: Check trial configuration

### Debug Commands
```elixir
# Check user subscription status
iex> ButtonLog.Subscriptions.SubscriptionService.get_user_subscription(user_id)

# Verify feature access
iex> ButtonLog.Subscriptions.SubscriptionService.can_perform_action(user_id, :create_button, %{})
```

## Conclusion

The ButtonLog subscription system provides a robust foundation for monetizing your application while maintaining a great user experience. The system is designed to be:

- **Flexible**: Easy to add new features and plans
- **Scalable**: Handles growth without performance issues
- **Maintainable**: Clear separation of concerns
- **Secure**: Proper access control and data protection
- **Extensible**: Ready for future enhancements

For questions or support, refer to the codebase or contact the development team.

