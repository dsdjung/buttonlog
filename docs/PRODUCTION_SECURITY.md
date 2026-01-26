# Production Security Guide

This document outlines the security requirements for deploying ButtonLog to production.

## Required Environment Variables

The following environment variables MUST be set in production:

### Critical (Application will fail without these)

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `SECRET_KEY_BASE` | Phoenix secret key for cookies/sessions | Generate: `mix phx.gen.secret` |
| `DATABASE_URL` | PostgreSQL connection string | Your database provider |
| `PHX_HOST` | Production hostname | e.g., `buttonlog.com` |

### Payment Processing (Required if using Stripe)

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `STRIPE_SECRET_KEY` | Stripe API secret key | Stripe Dashboard > Developers > API keys |
| `STRIPE_WEBHOOK_SECRET` | Webhook signing secret (REQUIRED in prod) | Stripe Dashboard > Developers > Webhooks |
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key | Stripe Dashboard > Developers > API keys |
| `STRIPE_PRICE_*` | Price IDs for subscription plans | Stripe Dashboard > Products |

### Authentication

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | Google Cloud Console |
| `FACEBOOK_CLIENT_ID` | Facebook OAuth app ID (optional) | Facebook Developers |
| `FACEBOOK_CLIENT_SECRET` | Facebook OAuth app secret (optional) | Facebook Developers |
| `APPLE_CLIENT_ID` | Apple Sign In client ID (optional) | Apple Developer Portal |
| `APPLE_CLIENT_SECRET` | Apple Sign In client secret (optional) | Apple Developer Portal |

### Push Notifications

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `FCM_PROJECT_ID` | Firebase project ID | Firebase Console |
| `FCM_SERVICE_ACCOUNT_JSON` | Firebase service account JSON | Firebase Console > Project Settings > Service Accounts |
| `APNS_KEY_ID` | Apple Push Notification key ID | Apple Developer Portal > Keys |
| `APNS_TEAM_ID` | Apple Team ID | Apple Developer Portal |
| `APNS_KEY_PATH` or `APNS_KEY_CONTENT` | APNs authentication key | Apple Developer Portal > Keys |
| `APNS_BUNDLE_ID` | iOS app bundle identifier | Your app's bundle ID |
| `APNS_ENVIRONMENT` | `api.push.apple.com` for production | - |

### Email (AWS SES)

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | AWS IAM Console |
| `AWS_REGION` | AWS region for SES | e.g., `us-east-1` |
| `SES_FROM_EMAIL` | Verified sender email | Must be verified in AWS SES |

---

## Credential Rotation Schedule

### Immediate Rotation Required
If any of these have been exposed (e.g., committed to git):
- [ ] `SECRET_KEY_BASE` - Regenerate immediately
- [ ] `STRIPE_SECRET_KEY` - Rotate in Stripe Dashboard
- [ ] `STRIPE_WEBHOOK_SECRET` - Regenerate in Stripe Webhooks
- [ ] `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - Rotate in AWS IAM
- [ ] `GOOGLE_CLIENT_SECRET` - Regenerate in Google Cloud Console
- [ ] `FCM_SERVICE_ACCOUNT_JSON` - Generate new service account key

### Recommended Rotation Schedule

| Credential | Rotation Period | Notes |
|------------|-----------------|-------|
| `SECRET_KEY_BASE` | 90 days or on compromise | Will invalidate all sessions |
| Database password | 90 days | Coordinate with deployment |
| AWS IAM keys | 90 days | Create new key, then delete old |
| Stripe API keys | Annually or on compromise | Test with test keys first |
| OAuth secrets | Annually or on compromise | Coordinate with mobile app updates |
| APNs key | 12 months (expiration) | Apple keys expire after 12 months |

---

## Pre-Deployment Security Checklist

### Configuration
- [ ] `force_ssl` is enabled in `prod.exs`
- [ ] `SECRET_KEY_BASE` is set from environment variable
- [ ] `STRIPE_WEBHOOK_SECRET` is set (required in production)
- [ ] No debug endpoints exposed (`/debug`, `/test`)
- [ ] LiveDashboard is disabled or password-protected

### Secrets
- [ ] No secrets in source code or git history
- [ ] `.env` file is in `.gitignore`
- [ ] All credentials are loaded from environment variables
- [ ] Test/development keys are NOT used in production

### Network
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] HSTS headers enabled
- [ ] Database not publicly accessible
- [ ] Firewall rules configured

### Monitoring
- [ ] Error tracking configured (Sentry, etc.)
- [ ] Logging to centralized service
- [ ] Alerts for failed authentication attempts
- [ ] Alerts for payment processing errors

---

## Incident Response

### If Credentials Are Compromised

1. **Immediately rotate** the compromised credential
2. **Audit logs** for unauthorized access
3. **Notify users** if their data may have been accessed
4. **Document** the incident and response
5. **Review** how the compromise occurred

### Contact for Security Issues

Report security vulnerabilities to: security@buttonlog.com

---

## Production Environment Setup

```bash
# Generate a secure SECRET_KEY_BASE
mix phx.gen.secret

# Required environment variables (example)
export SECRET_KEY_BASE="generated-secret-here"
export DATABASE_URL="ecto://user:pass@host/buttonlog_prod"
export PHX_HOST="buttonlog.com"
export STRIPE_SECRET_KEY="sk_live_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
# ... other variables from env_template.txt
```

### Building for Production

```bash
# Install dependencies
mix deps.get --only prod

# Compile assets
MIX_ENV=prod mix assets.deploy

# Compile application
MIX_ENV=prod mix compile

# Run database migrations
MIX_ENV=prod mix ecto.migrate

# Start the server
MIX_ENV=prod mix phx.server
```
