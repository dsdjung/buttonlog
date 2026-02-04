# ButtonLog Automation Playbook

Full-stack automation plan covering strategy iteration, development, deployment, marketing, and operations.

---

## Current Infrastructure Inventory

### What Already Exists

| Category | Tool/Config | Location |
|----------|-------------|----------|
| CI/CD (Backend) | GitHub Actions | `.github/workflows/ci.yml` |
| CI/CD (Deploy) | GitHub Actions | `.github/workflows/deploy.yml` |
| CI/CD (Android) | GitHub Actions + Fastlane | `.github/workflows/android.yml`, `android/fastlane/` |
| CI/CD (iOS) | GitHub Actions + Fastlane | `.github/workflows/ios.yml`, `iphone/fastlane/` |
| E2E (Web) | Playwright | `e2e/playwright.config.ts` |
| E2E (Mobile) | Maestro | `e2e-mobile/config.yaml` |
| Docker | Multi-stage build | `deploy/docker/Dockerfile`, `deploy/docker/docker-compose.yml` |
| Server provisioning | Bash script | `deploy/scripts/setup-server.sh` |
| Deployment | SSH + symlink releases | `deploy/scripts/deploy.sh` |
| Remote ops | Helper script | `deploy/scripts/remote-commands.sh` |
| Secrets | GitHub Actions secrets | Configured per-workflow |
| Email | AWS SES + Swoosh | `backend/config/runtime.exs` |
| Push (Android) | FCM | `backend/config/runtime.exs` |
| Push (iOS) | APNs | `backend/config/runtime.exs` |
| Payments | Stripe | `backend/config/runtime.exs` |
| Test runner | ExUnit | `backend/mix.exs` |
| DNS/AWS | SES credentials + DNS records | `aws/` |

### What Is Missing

| Category | Gap |
|----------|-----|
| Error tracking | No Sentry or equivalent |
| Uptime monitoring | No health check monitoring |
| Log aggregation | No centralized logging |
| Product analytics | No event tracking (Mixpanel, PostHog, etc.) |
| Database backups | No automated backup/restore |
| Staging environment | No pre-production environment |
| Dependency scanning | No Dependabot or Renovate |
| Security scanning | No SAST/DAST in CI |
| Feature flags | No runtime feature toggle system |
| Load testing | No performance regression tests |
| Infrastructure as code | No Terraform/Pulumi |
| App store metadata | No automated screenshots or descriptions |
| Landing page | Default Phoenix welcome page |
| Referral system | Not built |
| In-app review prompts | Not implemented |
| Rate limiting | No API rate limiting |

---

## 1. Strategy Iteration (Automated Feedback Loop)

Goal: data flows in from users and the market, strategy adjusts based on evidence.

### 1.1 Product Analytics — PostHog

| Detail | Value |
|--------|-------|
| Tool | PostHog (self-hosted or cloud) |
| Cost | Free tier (1M events/mo) to $450/mo |
| Purpose | Funnels, retention cohorts, feature usage, session recordings |

**Integration points:**
- Backend: Track server-side events (button clicks, signups, subscription changes) via PostHog Elixir client
- iOS: PostHog Swift SDK — track screen views, button interactions, feature usage
- Android: PostHog Android SDK — same event set as iOS for parity
- Web: PostHog JS snippet in Phoenix layout

**Key events to track:**
```
user_signed_up, user_logged_in, button_created, button_clicked,
friend_request_sent, friend_request_accepted, gift_button_sent,
subscription_started, subscription_cancelled, export_requested
```

### 1.2 App Store Metrics Pipeline

| Detail | Value |
|--------|-------|
| Tool | App Store Connect API + Google Play Developer API |
| Cost | Free (already have developer accounts) |
| Purpose | Pull ratings, reviews, install counts, crash rates |

**Build:** Scheduled job (daily cron or Oban job) that:
1. Fetches reviews from both stores via their APIs
2. Runs sentiment analysis via Claude API (batch, ~$0.01/review)
3. Tags reviews as: bug report, feature request, praise, complaint
4. Stores results in a `review_analyses` table
5. Surfaces top issues in the strategy dashboard

