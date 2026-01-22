# Script for populating the database. You can run it as:
#
#     $ mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ButtonLog.Repo.insert!(%ButtonLog.SomeSchema{})
#
# We recommend using the functions in `ButtonLog.Repo` such as
# `insert!`, `update!`, etc. as they will fail if something goes wrong.

alias ButtonLog.Repo
alias ButtonLog.Accounts.User
alias ButtonLog.Buttons.Button

# Create a test user
user = Repo.insert!(%User{
  email: "test@example.com",
  username: "testuser",
  password_hash: Bcrypt.hash_pwd_salt("password123"),
  display_name: "Test User",
  timezone: "UTC",
  language: "en",
  subscription_tier: "free",
  default_history_sharing: false,
  allow_friend_requests: true,
  profile_visibility: "public",
  activity_visibility: "public"
})

# Create some test buttons
Repo.insert!(%Button{
  user_id: user.id,
  name: "Coffee Break",
  description: "Track my coffee breaks",
  type: "instant",
  icon: "☕",
  color: "#8B4513",
  is_active: true,
  notifications_enabled: true,
  auto_stop_enabled: false,
  calendar_sync_enabled: false
})

Repo.insert!(%Button{
  user_id: user.id,
  name: "Work Session",
  description: "Track focused work time",
  type: "toggle",
  icon: "💼",
  color: "#4CAF50",
  is_active: true,
  notifications_enabled: true,
  auto_stop_enabled: true,
  calendar_sync_enabled: true
})

Repo.insert!(%Button{
  user_id: user.id,
  name: "Exercise",
  description: "Track workout sessions",
  type: "toggle",
  icon: "🏃",
  color: "#FF5722",
  is_active: true,
  notifications_enabled: false,
  auto_stop_enabled: false,
  calendar_sync_enabled: false
})

IO.puts("Database seeded with test data!")
IO.puts("Test user: test@example.com / password123")
IO.puts("Created 3 test buttons")
