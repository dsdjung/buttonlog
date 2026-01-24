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
end