### 1.3 Revenue Metrics

| Detail | Value |
|--------|-------|
| Tool | Stripe Dashboard + webhooks (already configured) |
| Cost | Free |
| Purpose | MRR, churn, LTV, ARPU |

**Build:** Phoenix LiveView dashboard page that queries:
- `subscriptions` table for MRR/ARR calculations
- Stripe API for payment failure rates
- User table for conversion funnel (registered → free → trial → paid)

### 1.4 Strategy Dashboard

| Detail | Value |
|--------|-------|
| Tool | Custom Phoenix LiveView page |
| Cost | Free (code) |
| Purpose | Single view of all KPIs from STRATEGY.md |

**Aggregates data from:**
- PostHog (DAU/MAU, retention, feature adoption)
- Stripe (MRR, churn, LTV)
- App store APIs (ratings, install velocity, review sentiment)
- Backend database (button count, click volume, friend connections)

**Auto-generates:** Weekly strategy health report comparing actuals to STRATEGY.md targets.

---

## 2. Development Automation

### 2.1 Dependency Management — Dependabot

| Detail | Value |
|--------|-------|
| Tool | GitHub Dependabot |
| Cost | Free |
| Setup | 2 minutes — add `.github/dependabot.yml` |

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "mix"
    directory: "/backend"
    schedule:
      interval: "weekly"
  - package-ecosystem: "npm"
    directory: "/backend/assets"
    schedule:
      interval: "weekly"
  - package-ecosystem: "gradle"
    directory: "/android"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### 2.2 Security Scanning

| Detail | Value |
|--------|-------|
| Tool | Sobelow (Elixir SAST) + GitHub CodeQL |
| Cost | Free |
| Purpose | Catch security vulnerabilities in CI |

**Add to CI pipeline:**
```yaml
- name: Security scan
  run: mix sobelow --config
```

**Add CodeQL:** Enable via GitHub repository Settings → Code security → CodeQL analysis.

### 2.3 Static Type Checking — Dialyzer

| Detail | Value |
|--------|-------|
| Tool | Dialyzer via `dialyxir` |
| Cost | Free |
| Purpose | Static type analysis for Elixir |

**Add to CI pipeline:**
```yaml
- name: Dialyzer
  run: mix dialyzer --format github
```

### 2.4 Test Coverage Tracking

| Detail | Value |
|--------|-------|
| Tool | ExCoveralls or Codecov |
| Cost | Free |
| Purpose | Track coverage regressions across PRs |

### 2.5 Feature Flags — FunWithFlags

| Detail | Value |
|--------|-------|
| Tool | FunWithFlags (Elixir library) |
| Cost | Free |
| Purpose | Runtime feature toggles without redeployment |

**Use cases:**
- Roll out new features to % of users
- Kill switch for problematic features
- A/B test different experiences
- Enable features per subscription tier

### 2.6 Load Testing — k6

| Detail | Value |
|--------|-------|
| Tool | k6 (Grafana Labs) |
| Cost | Free (CLI), paid for cloud |
| Purpose | Automated performance regression tests |

**Script key API endpoints:**
- `POST /api/buttons/:id/click` (highest traffic)
- `GET /api/buttons` (most frequent read)
- `POST /api/auth/login` (auth flow)
- WebSocket channel connections

**Run in CI:** On release branches, run k6 against staging to catch regressions.

---

## 3. Deployment Automation

### 3.1 Automated Database Backups

| Detail | Value |
|--------|-------|
| Tool | Cron + pg_dump + S3 |
| Cost | ~$2-5/mo (S3 storage) |
| Priority | CRITICAL — currently zero backup automation |

**Build:** Cron job on production server:
```bash
# /etc/cron.d/buttonlog-backup
0 3 * * * buttonlog /opt/buttonlog/scripts/backup.sh
```

