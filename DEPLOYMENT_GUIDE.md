# MeasureBowl Deployment Guide

## Overview

This guide covers deploying the MeasureBowl application across different environments and platforms.

## Prerequisites

### Required Tools
- Node.js 18+ and npm
- Flutter SDK 3.24.5+
- Docker (optional)
- Git

### Required Accounts
- Google Play Console (Android)
- Apple Developer Account (iOS)
- Firebase Project
- Neon Database Account
- GitHub Account

## Environment Setup

### 1. Environment Variables

Create environment files for each environment:

**Development (.env.development)**
```bash
NODE_ENV=development
PORT=5000
DATABASE_URL=postgresql://dev_user:dev_pass@localhost:5432/measurebowl_dev
JWT_SECRET=dev-jwt-secret-key
API_KEY=dev-api-key
GOOGLE_PLAY_CREDENTIALS=base64_encoded_json
FIREBASE_PROJECT_ID=measurebowl-dev
OPENCV_DEBUG=true
OPENCV_LOG_LEVEL=debug
```

**Production (.env.production)**
```bash
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://prod_user:prod_pass@prod-host:5432/measurebowl_prod
JWT_SECRET=super-secure-jwt-secret-key
API_KEY=super-secure-api-key
GOOGLE_PLAY_CREDENTIALS=base64_encoded_json
FIREBASE_PROJECT_ID=measurebowl-prod
OPENCV_DEBUG=false
OPENCV_LOG_LEVEL=error
```

### 2. Database Setup

