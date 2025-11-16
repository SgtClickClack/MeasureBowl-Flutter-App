# Firebase CLI Setup Guide

This guide will help you configure Firebase App Distribution using the Firebase CLI, which is much more streamlined than manual configuration.

## 🔧 Step-by-Step Setup

### 1. Complete Firebase Login

Run this command in your terminal (in the `flutter_app/android` directory):

```bash
firebase login
```

**Follow these steps:**
1. Answer "n" to the Gemini question (unless you want to enable it)
2. A browser window will open for authentication
3. Sign in with your Google account
4. Grant permissions to Firebase CLI
5. Return to the terminal - you should see "Success! Logged in as [your-email]"

### 2. Initialize Firebase App Distribution

Once logged in, run:

```bash
firebase init appdistribution
```

**Configuration options:**
- **Select Firebase project**: Choose your existing project or create a new one
- **App ID**: This will be auto-detected from your `google-services.json` file
- **Groups**: Enter `qa-team` (or create this group in Firebase Console first)
- **Release notes**: Enter `New QA build available for testing.`

### 3. Verify Configuration

After initialization, you should see:
- `firebase.json` file created in your Android directory
- `google-services.json` file (if not already present)
- Updated Gradle configuration

### 4. Update Gradle Configuration

The CLI will automatically update your `build.gradle.kts` files, but let me show you what the final configuration should look like:

**In `android/app/build.gradle.kts`:**
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.firebase.appdistribution")
}

// Firebase App Distribution configuration
firebaseAppDistribution {
    appId = "1:YOUR_ACTUAL_APP_ID" // Auto-populated by CLI
    groups = "qa-team"
    releaseNotes = "New QA build available for testing."
}
```

### 5. Test the Setup

Once everything is configured, test with:

```bash
# Build and distribute to QA team
./gradlew distributeToQa

# Or use Firebase CLI directly
firebase appdistribution:distribute app/build/outputs/apk/release/app-release.apk --groups qa-team
```

## 🚀 Usage Commands

### Using Gradle Task (Recommended)
```bash
./gradlew distributeToQa
```

### Using Firebase CLI Directly
```bash
# Build first
./gradlew assembleRelease

# Then distribute
firebase appdistribution:distribute app/build/outputs/apk/release/app-release.apk --groups qa-team --release-notes "New QA build available for testing."
```

### Advanced CLI Options
```bash
# Distribute with custom release notes
firebase appdistribution:distribute app/build/outputs/apk/release/app-release.apk --groups qa-team --release-notes "Bug fixes and performance improvements"

# Distribute to multiple groups
firebase appdistribution:distribute app/build/outputs/apk/release/app-release.apk --groups qa-team,beta-testers

# Distribute with custom app ID
firebase appdistribution:distribute app/build/outputs/apk/release/app-release.apk --app-id "1:123456789:android:abcdef" --groups qa-team
```

## 📱 Tester Management

### Add Testers via CLI
```bash
# Add individual tester
firebase appdistribution:testers:add user@example.com

# Add tester to group
firebase appdistribution:testers:add user@example.com --group qa-team

# List all testers
firebase appdistribution:testers:list

# List testers in group
firebase appdistribution:testers:list --group qa-team
```

### Manage Groups via CLI
```bash
# Create group
firebase appdistribution:groups:create qa-team

# List groups
firebase appdistribution:groups:list

# Add tester to group
firebase appdistribution:groups:add qa-team user@example.com
```

## 🔍 Troubleshooting

### Common Issues:

1. **"Not authenticated"**: Run `firebase login` again
2. **"App not found"**: Ensure `google-services.json` is in `app/` directory
3. **"Group not found"**: Create the group in Firebase Console or via CLI
4. **Build failures**: Check your signing configuration

### Debug Commands:
```bash
# Check Firebase project
firebase projects:list

# Check app configuration
firebase apps:list

# Verify app distribution setup
firebase appdistribution:releases:list
```

## 📋 Next Steps

1. Complete the Firebase login
2. Run `firebase init appdistribution`
3. Test the distribution workflow
4. Add your testers to the `qa-team` group
5. Set up CI/CD integration if needed

---

**Need help?** Check the [Firebase CLI documentation](https://firebase.google.com/docs/cli) for more advanced usage.