**Backup script responsibilities:**
1. `pg_dump` with compression → timestamped file
2. Upload to S3 bucket with lifecycle policy (30-day retention)
3. Verify upload succeeded
4. Weekly automated restore test to a scratch database
5. Alert on failure via webhook

### 3.2 Staging Environment

| Detail | Value |
|--------|-------|
| Tool | Second VPS (Linode/DigitalOcean) |
| Cost | ~$20-40/mo |
| Purpose | Pre-production validation |

**Automation:**
- Auto-deploy `develop` branch on push via GitHub Actions
- Mirror production config with test Stripe keys
- Run E2E tests against staging before production deploy
- Seed with synthetic test data

### 3.3 Infrastructure as Code — Terraform

| Detail | Value |
|--------|-------|
| Tool | Terraform |
| Cost | Free |
| Purpose | Reproducible infrastructure |

**Manage:**
- VPS provisioning (Linode/DigitalOcean provider)
- PostgreSQL database
- DNS records
- S3 buckets (backups, assets)
- AWS SES configuration
- Firewall rules

### 3.4 Blue-Green Deployments

| Detail | Value |
|--------|-------|
| Tool | Custom script (Docker compose profiles exist) |
| Cost | Free |
| Purpose | Zero-downtime deployments |

**Automate the flow:**
1. Deploy new release to inactive slot (blue or green)
2. Run health checks against new slot
3. Swap nginx upstream to new slot
4. Keep old slot running for instant rollback
5. Clean up old slot after verification period

### 3.5 Automated SSL Renewal

| Detail | Value |
|--------|-------|
| Tool | Let's Encrypt + certbot |
| Cost | Free |
| Setup | Certbot cron with auto-renewal |

```bash
# /etc/cron.d/certbot-renew
0 0 1,15 * * root certbot renew --quiet --post-hook "systemctl reload nginx"
```

### 3.6 Unified Version Management

| Detail | Value |
|--------|-------|
| Tool | Custom script |
| Cost | Free |
| Purpose | Single source of truth for version across all platforms |

**Script that updates version in:**
- `backend/mix.exs` (Elixir version)
- `android/app/build.gradle.kts` (versionName + versionCode)
- `iphone/ButtonLog.xcodeproj` (CFBundleShortVersionString + CFBundleVersion)

**Triggered by:** Git tag push (e.g., `v1.2.0`).

---

## 4. Marketing Automation

### 4.1 App Store Optimization (ASO)

| Detail | Value |
|--------|-------|
| Tool | AppFollow or AppTweak |
| Cost | $30-100/mo |
| Purpose | Keyword tracking, competitor monitoring, review management |

**Track:**
- Keyword rankings for: "habit tracker", "button counter", "activity log", "social habit tracker"
- Competitor app updates and rating changes
- Review response management

### 4.2 Automated App Store Screenshots — Fastlane Snapshot

| Detail | Value |
|--------|-------|
| Tool | Fastlane snapshot (iOS) + screengrab (Android) |
| Cost | Free |
| Purpose | Auto-generate screenshots for all device sizes |

**Build:**
- UI test scripts that navigate to key screens
- Run on every release to regenerate screenshots
- Upload via `fastlane deliver` (iOS) and `fastlane supply` (Android)

### 4.3 App Store Metadata Management

| Detail | Value |
|--------|-------|
| Tool | Fastlane metadata directories |
| Cost | Free |
| Purpose | Version-controlled app store descriptions, keywords, changelogs |

**Directory structure:**
```
android/fastlane/metadata/android/en-US/
  full_description.txt
  short_description.txt
  title.txt
  changelogs/

iphone/fastlane/metadata/en-US/
  description.txt
  keywords.txt
  subtitle.txt
  release_notes.txt
```

**Auto-deploy:** Metadata uploaded alongside each app release in CI.

### 4.4 Landing Page — buttonlog.com

| Detail | Value |
|--------|-------|
| Tool | Phoenix (replace default welcome page) |
| Cost | Free |
| Purpose | SEO-optimized marketing site, email capture |

