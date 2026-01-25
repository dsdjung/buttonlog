defmodule ButtonLog.Emails do
  @moduledoc """
  Email templates for ButtonLog.

  Email sender configuration can be set via environment variables:
  - SES_FROM_EMAIL: The sender email address (must be verified in AWS SES)
  - SES_FROM_NAME: The display name for the sender

  Default values are used if not configured.
  """

  import Swoosh.Email

  # Default values - can be overridden via config
  @default_from_email "noreply@buttonlog.app"
  @default_from_name "ButtonLog"

  @doc """
  Returns the configured sender email address.
  """
  def from_email do
    get_in(Application.get_env(:buttonlog, :email, []), [:from_address]) || @default_from_email
  end

  @doc """
  Returns the configured sender display name.
  """
  def from_name do
    get_in(Application.get_env(:buttonlog, :email, []), [:from_name]) || @default_from_name
  end

  # App store URLs (update these with actual store links when published)
  @app_store_url "https://apps.apple.com/app/buttonlog"
  @play_store_url "https://play.google.com/store/apps/details?id=com.buttonlog.app"

  @doc """
  Sends an invitation email to someone who isn't registered yet.
  """
  def friend_invitation(to_email, inviter_name) do
    new()
    |> to(to_email)
    |> from({from_name(), from_email()})
    |> subject("#{inviter_name} invited you to join ButtonLog!")
    |> html_body(friend_invitation_html(inviter_name))
    |> text_body(friend_invitation_text(inviter_name))
  end

  defp friend_invitation_html(inviter_name) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Join ButtonLog</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          text-align: center;
          padding: 20px 0;
        }
        .logo {
          font-size: 32px;
          font-weight: bold;
          color: #00BFA5;
        }
        .content {
          background: #f9f9f9;
          border-radius: 12px;
          padding: 30px;
          margin: 20px 0;
        }
        h1 {
          color: #333;
          font-size: 24px;
          margin-bottom: 20px;
        }
        p {
          margin: 15px 0;
        }
        .cta-container {
          text-align: center;
          margin: 30px 0;
        }
        .cta-button {
          display: inline-block;
          background: #00BFA5;
          color: white !important;
          text-decoration: none;
          padding: 14px 28px;
          border-radius: 8px;
          font-weight: 600;
          margin: 10px;
        }
        .store-buttons {
          text-align: center;
          margin: 20px 0;
        }
        .store-button {
          display: inline-block;
          margin: 5px 10px;
          text-decoration: none;
        }
        .footer {
          text-align: center;
          color: #666;
          font-size: 14px;
          margin-top: 30px;
          padding-top: 20px;
          border-top: 1px solid #eee;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="logo">ButtonLog</div>
      </div>

      <div class="content">
        <h1>You've been invited!</h1>
        <p>
          <strong>#{inviter_name}</strong> wants to connect with you on ButtonLog -
          the app that helps you track habits, activities, and life moments with just a tap.
        </p>
        <p>
          With ButtonLog, you can:
        </p>
        <ul>
          <li>Create custom buttons to track anything</li>
          <li>Share your progress with friends</li>
          <li>View your activity history and patterns</li>
          <li>Get notified when friends hit their goals</li>
        </ul>

        <div class="cta-container">
          <p><strong>Download ButtonLog and connect with #{inviter_name}:</strong></p>
          <div class="store-buttons">
            <a href="#{@app_store_url}" class="cta-button">App Store</a>
            <a href="#{@play_store_url}" class="cta-button">Google Play</a>
          </div>
        </div>
      </div>

      <div class="footer">
        <p>
          This invitation was sent by #{inviter_name} via ButtonLog.<br>
          If you didn't expect this email, you can safely ignore it.
        </p>
      </div>
    </body>
    </html>
    """
  end

  defp friend_invitation_text(inviter_name) do
    """
    You've been invited to join ButtonLog!

    #{inviter_name} wants to connect with you on ButtonLog - the app that helps you track habits, activities, and life moments with just a tap.

    With ButtonLog, you can:
    - Create custom buttons to track anything
    - Share your progress with friends
    - View your activity history and patterns
    - Get notified when friends hit their goals

    Download ButtonLog and connect with #{inviter_name}:

    App Store: #{@app_store_url}
    Google Play: #{@play_store_url}

    ---
    This invitation was sent by #{inviter_name} via ButtonLog.
    If you didn't expect this email, you can safely ignore it.
    """
  end

  @doc """
  Sends an email notification when a user's trial is about to end.
  Stripe sends this event 3 days before the trial ends.
  """
  def trial_ending(to_email, user_name, plan_name, trial_end_date) do
    formatted_date = Calendar.strftime(trial_end_date, "%B %d, %Y")
    days_left = calculate_days_until(trial_end_date)

    new()
    |> to(to_email)
    |> from({from_name(), from_email()})
    |> subject("Your #{plan_name} trial ends in #{days_left} days")
    |> html_body(trial_ending_html(user_name, plan_name, formatted_date, days_left))
    |> text_body(trial_ending_text(user_name, plan_name, formatted_date, days_left))
  end

  defp calculate_days_until(end_date) do
    now = DateTime.utc_now()
    diff = DateTime.diff(end_date, now, :day)
    max(diff, 0)
  end

  defp trial_ending_html(user_name, plan_name, formatted_date, days_left) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Your Trial is Ending</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          text-align: center;
          padding: 20px 0;
        }
        .logo {
          font-size: 32px;
          font-weight: bold;
          color: #00BFA5;
        }
        .content {
          background: #f9f9f9;
          border-radius: 12px;
          padding: 30px;
          margin: 20px 0;
        }
        .alert-box {
          background: #FFF3E0;
          border: 1px solid #FF9800;
          border-radius: 8px;
          padding: 15px;
          margin: 20px 0;
          text-align: center;
        }
        .alert-box .days {
          font-size: 36px;
          font-weight: bold;
          color: #FF9800;
        }
        h1 {
          color: #333;
          font-size: 24px;
          margin-bottom: 20px;
        }
        p {
          margin: 15px 0;
        }
        .cta-container {
          text-align: center;
          margin: 30px 0;
        }
        .cta-button {
          display: inline-block;
          background: #00BFA5;
          color: white !important;
          text-decoration: none;
          padding: 14px 28px;
          border-radius: 8px;
          font-weight: 600;
        }
        .feature-list {
          background: #E8F5E9;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        .feature-list h3 {
          color: #2E7D32;
          margin-top: 0;
        }
        .footer {
          text-align: center;
          color: #666;
          font-size: 14px;
          margin-top: 30px;
          padding-top: 20px;
          border-top: 1px solid #eee;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="logo">ButtonLog</div>
      </div>

      <div class="content">
        <h1>Hi #{user_name},</h1>

        <div class="alert-box">
          <div class="days">#{days_left}</div>
          <div>days left in your trial</div>
        </div>

        <p>
          Your <strong>#{plan_name}</strong> free trial will end on <strong>#{formatted_date}</strong>.
        </p>

        <p>
          After your trial ends, your subscription will automatically continue and you'll be charged
          based on your selected billing cycle. No action is needed to continue enjoying all the
          premium features you've been using.
        </p>

        <div class="feature-list">
          <h3>What you'll keep with #{plan_name}:</h3>
          <ul>
            <li>Unlimited buttons and tracking</li>
            <li>Extended friend connections</li>
            <li>Full click history</li>
            <li>Priority support</li>
          </ul>
        </div>

        <p>
          Want to make changes? You can update your plan or cancel anytime from your account settings.
        </p>

        <div class="cta-container">
          <a href="https://buttonlog.app/account" class="cta-button">Manage Subscription</a>
        </div>
      </div>

      <div class="footer">
        <p>
          Questions? Reply to this email or visit our <a href="https://buttonlog.app/support">Help Center</a>.
        </p>
        <p>
          ButtonLog - Track what matters to you
        </p>
      </div>
    </body>
    </html>
    """
  end

  defp trial_ending_text(user_name, plan_name, formatted_date, days_left) do
    """
    Hi #{user_name},

    YOUR TRIAL IS ENDING SOON
    #{days_left} days left

    Your #{plan_name} free trial will end on #{formatted_date}.

    After your trial ends, your subscription will automatically continue and you'll be charged
    based on your selected billing cycle. No action is needed to continue enjoying all the
    premium features you've been using.

    What you'll keep with #{plan_name}:
    - Unlimited buttons and tracking
    - Extended friend connections
    - Full click history
    - Priority support

    Want to make changes? You can update your plan or cancel anytime from your account settings:
    https://buttonlog.app/account

    ---
    Questions? Reply to this email or visit our Help Center at https://buttonlog.app/support
    ButtonLog - Track what matters to you
    """
  end
end
