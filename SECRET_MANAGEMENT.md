# Secret Management Guide - MeasureBowl

This document outlines the secret management strategy for the MeasureBowl application using Doppler.

## Overview

MeasureBowl uses [Doppler](https://www.doppler.com/) for centralized, secure secret management. This eliminates the need for local `.env` files and provides a single source of truth for all environment variables across development, staging, and production environments.

## Benefits

- **Centralized Management**: All secrets stored in one secure location
- **Type Safety**: TypeScript definitions provide IntelliSense and compile-time validation
- **Environment Isolation**: Separate secrets for dev, staging, and production
- **Team Collaboration**: Easy secret sharing without file transfers
- **Audit Trail**: Track who accessed what secrets and when
- **Automatic Rotation**: Support for secret rotation policies

## Prerequisites

1. **Doppler Account**: Sign up at [doppler.com](https://www.doppler.com/)
2. **Doppler CLI**: Install the CLI tool
   - **Windows (PowerShell)**:
     ```powershell
     # Using Scoop
     scoop install doppler
     
     # Or using Chocolatey
     choco install doppler
     
     # Or download from: https://docs.doppler.com/docs/install-cli
     ```
   - **macOS**:
     ```bash
     brew install doppler
     ```
   - **Linux**:
     ```bash
     curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
     echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
     sudo apt-get update && sudo apt-get install doppler
     ```

## Initial Setup

### 1. Login to Doppler

```bash
doppler login
```

This will open your browser to authenticate with Doppler.

### 2. Setup Project

```bash
# Navigate to project root
cd /path/to/MeasureBowl-Flutter-App

# Run setup (interactive)
doppler setup

# Or specify project and config directly
doppler setup --project measurebowl --config dev
```

### 3. Verify Configuration

```bash
doppler configure get
```

This should display your current project and config settings.

## Environment Variables Reference

### Database Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/dbname` |

### Security

| Variable | Description | Example |
|----------|-------------|---------|
| `JWT_SECRET` | Secret key for JWT token signing | `your-super-secret-jwt-key` |
| `API_KEY` | API key for protected endpoints | `your-api-key-here` |

### Server Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `PORT` | Server port number | `5000` |
| `NODE_ENV` | Environment mode | `development`, `production`, or `test` |

### OpenCV Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENCV_DEBUG` | Enable OpenCV debug logging | `true` or `false` |
| `OPENCV_LOG_LEVEL` | OpenCV log level | `error`, `warn`, `info`, or `debug` |

### Firebase Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_PROJECT_ID` | Firebase project identifier | `measurebowl-prod` |
| `FIREBASE_PRIVATE_KEY` | Firebase service account private key | `-----BEGIN PRIVATE KEY-----\n...` |
| `FIREBASE_CLIENT_EMAIL` | Firebase service account email | `firebase-adminsdk@project.iam.gserviceaccount.com` |

### Google Play Console

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_PLAY_CREDENTIALS` | Base64 encoded service account JSON | `eyJ0eXAiOiJKV1QiLCJhbGc...` |

### App Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_NAME` | Application name | `MeasureBowl` |
| `APP_VERSION` | Application version | `1.0.0` |

## Usage

### Running Commands with Doppler

#### Option 1: Using Doppler CLI Directly

```bash
# Run development server
doppler run -- npm run dev

# Run client only
doppler run -- npm run dev:client

# Run server only
doppler run -- npm run dev:server

# Run tests
doppler run -- npm test
```

#### Option 2: Using npm Scripts (Recommended)

```bash
# Development
npm run dev:doppler
npm run dev:client:doppler
npm run dev:server:doppler

# Testing
npm run test:doppler
```

### Accessing Secrets in Code

Secrets are automatically injected as environment variables. Use them as you would with `.env` files:

```typescript
// TypeScript with type safety
const dbUrl = process.env.DATABASE_URL;
const jwtSecret = process.env.JWT_SECRET;

// The environment.d.ts file provides IntelliSense
// and type checking for all environment variables
```

## Migration from .env Files

### Step 1: Export Existing Secrets

If you have existing `.env` files, export them to Doppler:

```bash
# For each environment variable in your .env file
doppler secrets set DATABASE_URL="postgresql://..."
doppler secrets set JWT_SECRET="your-secret"
# ... repeat for all variables
```

### Step 2: Bulk Import (Alternative)

You can also use Doppler's web dashboard to import secrets in bulk:

1. Go to your project in Doppler dashboard
2. Navigate to the appropriate config (dev/staging/prod)
3. Click "Import" and paste your `.env` file contents
4. Review and save

### Step 3: Update Team Workflows

Ensure all team members:
1. Install Doppler CLI
2. Run `doppler setup` in the project root
3. Use `npm run dev:doppler` instead of `npm run dev`

### Step 4: Remove .env Files

Once migration is complete and verified:

```bash
# Add to .gitignore (if not already present)
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
echo ".env.*.local" >> .gitignore

# Remove existing .env files (after backing up!)
# DO NOT commit .env files to git
```

## Environment Management

### Creating New Environments

```bash
# Create a new config (e.g., staging)
doppler setup --project measurebowl --config staging

# Set secrets for the new environment
doppler secrets set DATABASE_URL="staging-db-url"
# ... set other secrets
```

### Switching Between Environments

```bash
# Switch to production
doppler setup --project measurebowl --config prod

# Verify current config
doppler configure get
```

### Listing Secrets

```bash
# List all secrets (values hidden)
doppler secrets

# Get a specific secret value
doppler secrets get DATABASE_URL --plain
```

## Best Practices

1. **Never Commit Secrets**: Always use `.gitignore` to exclude `.env` files
2. **Use Different Secrets**: Each environment (dev/staging/prod) should have unique secrets
3. **Rotate Regularly**: Update secrets periodically, especially after team member changes
4. **Limit Access**: Only grant Doppler access to team members who need it
5. **Use Type Safety**: Always reference `shared/types/environment.d.ts` for available variables
6. **Document Changes**: Update this file when adding new environment variables

## Troubleshooting

### Doppler CLI Not Found

```bash
# Verify installation
doppler --version

# If not found, reinstall following platform-specific instructions above
```

### Authentication Issues

```bash
# Re-authenticate
doppler login

# Verify authentication
doppler me
```

### Wrong Project/Config

```bash
# Check current configuration
doppler configure get

# Reset configuration
doppler setup
```

### Secrets Not Loading

1. Verify you're in the correct project directory
2. Check that `doppler setup` has been run
3. Verify secrets exist in Doppler dashboard
4. Ensure you're using `doppler run --` prefix or npm scripts

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Install Doppler CLI
  uses: dopplerhq/cli-action@v3
  with:
    token: ${{ secrets.DOPPLER_TOKEN }}

- name: Run tests with secrets
  run: doppler run -- npm test
```

### Other Platforms

Refer to [Doppler's CI/CD documentation](https://docs.doppler.com/docs/ci-cd) for platform-specific integration guides.

## Additional Resources

- [Doppler Documentation](https://docs.doppler.com/)
- [Doppler CLI Reference](https://docs.doppler.com/docs/cli)
- [TypeScript Environment Types](./shared/types/environment.d.ts)
- [Doppler Configuration](./.doppler.yaml)

## Support

For issues or questions:
1. Check Doppler documentation: https://docs.doppler.com/
2. Review project-specific configuration in `.doppler.yaml`
3. Contact the project maintainer