**Pages to build:**
- `/` — Hero, value proposition, feature highlights, CTA
- `/pricing` — Subscription comparison table
- `/features` — Detailed feature breakdown
- `/blog` — SEO content (optional, or use Ghost at $9/mo)

### 4.5 Email Automation — Onboarding Drip

| Detail | Value |
|--------|-------|
| Tool | Swoosh + AWS SES (already configured) + Oban (job scheduling) |
| Cost | ~$5/mo (SES volume) |
| Purpose | Automated email sequences |

**Sequences to build:**

| Sequence | Trigger | Emails |
|----------|---------|--------|
| Welcome | User registers | Day 0: Welcome + getting started |
| Activation | No buttons created after 24h | Day 1: "Create your first button" |
| Social | No friends after 3 days | Day 3: "Track with friends" |
| Engagement | No clicks in 7 days | Day 7: Re-engagement prompt |
| Upgrade | Free user hits limit | Immediate: Upgrade prompt |
| Churn prevention | Subscription cancelled | Day 0: "We're sorry to see you go" + Day 7: Win-back offer |
| Failed payment | Stripe payment fails | Day 0: Update payment method (dunning) |

### 4.6 Referral System

| Detail | Value |
|--------|-------|
| Tool | Custom (backend code) |
| Cost | Free to build |
| Purpose | Viral growth loop from STRATEGY.md |

**Build:**
- `referral_codes` table: unique code per user
- `referrals` table: referrer_id, referee_id, status, reward_granted
- Reward: Both referrer and referee get 1 month Premium free
- Deep link generation for sharing
- Track attribution through signup flow

### 4.7 In-App Review Prompts

| Detail | Value |
|--------|-------|
| Tool | iOS `SKStoreReviewController`, Android `ReviewManager` |
| Cost | Free |
| Purpose | Drive app store ratings organically |

**Trigger conditions (show prompt when ALL are true):**
- User has 5+ button clicks
- User has used app for 7+ days
- User has not been prompted in last 90 days
- User has not dismissed prompt 2+ times

### 4.8 Push Notification Campaigns

| Detail | Value |
|--------|-------|
| Tool | FCM + APNs (infrastructure exists) |
| Cost | Free |
| Purpose | Re-engagement and feature adoption |

**Build:**
- Campaign targeting: by subscription tier, activity level, last active date
- Scheduling: send at user's local optimal time
- A/B testing: message content variants
- Templates: streak reminders, friend activity, new feature announcements

### 4.9 Automated Changelog

| Detail | Value |
|--------|-------|
| Tool | Custom script |
| Cost | Free |
| Purpose | Auto-generate release notes from git history |

**Flow:**
1. On git tag push, extract commits since last tag
2. Group by type (feat, fix, chore) using conventional commits
3. Generate markdown changelog
4. Surface in-app ("What's New" modal on first launch after update)
5. Use as app store release notes

---

## 5. Operations Automation

### 5.1 Error Tracking — Sentry

| Detail | Value |
|--------|-------|
| Tool | Sentry |
| Cost | Free tier (5K errors/mo) to $26/mo |
| Priority | CRITICAL — currently zero error tracking |

**Integration:**
- Backend: `sentry` Elixir SDK — captures exceptions, Plug errors, Oban failures
- iOS: Sentry Swift SDK — crash reports, breadcrumbs, performance
- Android: Sentry Android SDK — crash reports, ANRs, performance

**Alerts:** Slack/Discord webhook on new error types, error spike (>10x baseline), unhandled exceptions.

### 5.2 Uptime Monitoring

| Detail | Value |
|--------|-------|
| Tool | UptimeRobot or Better Uptime |
| Cost | Free tier |
| Priority | CRITICAL |

**Monitors:**
- `GET /health` — every 60 seconds
- `GET /api/buttons` (authenticated) — every 5 minutes
- SSL certificate expiry — weekly check
- DNS resolution — every 5 minutes

**Includes:** Public status page at `status.buttonlog.com`.

### 5.3 Log Aggregation