#### Neon Database (Recommended)
1. Create account at [Neon](https://neon.tech)
2. Create new project
3. Copy connection string to `DATABASE_URL`
4. Run migrations:
```bash
npm run db:push
```

#### Local PostgreSQL
```bash
# Install PostgreSQL
brew install postgresql  # macOS
sudo apt-get install postgresql  # Ubuntu

# Create database
createdb measurebowl_dev
createdb measurebowl_prod

# Run migrations
npm run db:push
```

## Web Application Deployment

### 1. Build Process
```bash
# Install dependencies
npm install

# Build for production
npm run build

# Start production server
npm start
```

### 2. Docker Deployment
```bash
# Build Docker image
docker build -t measurebowl-web .

# Run container
docker run -p 5000:5000 --env-file .env.production measurebowl-web
```

**Dockerfile**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application
RUN npm run build

# Expose port
EXPOSE 5000

# Start application
CMD ["npm", "start"]
```

### 3. Platform Deployment

#### Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

#### Netlify
```bash
# Build command
npm run build

# Publish directory
dist/public
```

#### Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway deploy
```

## Flutter Mobile App Deployment

### 1. Android Deployment

#### Setup
```bash
# Navigate to Flutter app
cd flutter_app

# Get dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main
```

#### Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

#### Build AAB (Google Play)

**Quick Build:**
```bash
# From project root
cd flutter_app
flutter pub get
flutter build appbundle --release
```

**Using Build Script:**
```powershell
# From project root
cd flutter_app
.\build_aab.ps1
```

**Using CI/CD Pipeline:**
```powershell
# From project root
.\ci_cd_pipeline.ps1 -Action build -Platform android -BuildType release
```

📖 **For detailed instructions, see:** [`flutter_app/BUILD_AAB_GUIDE.md`](flutter_app/BUILD_AAB_GUIDE.md)

**Output Location:**
```
flutter_app/build/app/outputs/bundle/release/app-release.aab
```

#### Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app → Production → Create new release
3. Upload AAB file: `flutter_app/build/app/outputs/bundle/release/app-release.aab`
4. Add release notes
5. Review and submit for rollout

#### Fastlane Deployment
```bash
# Install Fastlane
cd android
bundle install

# Deploy to internal track
bundle exec fastlane android internal
```

### 2. iOS Deployment

#### Setup
```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios
pod install
```

#### Build IPA
```bash
# Release build
flutter build ios --release
```

#### App Store Connect
1. Create app in App Store Connect
2. Upload IPA using Xcode or Transporter
3. Configure app information
4. Submit for review

### 3. Firebase Setup

#### Android
1. Create Firebase project
2. Add Android app with package name: `com.dojo.measurebowl`
3. Download `google-services.json`
4. Place in `flutter_app/android/app/`

#### iOS
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Add to Xcode project

#### Firebase Services
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
firebase init

# Deploy
firebase deploy
```

## CI/CD Pipeline

### GitHub Actions

The project includes a comprehensive CI/CD pipeline:

**Workflow Features:**
- Code analysis and formatting
- Unit and integration tests
- Multi-platform builds
- Automated deployment
- Security scanning

**Manual Triggers:**
```yaml
# Build specific platform
workflow_dispatch:
  inputs:
    platform:
      description: 'Platform to build'
      required: true
      default: 'android'
      type: choice
      options: [android, ios, web, all]
```

### Local CI/CD
```bash
# Run full pipeline
./ci_cd_pipeline.ps1 -Action build -Platform all

# Run tests only
./ci_cd_pipeline.ps1 -Action test

# Deploy to production
./ci_cd_pipeline.ps1 -Action deploy -Platform android
```

## Monitoring and Logging

### 1. Application Monitoring
- **Flutter**: Firebase Crashlytics
- **Web**: Sentry or LogRocket
- **Server**: Winston logger with structured logging

### 2. Performance Monitoring
- **Flutter**: Firebase Performance Monitoring
- **Web**: Web Vitals tracking
- **Server**: Response time and error rate monitoring

### 3. Health Checks
```bash
# Server health check
curl https://api.measurebowl.com/health

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

## Security Considerations

### 1. Environment Security
- Use strong, unique secrets for each environment
- Rotate API keys regularly
- Enable 2FA on all accounts
- Use HTTPS everywhere

### 2. Database Security
- Use connection pooling
- Enable SSL/TLS connections
- Regular backups
- Access control and monitoring

### 3. Application Security
- Input validation and sanitization
- Rate limiting
- CORS configuration
- Security headers

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Flutter build issues
flutter clean
flutter pub get
flutter build apk --debug

# Node.js build issues
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### Database Connection Issues
```bash
# Test database connection
psql $DATABASE_URL -c "SELECT 1;"

# Check migration status
npm run db:push
```

#### Firebase Issues
```bash
# Flutter Firebase setup
flutter pub get
cd ios && pod install
cd android && ./gradlew clean
```

#### OpenCV Issues
```bash
# Flutter OpenCV issues
flutter clean
flutter pub get
cd android && ./gradlew clean
flutter build apk --debug
```

### Performance Issues

#### Web Application
- Enable gzip compression
- Use CDN for static assets
- Implement caching strategies
- Optimize bundle sizes

#### Mobile Application
- Enable R8/ProGuard obfuscation
- Optimize image assets
- Use lazy loading
- Implement proper error handling

## Rollback Procedures

### Web Application
```bash
# Rollback to previous version
git checkout previous-commit
npm run build
npm start
```

### Mobile Application
1. Revert to previous version in app stores
2. Update version numbers
3. Rebuild and redeploy

### Database
```bash
# Restore from backup
pg_restore -d measurebowl_prod backup_file.sql
```

## Maintenance

### Regular Tasks
- Update dependencies monthly
- Review and rotate secrets quarterly
- Monitor performance metrics
- Update documentation
- Security audits

### Backup Strategy
- Database: Daily automated backups
- Code: Git repository with multiple remotes
- Assets: Cloud storage with versioning
- Configuration: Encrypted backups

## Support

For deployment issues:
- Check logs: `npm run logs`
- Review GitHub Actions: Check Actions tab
- Contact support: support@measurebowl.com
- Documentation: https://docs.measurebowl.com
