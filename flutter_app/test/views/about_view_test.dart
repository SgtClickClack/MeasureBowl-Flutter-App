import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lawn_bowls_measure/views/about_view.dart';
import 'package:lawn_bowls_measure/widgets/settings_tile.dart';

/// Helper function to create a test widget with AboutView
Widget createTestWidget() {
  return MaterialApp(
    routes: {
      AboutView.routeName: (context) => const AboutView(),
    },
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, AboutView.routeName);
          },
          child: const Text('Navigate to About'),
        ),
      ),
    ),
  );
}

void main() {
  group('AboutView', () {
    testWidgets('should display AboutView content using SettingsTile component',
        (WidgetTester tester) async {
      // Arrange: Pump the AboutView widget directly
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      // Assert: Expect to find the SettingsTile component with the title 'App version 1.0.0'
      // This will fail (Red Phase) because the existing AboutView uses a raw Text widget,
      // not a structured SettingsTile
      expect(find.byType(SettingsTile), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(SettingsTile),
          matching: find.text('App version 1.0.0'),
        ),
        findsOneWidget,
      );
    });
  });
}