| Detail | Value |
|--------|-------|
| Tool | Logflare (Phoenix-native) or Papertrail |
| Cost | Free tier to $7/mo |
| Purpose | Centralized searchable logs |

**Integrate:**
- `LogflareLogger` backend for Elixir Logger
- Search, filter, and alert on log patterns
- Alert on: repeated auth failures, payment errors, 5xx spikes

### 5.4 Automated Alerting

| Detail | Value |
|--------|-------|
| Tool | Webhook integrations from Sentry + UptimeRobot + Stripe |
| Cost | Free |
| Purpose | Unified alert channel |

**Alert routing:**
| Source | Condition | Channel |
|--------|-----------|---------|
| Sentry | New error type | Slack/Discord + email |
| Sentry | Error spike (>10x) | Slack/Discord + email + SMS |
| UptimeRobot | Downtime detected | Slack/Discord + email + SMS |
| Stripe | Payment failure | Email |
| Stripe | Subscription cancelled | Email |
| App store | 1-star review | Slack/Discord |
| CI/CD | Deploy failure | Slack/Discord |

### 5.5 API Rate Limiting

| Detail | Value |
|--------|-------|
| Tool | Custom Plug (Elixir) or `hammer` library |
| Cost | Free |
| Priority | HIGH — no protection against abuse |

