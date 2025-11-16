# Firebase App Distribution Setup Guide

This guide will help you complete the setup for Firebase App Distribution in your Flutter Android app.

## ✅ What's Already Configured

I've already added the necessary Gradle configuration to your project:

1. **Firebase App Distribution Plugin** added to `android/app/build.gradle.kts`
2. **Custom Gradle Task** `distributeToQa` created for automated distribution
3. **Project-level dependencies** added to `android/build.gradle.kts`

## 🔧 Required Setup Steps

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add Android app with package name: `com.dojo.measurebowl`
4. Download `google-services.json` and place it in `flutter_app/android/app/`
5. Enable App Distribution in the Firebase Console

### 2. Get Firebase App ID

1. In Firebase Console, go to Project Settings
2. Copy your **App ID** (format: `1:123456789:android:abcdef123456`)
3. Replace `YOUR_FIREBASE_APP_ID` in `android/app/build.gradle.kts` with your actual App ID

### 3. Create Service Account

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file and save it securely
4. Update `serviceCredentialsFile` path in `android/app/build.gradle.kts` to point to this file

### 4. Set Up Tester Groups

1. In Firebase Console, go to App Distribution → Testers & Groups
2. Create a group called `qa-team`
3. Add tester email addresses to this group

## 🚀 Usage

Once setup is complete, you can distribute your app to testers with a single command:

```bash
cd flutter_app/android
./gradlew distributeToQa
```

This will:
- Build a release APK
- Upload it to Firebase App Distribution
- Send notifications to your `qa-team` testers
- Include release notes: "New QA build available for testing."

## 📱 Tester Experience

Your testers will:
1. Receive an email invitation
2. Click the link on their Android device
3. Follow the guided installation process
4. Install the app directly from the web interface

## 🔒 Security Notes

- Keep your service account key file secure and never commit it to version control
- Consider using environment variables for sensitive configuration
- The service account key should have only the necessary Firebase permissions

## 🛠️ Troubleshooting

### Common Issues:

1. **"App ID not found"**: Verify your Firebase App ID is correct
2. **"Service account not authorized"**: Check service account permissions
3. **"Group not found"**: Ensure `qa-team` group exists in Firebase Console
4. **Build failures**: Make sure you have a valid signing configuration

### Debug Commands:

```bash
# Check available Gradle tasks
./gradlew tasks --group=distribution

# Run with debug output
./gradlew distributeToQa --info

# Test build only
./gradlew assembleRelease
```

## 📋 Next Steps

1. Complete the Firebase project setup
2. Update the configuration with your actual values
3. Test the distribution workflow
4. Add more tester groups as needed
5. Consider setting up CI/CD integration for automated releases

---

**Need help?** Check the [Firebase App Distribution documentation](https://firebase.google.com/docs/app-distribution) for detailed setup instructions.
