# MeasureBowl Troubleshooting Guide

## Quick Diagnostics

### Check System Status
```bash
# Flutter doctor
flutter doctor -v

# Node.js version
node --version
npm --version

# Database connection
psql $DATABASE_URL -c "SELECT 1;"
```

## Common Issues and Solutions

### Flutter App Issues

#### 1. Camera Not Working

**Symptoms:**
- Camera preview shows black screen
- "Camera not available" error
- App crashes when taking photos

**Solutions:**
```bash
# Check camera permissions
flutter doctor -v

# Clean and rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean
flutter build apk --debug

# Check Android manifest permissions
# Ensure these are in android/app/src/main/AndroidManifest.xml:
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

**Debug Steps:**
1. Check device camera permissions in settings
2. Test with different devices
3. Check camera availability in other apps
4. Review Flutter camera plugin documentation

#### 2. OpenCV Processing Failures

**Symptoms:**
- "OpenCV native library not available" error
- Image processing returns empty results
- App crashes during image processing

**Solutions:**
```bash
# Rebuild with OpenCV support
flutter clean
flutter pub get
cd android && ./gradlew clean
flutter build apk --debug

# Check NDK configuration in android/app/build.gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a'
        }
    }
}
```

**Debug Steps:**
1. Test with sample images
2. Check OpenCV version compatibility
3. Verify NDK installation
4. Test on different device architectures

#### 3. Build Failures

**Symptoms:**
- Gradle build errors
- Missing dependencies
- Version conflicts

**Solutions:**
```bash
# Clean everything
flutter clean
rm -rf android/.gradle
rm -rf android/build
rm -rf android/app/build

# Reinstall dependencies
flutter pub get
cd android && ./gradlew clean

# Check Flutter version
flutter --version
flutter upgrade

# Check Android SDK
flutter doctor -v
```

#### 4. App Crashes on Launch

**Symptoms:**
- App closes immediately after opening
- White/black screen on launch
- Crash logs in device logs

**Solutions:**
```bash
# Check for null safety issues
flutter analyze

# Run in debug mode for detailed logs
flutter run --debug

# Check device compatibility
flutter doctor -v

# Test on different devices
```

### Web Application Issues

#### 1. Build Failures

**Symptoms:**
- Vite build errors
- TypeScript compilation errors
- Missing dependencies

**Solutions:**
```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node.js version
node --version  # Should be 18+

# Clear npm cache
npm cache clean --force

# Rebuild
npm run build
```

#### 2. OpenCV.js Not Loading

**Symptoms:**
- "OpenCV not loaded" error
- Camera processing fails
- Large bundle size

**Solutions:**
```bash
# Check OpenCV.js loading
# Verify opencv.js is in public directory
ls client/public/opencv.js

# Check network requests in browser dev tools
# Ensure OpenCV.js loads successfully

# Consider lazy loading OpenCV.js
# Implement loading states
```

#### 3. API Connection Issues

**Symptoms:**
- Network errors
- CORS issues
- Authentication failures

**Solutions:**
```bash
# Check server status
curl http://localhost:5000/health

# Check environment variables
echo $DATABASE_URL
echo $JWT_SECRET

# Test API endpoints
curl -X GET http://localhost:5000/api/measurements
```

### Server Issues

#### 1. Database Connection Problems

**Symptoms:**
- "Connection refused" errors
- Database timeout errors
- Migration failures

**Solutions:**
```bash
# Test database connection
psql $DATABASE_URL -c "SELECT 1;"

# Check database status
# For Neon: Check dashboard
# For local: sudo systemctl status postgresql

# Reset database
npm run db:push

# Check connection string format
# Should be: postgresql://user:pass@host:port/dbname
```

#### 2. Authentication Issues

**Symptoms:**
- JWT token errors
- API key validation failures
- Permission denied errors

**Solutions:**
```bash
# Check JWT secret
echo $JWT_SECRET

# Verify API key
echo $API_KEY

# Test authentication
curl -H "Authorization: Bearer <token>" http://localhost:5000/api/settings
```

#### 3. Performance Issues

**Symptoms:**
- Slow response times
- High memory usage
- Timeout errors

**Solutions:**
```bash
# Check server logs
npm run logs

# Monitor resource usage
top
htop

# Check database performance
# Enable query logging
# Review slow queries
```

## Development Environment Issues

### 1. Flutter SDK Issues

**Symptoms:**
- "flutter command not found"
- Version conflicts
- Path issues

**Solutions:**
```bash
# Install Flutter SDK
# Download from https://flutter.dev/docs/get-started/install

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor -v

