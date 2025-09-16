import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/camera_view.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred device orientations (portrait only for better UX)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const LawnBowlsMeasureApp());
}

/// Main application widget that sets up the app theme and navigation
class LawnBowlsMeasureApp extends StatelessWidget {
  const LawnBowlsMeasureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lawn Bowls Measure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // High contrast theme optimized for elderly users
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[700],
        scaffoldBackgroundColor: Colors.black,
        
        // Large, accessible text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        
        // Button theme with large touch targets
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 60),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const CameraView(),
    );
  }
}