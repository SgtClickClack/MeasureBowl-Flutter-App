# MeasureBowl CI/CD Pipeline

This document describes the CI/CD pipeline setup for the MeasureBowl Flutter application.

## Overview

The CI/CD pipeline includes:
- **Code Analysis**: Flutter analyze and formatting checks
- **Testing**: Unit tests with coverage reporting
- **Building**: Multi-platform builds (Android, iOS, Web)
- **Deployment**: Automated deployment to Google Play Store

## Prerequisites

### Local Development Setup

1. **Install Flutter SDK**:
   ```powershell
   .\setup_flutter.ps1
   ```

2. **Verify Installation**:
   ```powershell
   flutter doctor -v
   ```

3. **Install Dependencies**:
   ```powershell
   cd flutter_app
   flutter pub get
   ```

### CI/CD Requirements

- **GitHub Actions**: Automated CI/CD runs on GitHub
- **Google Play Console**: For Android app deployment
- **Fastlane**: For automated deployment (optional for local)

## Pipeline Scripts

### 1. Flutter Setup Script (`setup_flutter.ps1`)
Automatically downloads and installs Flutter SDK on Windows.

### 2. CI/CD Pipeline Script (`ci_cd_pipeline.ps1`)
Local CI/CD pipeline script with the following actions:

```powershell
# Clean project
.\ci_cd_pipeline.ps1 -Action clean

# Run tests
.\ci_cd_pipeline.ps1 -Action test

# Analyze code
.\ci_cd_pipeline.ps1 -Action analyze

# Build Android debug
.\ci_cd_pipeline.ps1 -Action build -Platform android -BuildType debug

# Build Android release
.\ci_cd_pipeline.ps1 -Action build -Platform android -BuildType release

# Build all platforms
.\ci_cd_pipeline.ps1 -Action build -Platform all

# Deploy (requires Fastlane setup)
.\ci_cd_pipeline.ps1 -Action deploy -Platform android
```

## GitHub Actions Workflow

The `.github/workflows/ci-cd.yml` file defines the automated pipeline:

### Triggers
- **Push to main/develop**: Automatic build and test
- **Pull Requests**: Code analysis and testing
- **Manual Dispatch**: Build specific platforms

### Jobs

1. **analyze**: Code analysis and formatting checks
2. **test**: Unit tests with coverage reporting
3. **build-android**: Android APK/AAB builds
4. **build-ios**: iOS app builds (macOS runners)
5. **build-web**: Web application builds
6. **deploy-android**: Automated deployment to Google Play

## Configuration Files

### Android Configuration
- **Package Name**: `com.dojo.measurebowl`
- **Min SDK**: 24 (required for camera and OpenCV)
- **Target SDK**: Latest Flutter target
- **Signing**: Uses `upload-keystore.jks` for release builds

### Fastlane Configuration
- **Android Fastfile**: `flutter_app/android/fastlane/Fastfile`
- **Appfile**: `flutter_app/android/fastlane/Appfile`
- **Credentials**: Stored in `fastlane/` directory

## Common Issues and Solutions

### 1. Flutter Not Found
**Error**: `flutter: The term 'flutter' is not recognized`

**Solution**:
```powershell
.\setup_flutter.ps1
# Restart terminal after installation
```

### 2. Build Failures
**Error**: Android build fails

**Solutions**:
- Check Android SDK installation: `flutter doctor`
- Verify keystore file exists: `android/app/upload-keystore.jks`
- Check package name consistency

### 3. OpenCV Issues
**Error**: OpenCV native library not available

**Solutions**:
- Ensure `opencv_dart` dependency is properly configured
- Check NDK configuration in `build.gradle`
- Verify ABI filters include required architectures

### 4. Fastlane Deployment Issues
**Error**: Fastlane deployment fails

**Solutions**:
- Install Ruby and Bundler
- Run `bundle install` in `flutter_app/android/`
- Configure Google Play Console credentials
- Verify package name matches Play Console

## Environment Variables

### GitHub Secrets
- `GOOGLE_PLAY_CREDENTIALS`: JSON credentials for Play Console API

### Local Environment
- `FLUTTER_ROOT`: Flutter SDK installation path
- `ANDROID_HOME`: Android SDK path
- `JAVA_HOME`: Java installation path

## Testing the Pipeline

### Local Testing
```powershell
# Test code analysis
.\ci_cd_pipeline.ps1 -Action analyze

# Test build process
.\ci_cd_pipeline.ps1 -Action build -Platform android -BuildType debug

# Test full pipeline
.\ci_cd_pipeline.ps1 -Action build -Platform all
```

### GitHub Actions Testing
1. Push changes to trigger automatic pipeline
2. Use manual dispatch for specific platform builds
3. Check Actions tab for detailed logs

## Monitoring and Debugging

### Local Debugging
- Check Flutter doctor output
- Review build logs for specific errors
- Verify file paths and permissions

### GitHub Actions Debugging
- Check Actions tab for workflow runs
- Review job logs for specific failures
- Use artifacts to download build outputs

## Best Practices

1. **Always run tests locally** before pushing
2. **Use feature branches** for development
3. **Review code analysis** results before merging
4. **Test on multiple platforms** before release
5. **Keep dependencies updated** regularly
6. **Monitor build times** and optimize as needed

## Troubleshooting Checklist

- [ ] Flutter SDK installed and in PATH
- [ ] Android SDK configured properly
- [ ] Keystore file exists and is valid
- [ ] Package names consistent across files
- [ ] Dependencies up to date (`flutter pub get`)
- [ ] Code passes analysis (`flutter analyze`)
- [ ] Tests pass (`flutter test`)
- [ ] Build succeeds locally before pushing
- [ ] GitHub secrets configured for deployment
- [ ] Fastlane credentials valid and accessible






