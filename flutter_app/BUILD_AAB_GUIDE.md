# Building Android App Bundle (AAB) for MeasureBowl

## Overview

The **Android App Bundle (`.aab`)** file is the compiled, signed package that you upload to Google Play Console. Unlike native Android development, Flutter apps use **Flutter CLI commands** to build AAB files, not Android Studio's build system.

## Key Concepts

### What is an `.aab` File?

- **Your Code:** The `.dart`, `.kt`, `.java` files you write are the *source code* (the recipe)
- **The `.aab` File:** This is the *compiled, signed, packaged app* ready for Google Play (the finished meal)

The `.aab` file is **not** in your source code—you must **build** it from your code.

### Flutter vs Native Android

For **Flutter apps**, you use:
```bash
flutter build appbundle --release
```

For **native Android apps**, you use Android Studio's GUI or Gradle commands.

## Prerequisites

Before building your AAB file, ensure you have:

1. ✅ **Flutter SDK** installed (3.24.5+)
2. ✅ **Java Development Kit (JDK)** installed (version 17 recommended)
3. ✅ **Signing Keystore** configured (already set up for this project)
4. ✅ **Android SDK** installed via Flutter

### Verify Your Setup

```bash
# Check Flutter installation
flutter doctor

# Check if keystore exists
ls flutter_app/android/app/upload-keystore.jks

# Check key.properties configuration
cat flutter_app/android/key.properties
```

## Building the AAB File

### Step 1: Navigate to Flutter App Directory

```bash
cd flutter_app
```

### Step 2: Get Dependencies

```bash
flutter pub get
```

### Step 3: Build the Release AAB

```bash
flutter build appbundle --release
```

### Step 4: Locate Your AAB File

After the build completes successfully, your AAB file will be located at:

```
flutter_app/build/app/outputs/bundle/release/app-release.aab
```

## Signing Configuration

Your project is already configured with signing:

### Keystore Location
- **File:** `flutter_app/android/app/upload-keystore.jks`
- **Configuration:** `flutter_app/android/key.properties`

### Signing Configuration (Already Set Up)

The signing is configured in `flutter_app/android/app/build.gradle`:

```52:93:flutter_app/android/app/build.gradle
    signingConfigs {
        release {
            if (keystoreProperties.getProperty('storeFile')) {
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
            }
        }
    }

    defaultConfig {
        applicationId "com.dojo.measurebowl"
        // Camera plugin and opencv_dart require minSdkVersion 24
        minSdkVersion 24
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // NDK configuration for opencv_dart native libraries
        externalNativeBuild {
            cmake {
                cppFlags "-frtti -fexceptions"
                abiFilters 'armeabi-v7a', 'arm64-v8a'
            }
        }
        
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a'
        }
    }

    buildTypes {
        release {
            // Use upload keystore if configured
            if (keystoreProperties.getProperty('storeFile')) {
                signingConfig signingConfigs.release
            }
            minifyEnabled false
            shrinkResources false
        }
    }
```

⚠️ **IMPORTANT:** Keep your keystore file (`upload-keystore.jks`) and `key.properties` **secure and backed up**. If you lose the keystore, you cannot update your app on Google Play!

## Complete Build Process

### Quick Build Command

```bash
# From project root
cd flutter_app
flutter pub get
flutter build appbundle --release
```

### Build Script (PowerShell)

You can also use the existing CI/CD script:

```powershell
# From project root
.\ci_cd_pipeline.ps1 -Action build -Platform android -BuildType release
```

## Uploading to Google Play Console

### Step 1: Access Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app: **MeasureBowl** (package: `com.dojo.measurebowl`)

### Step 2: Navigate to Release

1. In the left sidebar, go to **Production** (or **Internal testing** / **Closed testing**)
2. Click **Create new release**

### Step 3: Upload AAB File

1. Click **Upload** or drag and drop your AAB file
2. Select the file: `flutter_app/build/app/outputs/bundle/release/app-release.aab`
3. Wait for Google Play to process the upload

### Step 4: Complete Release

1. Add release notes if required
2. Review the release
3. Click **Save** (for draft) or **Review release** → **Start rollout**

## Troubleshooting

### Build Fails with "Keystore not found"

**Solution:** Ensure `key.properties` points to the correct keystore path:

```properties
storeFile=app/upload-keystore.jks
```

The path is relative to `flutter_app/android/`.

### Build Fails with "Signing config error"

**Solution:** Verify `key.properties` has all required properties:

```properties
storeFile=app/upload-keystore.jks
storePassword=your_password
keyAlias=upload
keyPassword=your_password
```

### Build Takes Too Long

**Solution:** Clean build files first:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter build appbundle --release
```

### AAB File Not Found After Build

**Solution:** Check the build output for errors:

```bash
flutter build appbundle --release --verbose
```

The file should be at: `build/app/outputs/bundle/release/app-release.aab`

### Version Code Conflicts

**Solution:** Update version in `pubspec.yaml`:

```yaml
version: 1.0.1+2  # versionName + versionCode
```

Then rebuild.

## Advanced: Using Fastlane (Automated)

The project includes Fastlane configuration for automated deployment:

```bash
cd flutter_app/android
bundle install
bundle exec fastlane android internal
```

See `flutter_app/android/fastlane/Fastfile` for configuration.

## Version Management

### Update Version Before Building

Edit `flutter_app/pubspec.yaml`:

```yaml
version: 1.0.1+2  # Format: versionName+versionCode
```

- **versionName:** User-facing version (e.g., "1.0.1")
- **versionCode:** Integer that must increase with each release (e.g., 2)

### Check Current Version

```bash
cd flutter_app
flutter pub get
grep "version:" pubspec.yaml
```

## Build Variants

### Release Build (for Google Play)

```bash
flutter build appbundle --release
```

### Debug Build (for testing)

```bash
flutter build apk --debug
```

Note: Google Play requires **AAB** files, not APK files for production releases.

## File Locations Summary

| File/Path | Location | Purpose |
|-----------|----------|---------|
| AAB Output | `flutter_app/build/app/outputs/bundle/release/app-release.aab` | Final file to upload |
| Keystore | `flutter_app/android/app/upload-keystore.jks` | Signing certificate |
| Key Config | `flutter_app/android/key.properties` | Keystore credentials |
| Build Config | `flutter_app/android/app/build.gradle` | Android build settings |

## Next Steps After Building

1. ✅ **Test the AAB** locally (optional):
   ```bash
   # Install via ADB (if you have a device connected)
   bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=local-testing
   bundletool install-apks --apks=app.apks
   ```

2. ✅ **Upload to Google Play Console** (see section above)

3. ✅ **Monitor release** in Google Play Console

4. ✅ **Update documentation** if version changed

## Additional Resources

- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Project CI/CD Pipeline](../CI_CD_README.md)

---

**Last Updated:** 2025-01-20  
**Flutter Version:** 3.24.5  
**App Package:** com.dojo.measurebowl

