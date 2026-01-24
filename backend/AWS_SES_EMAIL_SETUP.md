# AWS SES Email Setup

ButtonLog uses AWS Simple Email Service (SES) for sending transactional emails in production.

## Prerequisites

1. **AWS Account**: You need an AWS account with SES access
2. **Verified Domain/Email**: At least one verified sender email or domain in SES
3. **IAM User**: An IAM user with SES permissions

## AWS Setup

### 1. Verify Your Sender Email/Domain

1. Go to AWS SES Console > Verified identities
2. Click "Create identity"
3. Choose either:
   - **Email address**: Verify a specific email (good for testing)
   - **Domain**: Verify an entire domain (recommended for production)
4. Follow the verification steps (email confirmation or DNS records)

### 2. Create IAM User for SES

1. Go to AWS IAM Console > Users
2. Click "Create user"
3. Name it something like `buttonlog-ses-sender`
4. Attach the following policy (or create a custom one):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }
    ]
}
```

5. Create access keys for the user
6. Save the Access Key ID and Secret Access Key securely

### 3. Request Production Access (if needed)

By default, SES is in sandbox mode which limits sending:
- Can only send to verified email addresses
- Limited sending rate

To request production access:
1. Go to AWS SES Console
2. Look for "Request production access" in the banner
3. Fill out the request form with your use case

## Application Configuration

### Environment Variables

Add these to your `.env` file or production environment:

```bash
# AWS SES Email Configuration
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
export SES_FROM_EMAIL="noreply@yourdomain.com"
export SES_FROM_NAME="ButtonLog"
```

### Configuration Details

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `AWS_ACCESS_KEY_ID` | IAM user access key | Yes | - |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key | Yes | - |
| `AWS_REGION` | AWS region for SES | No | `us-east-1` |
| `SES_FROM_EMAIL` | Verified sender email | No | `noreply@buttonlog.com` |
| `SES_FROM_NAME` | Display name for sender | No | `ButtonLog` |

## How It Works

1. **Development/Test**: Uses Swoosh Local adapter (no actual emails sent)
2. **Production**: When AWS credentials are present, uses AWS SES via ExAws

The configuration automatically switches adapters based on environment:

```elixir
# In dev/test - emails stored locally, viewable at /dev/mailbox
config :buttonlog, ButtonLog.Mailer,
  adapter: Swoosh.Adapters.Local

# In production with AWS credentials - real emails sent via SES
config :buttonlog, ButtonLog.Mailer,
  adapter: Swoosh.Adapters.ExAwsAmazonSES,
  region: "us-east-1"
```

## Testing

### View Development Emails

In development, emails are captured locally. Access them at:
```
http://localhost:4000/dev/mailbox
```

### Test SES in Production

1. Deploy with SES configuration
2. Trigger an email action (e.g., friend invitation)
3. Check AWS SES Console > Email sending > Sending statistics

## Troubleshooting

### Common Errors

**"Email address is not verified"**
- The from email must be verified in SES
- In sandbox mode, the recipient must also be verified

**"Access Denied"**
- Check IAM user has `ses:SendEmail` permission
- Verify access key/secret are correct

**"Region mismatch"**
- Ensure `AWS_REGION` matches where your SES is configured
- Some regions require explicit activation for SES

**No emails being sent in production**
- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set
- Check application logs for SES errors
- Verify sender email is verified in SES

### Viewing Logs

Check application logs for SES-related errors:
```bash
# In production logs, look for:
# - "SES" or "ex_aws" related messages
# - "email" or "mailer" related messages
```

## Security Notes

- Never commit AWS credentials to version control
- Use environment variables or secrets management
- Consider using IAM roles instead of access keys in AWS environments (EC2, ECS, Lambda)
- Rotate access keys periodically
- Use the principle of least privilege for IAM permissions