# Fix common issues
flutter doctor --android-licenses
```

### 2. Node.js Issues

**Symptoms:**
- Version conflicts
- Permission errors
- Package installation failures

**Solutions:**
```bash
# Use Node Version Manager (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Fix permissions
sudo chown -R $(whoami) ~/.npm
npm config set prefix ~/.npm-global
```

### 3. IDE Issues

**Symptoms:**
- IntelliSense not working
- Extension conflicts
- Performance issues

**Solutions:**
```bash
# VS Code
# Install Flutter and Dart extensions
# Reload window: Ctrl+Shift+P -> "Developer: Reload Window"

# Android Studio
# Update Flutter and Dart plugins
# Invalidate caches: File -> Invalidate Caches and Restart
```

## Testing Issues

### 1. Unit Test Failures

**Symptoms:**
- Tests failing locally
- Coverage issues
- Mock problems

**Solutions:**
```bash
# Flutter tests
flutter test
flutter test --coverage

# Server tests
npm test
npm run test:coverage

# Check test environment
# Ensure test database is configured
# Verify mock data
```

### 2. Integration Test Issues

**Symptoms:**
- Tests failing on CI
- Device-specific failures
- Timeout issues

**Solutions:**
```bash
# Run integration tests locally
flutter test integration_test/

# Check device availability
flutter devices

# Run with verbose output
flutter test integration_test/ --verbose
```

## Deployment Issues

### 1. Build Pipeline Failures

**Symptoms:**
- GitHub Actions failing
- Build timeouts
- Artifact upload failures

**Solutions:**
```bash
# Check workflow logs
# Review GitHub Actions tab

# Test locally
./ci_cd_pipeline.ps1 -Action build -Platform android

# Check environment variables
# Verify secrets are configured
```

### 2. App Store Rejections

**Symptoms:**
- Google Play rejection
- App Store rejection
- Policy violations

**Solutions:**
```bash
# Check app permissions
# Review privacy policy
# Test on different devices
# Follow platform guidelines

# Common issues:
# - Missing privacy policy
# - Inappropriate permissions
# - Crash on launch
# - Missing app icons
```

## Performance Issues

### 1. Slow App Launch

**Symptoms:**
- Long startup time
- White screen delay
- Memory issues

**Solutions:**
```bash
# Flutter performance
flutter build apk --analyze-size
flutter build apk --split-per-abi

# Check app size
# Remove unused dependencies
# Optimize images
# Enable R8/ProGuard
```

### 2. Memory Leaks

**Symptoms:**
- App becomes slow over time
- Crashes after extended use
- High memory usage

**Solutions:**
```bash
# Check for memory leaks
# Use Flutter Inspector
# Profile memory usage
# Review dispose methods
# Check for circular references
```

## Security Issues

### 1. Credential Exposure

**Symptoms:**
- API keys in logs
- Secrets in code
- Unauthorized access

**Solutions:**
```bash
# Check for exposed secrets
grep -r "password\|secret\|key" --exclude-dir=node_modules .

# Use environment variables
# Rotate compromised keys
# Review access logs
```

### 2. Input Validation Issues

**Symptoms:**
- XSS attacks
- SQL injection
- Data corruption

**Solutions:**
```bash
# Review input validation
# Check sanitization
# Test with malicious input
# Update dependencies
```

## Getting Help

### 1. Logs and Diagnostics

**Collect Information:**
```bash
# Flutter logs
flutter logs

# Server logs
npm run logs

# System information
flutter doctor -v
node --version
npm --version
```

### 2. Community Support

**Resources:**
- GitHub Issues: https://github.com/measurebowl/issues
- Flutter Community: https://flutter.dev/community
- Stack Overflow: Tag with `flutter`, `opencv`, `measurebowl`

### 3. Professional Support

**Contact:**
- Email: support@measurebowl.com
- Documentation: https://docs.measurebowl.com
- Status Page: https://status.measurebowl.com

## Prevention

### 1. Regular Maintenance

**Weekly:**
- Update dependencies
- Review error logs
- Test on different devices

**Monthly:**
- Security audit
- Performance review
- Backup verification

**Quarterly:**
- Dependency updates
- Code review
- Architecture review

### 2. Monitoring

**Set up alerts for:**
- High error rates
- Performance degradation
- Security incidents
- Build failures

**Monitor:**
- Application performance
- User experience
- System resources
- Security events
