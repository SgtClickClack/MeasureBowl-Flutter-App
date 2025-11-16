// TypeScript type definitions for environment variables
// This file provides IntelliSense and type safety for all environment variables
// used across the MeasureBowl application

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      // Database Configuration
      DATABASE_URL: string;

      // Google Play Console Credentials (Base64 encoded JSON)
      GOOGLE_PLAY_CREDENTIALS: string;

      // Firebase Configuration
      FIREBASE_PROJECT_ID: string;
      FIREBASE_PRIVATE_KEY: string;
      FIREBASE_CLIENT_EMAIL: string;

      // Server Configuration
      PORT: string;
      NODE_ENV: 'development' | 'production' | 'test';

      // Security
      JWT_SECRET: string;
      API_KEY: string;

      // OpenCV Configuration
      OPENCV_DEBUG: string;
      OPENCV_LOG_LEVEL: 'error' | 'warn' | 'info' | 'debug';

      // App Configuration
      APP_NAME: string;
      APP_VERSION: string;
    }
  }
}

export {};

