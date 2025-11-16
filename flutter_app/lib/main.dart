import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'views/camera_view.dart';
import 'views/about_view.dart';
import 'views/advanced_settings_view.dart';
import 'views/stats_view.dart';
import 'providers/settings_notifier_provider.dart';
import 'viewmodels/stats_viewmodel.dart';
import 'styles/app_styles.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred device orientations (portrait only for better UX)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: LawnBowlsMeasureApp(),
    ),
  );
}

/// Main application widget that sets up the app theme and navigation
class LawnBowlsMeasureApp extends ConsumerWidget {
  const LawnBowlsMeasureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the settings notifier to reactively update theme
    // This ensures MaterialApp rebuilds when theme mode changes
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp(
      title: 'Stand \'n\' Measure',
      debugShowCheckedModeBanner: false,
      // Read themeMode directly from the reactive watch to ensure current state
      themeMode: settings.themeMode.toFlutterThemeMode,
      theme: ThemeData(
        // High contrast light theme optimized for elderly users
        // Primary colors are explicitly defined
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[700],
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,

        // Color scheme for consistent theming with dark text on light surface
        // All color values are explicitly defined for high contrast
        colorScheme: ColorScheme.light(
          primary: Colors.blue[700]!,
          surface: Colors.white,
          onSurface:
              Colors.black87, // Very dark color for text on light surface
          onPrimary: Colors.white,
        ),

        // Large, accessible text theme with dark colors for light mode
        // Note: Font sizes use constants from AppStyles where applicable
        // headlineLarge uses 28 (larger than kFontSizeTitle for emphasis)
        // bodyLarge uses kFontSizeTitle (18.0)
        // bodyMedium uses kFontSizeBody (16.0)
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: AppStyles.kFontWeightBold,
            color: Colors.black87, // Dark text for light background
          ),
          bodyLarge: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            color: Colors.black87, // Dark text for light background
          ),
          bodyMedium: TextStyle(
            fontSize: AppStyles.kFontSizeBody,
            color: Colors.black87, // Dark text for light background
          ),
          bodySmall: TextStyle(
            fontSize: AppStyles.kFontSizeSubtitle,
            color: Colors.black54, // Slightly lighter for subtitles
          ),
          titleLarge: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            fontWeight: AppStyles.kFontWeightBold,
            color: Colors.black87, // Dark text for light background
          ),
          titleMedium: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            color: Colors.black87, // Dark text for light background
          ),
          titleSmall: TextStyle(
            fontSize: AppStyles.kFontSizeBody,
            color: Colors.black87, // Dark text for light background
          ),
          labelLarge: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            color: Colors.black87, // Dark text for light background
          ),
          labelMedium: TextStyle(
            fontSize: AppStyles.kFontSizeBody,
            color: Colors.black87, // Dark text for light background
          ),
        ),

        // Primary text theme with dark colors for light mode
        primaryTextTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            color: Colors.black87, // Dark text for light background
          ),
          bodyMedium: TextStyle(
            fontSize: AppStyles.kFontSizeBody,
            color: Colors.black87, // Dark text for light background
          ),
          titleMedium: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            color: Colors.black87, // Dark text for light background
          ),
        ),

        // ListTile theme to ensure proper text colors in settings
        listTileTheme: const ListTileThemeData(
          textColor: Colors.black87, // Dark text for light background
          iconColor: Colors.black54, // Dark icons for light background
        ),

        // AppBar theme to ensure proper text colors
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87, // Dark text for light background
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: AppStyles.kFontSizeTitle,
            fontWeight: AppStyles.kFontWeightBold,
          ),
        ),

        // Button theme with large touch targets
        // Uses kFontSizeTitle for button text size
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 60),
            textStyle: const TextStyle(
              fontSize: AppStyles.kFontSizeTitle,
              fontWeight: AppStyles.kFontWeightBold,
            ),
          ),
        ),

        // Dropdown button theme to ensure proper text colors
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(
            color: Colors.black87,
            fontSize: AppStyles.kFontSizeTitle,
          ),
        ),
      ),
      // Define darkTheme for proper theme switching
      darkTheme: ThemeData(
        // Dark theme with high contrast
        // Primary colors are explicitly defined
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[700],
        scaffoldBackgroundColor: Colors.grey[900],
        brightness: Brightness.dark,

        // Color scheme for consistent theming
        // All color values are explicitly defined
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[700]!,
          surface: Colors.grey[900]!,
          onSurface: Colors.white,
          onPrimary: Colors.white,
        ),

        // Large, accessible text theme for dark mode
        // Note: Font sizes use constants from AppStyles where applicable
        // headlineLarge uses 28 (larger than kFontSizeTitle for emphasis)
        // bodyLarge uses kFontSizeTitle (18.0)
        // bodyMedium uses kFontSizeBody (16.0)
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: AppStyles.kFontWeightBold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: AppStyles.kFontSizeTitle,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: AppStyles.kFontSizeBody,
            color: Colors.white,
          ),
        ),

        // Button theme with large touch targets
        // Uses kFontSizeTitle for button text size
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 60),
            textStyle: const TextStyle(
              fontSize: AppStyles.kFontSizeTitle,
              fontWeight: AppStyles.kFontWeightBold,
            ),
          ),
        ),

        // AppBar theme to ensure proper text colors for dark mode
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white, // Light text for dark background
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: AppStyles.kFontSizeTitle,
            fontWeight: AppStyles.kFontWeightBold,
          ),
        ),
      ),
      routes: {
        AboutView.routeName: (context) => const AboutView(),
        AdvancedSettingsView.routeName: (context) =>
            const AdvancedSettingsView(),
        '/stats': (context) => provider.ChangeNotifierProvider<StatsViewModel>(
              create: (_) => StatsViewModel()..loadStats(),
              child: const StatsView(),
            ),
      },
      home: const CameraView(),
    );
  }
}