**Rate limits:**
| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /api/auth/login` | 10 requests | per minute per IP |
| `POST /api/auth/register` | 5 requests | per minute per IP |
| `POST /api/buttons/:id/click` | 60 requests | per minute per user |
| `GET /api/*` (authenticated) | 300 requests | per minute per user |
| `GET /api/*` (unauthenticated) | 30 requests | per minute per IP |

### 5.6 GDPR/Privacy Automation

| Detail | Value |
|--------|-------|
| Tool | Custom (backend code) |
| Cost | Free |
| Purpose | Compliance with GDPR, CCPA |

**Build:**
- `GET /api/users/me/export` — Full data export (JSON) — already partially exists
- `DELETE /api/users/me` — Account deletion with cascade (buttons, clicks, friends, notifications)
- Cookie consent banner on web
- Privacy dashboard: show what data is stored, allow selective deletion
- Automated data retention: purge inactive accounts after 2 years (with warning emails)

### 5.7 Database Maintenance

| Detail | Value |
|--------|-------|
| Tool | Cron + psql scripts |
| Cost | Free |
| Purpose | Keep database healthy at scale |

**Scheduled tasks:**
```bash
# Weekly VACUUM ANALYZE
0 4 * * 0 buttonlog psql $DATABASE_URL -c "VACUUM ANALYZE;"

# Monthly reindex
0 4 1 * * buttonlog psql $DATABASE_URL -c "REINDEX DATABASE buttonlog_prod;"

# Daily: reset monthly usage counters (1st of month)
0 0 1 * * buttonlog /opt/buttonlog/scripts/reset-monthly-usage.sh
```

### 5.8 Customer Self-Service

| Detail | Value |
|--------|-------|
| Tool | Custom (Phoenix pages) |
| Cost | Free |
| Purpose | Reduce support burden |

**Build:**
- `/help` — FAQ page with common questions
- `/help/getting-started` — Onboarding guide
- In-app help tooltips on first use
- Contact form that creates support tickets (stored in database)

---

## Implementation Priority

### Week 1-2: Critical gaps (low effort, high impact)

| # | Task | Effort | Cost |
|---|------|--------|------|
| 1 | Enable Dependabot | 2 min | Free |
| 2 | Set up Sentry (backend + mobile) | 1 hour | Free tier |
| 3 | Set up UptimeRobot for `/health` | 10 min | Free |
| 4 | Add automated database backups (cron + S3) | 2 hours | ~$2/mo |
| 5 | Add in-app review prompts (iOS + Android) | 2 hours | Free |
| 6 | Add API rate limiting (`hammer` library) | 2 hours | Free |

### Week 3-4: Foundation for growth

| # | Task | Effort | Cost |
|---|------|--------|------|
| 7 | Integrate PostHog analytics (backend + mobile) | 4 hours | Free tier |
| 8 | Build landing page (replace Phoenix default) | 4 hours | Free |
| 9 | Add Fastlane metadata (descriptions, keywords) | 2 hours | Free |
| 10 | Build email onboarding drip (Oban + Swoosh) | 4 hours | ~$5/mo |
| 11 | Add Sobelow + CodeQL to CI | 1 hour | Free |
| 12 | Add Dialyzer to CI | 1 hour | Free |

### Month 2: Growth enablers

| # | Task | Effort | Cost |
|---|------|--------|------|
| 13 | Build referral system | 8 hours | Free |
| 14 | Set up staging environment | 4 hours | ~$20-40/mo |
| 15 | Add feature flags (FunWithFlags) | 3 hours | Free |
| 16 | Build push notification campaigns | 6 hours | Free |
| 17 | Terraform the infrastructure | 8 hours | Free |
| 18 | Automated app store screenshots | 4 hours | Free |

### Month 3+: Scale and optimize

| # | Task | Effort | Cost |
|---|------|--------|------|
| 19 | Strategy dashboard (LiveView) | 8 hours | Free |
| 20 | Review sentiment pipeline (LLM) | 4 hours | ~$5/mo |
| 21 | Load testing in CI (k6) | 4 hours | Free |
| 22 | Blue-green automated deploys | 4 hours | Free |
| 23 | Blog/content pipeline | 8 hours | $0-9/mo |
| 24 | GDPR privacy dashboard | 4 hours | Free |
| 25 | Unified version management script | 2 hours | Free |
| 26 | Automated changelog generation | 2 hours | Free |

---

## Cost Summary (Fully Automated)

| Category | Monthly Cost |
|----------|-------------|
| Infrastructure (VPS + DB + staging) | $80-120 |
| Monitoring (Sentry + UptimeRobot + Logflare) | $0-40 |
| Analytics (PostHog) | $0-50 |
| Marketing tools (ASO + social scheduler) | $30-115 |
| Email (AWS SES) | $5-20 |
| Backups (S3) | $2-5 |
| Blog (Ghost, optional) | $0-9 |
| **Total** | **$120-360/mo** |

Most automation is custom code rather than paid services. The Elixir/Phoenix stack handles high concurrency efficiently, keeping infrastructure costs low.

---

## Architecture Diagram

```
                        ┌─────────────────────────┐
                        │     GitHub Actions       │
                        │  CI/CD Orchestrator      │
                        └────────┬────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
     ┌────────────┐    ┌────────────┐    ┌────────────┐
     │  Backend   │    │  Android   │    │    iOS     │
     │  Elixir    │    │  Fastlane  │    │  Fastlane  │
     │  Release   │    │  Play Store│    │  App Store │
     └─────┬──────┘    └────────────┘    └────────────┘
           │
           ▼
    ┌──────────────┐     ┌──────────────┐
    │  Production  │────▶│   Staging    │
    │  Server      │     │   Server     │
    └──────┬───────┘     └──────────────┘
           │
     ┌─────┼─────────────────────┐
     │     │                     │
     ▼     ▼                     ▼
┌────────┐ ┌──────────┐  ┌────────────┐
│PostgreSQL│ │   S3     │  │  AWS SES   │
│Database │ │ Backups  │  │  Email     │
└────────┘ └──────────┘  └────────────┘

     Monitoring & Analytics Layer
┌─────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐
│ Sentry  │ │ Uptime  │ │ PostHog  │ │ Logflare │
│ Errors  │ │ Robot   │ │ Analytics│ │ Logs     │
└────┬────┘ └────┬────┘ └────┬─────┘ └────┬─────┘
     │           │           │             │
     └───────────┴───────────┴─────────────┘
                      │
                      ▼
              ┌──────────────┐
              │ Alert Router │
              │ Slack/Email  │
              └──────────────┘
```

---

*Last updated: February 2026*
