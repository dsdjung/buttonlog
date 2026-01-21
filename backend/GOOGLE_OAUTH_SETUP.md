# Google OAuth Setup Guide for ButtonLog

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API (if not already enabled)

## Step 2: Create OAuth 2.0 Credentials

1. In the Google Cloud Console, go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth 2.0 Client IDs**
3. Choose **Web application** as the application type
4. Set the following:
   - **Name**: ButtonLog Development
   - **Authorized JavaScript origins**: 
     - `http://localhost:4001`
   - **Authorized redirect URIs**:
     - `http://localhost:4001/auth/google/callback`

## Step 3: Get Your Credentials

After creating the OAuth client, you'll get:
- **Client ID** (looks like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`)
- **Client Secret** (looks like: `GOCSPX-abcdefghijklmnopqrstuvwxyz`)

## Step 4: Set Environment Variables

Create a `.env` file in your backend directory:

```bash
# .env file
export GOOGLE_CLIENT_ID="your-actual-client-id-here"
export GOOGLE_CLIENT_SECRET="your-actual-client-secret-here"
export GOOGLE_REDIRECT_URI="http://localhost:4001/auth/google/callback"
```

Then source it before starting your server:

```bash
source .env
mix phx.server
```

## Step 5: Test OAuth

1. Start your Phoenix server
2. Go to `http://localhost:4001/oauth-test`
3. Click "Sign in with Google"
4. You should be redirected to Google's consent screen
5. After authorization, you'll be redirected back to ButtonLog

## Troubleshooting

### Error: "invalid_client"
- Check that your Client ID and Client Secret are correct
- Ensure the redirect URI matches exactly
- Verify the OAuth client is configured for "Web application"

### Error: "redirect_uri_mismatch"
- Make sure the redirect URI in Google Console matches your app's callback URL
- Check for typos in the URI

### Error: "access_denied"
- User may have cancelled the OAuth flow
- Check that the Google+ API is enabled in your project

## Security Notes

- Never commit your `.env` file to version control
- Use different OAuth clients for development and production
- Regularly rotate your client secrets
- Monitor OAuth usage in Google Cloud Console


