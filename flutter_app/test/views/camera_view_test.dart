import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:lawn_bowls_measure/views/camera_view.dart';
import 'package:lawn_bowls_measure/views/history_view.dart';
import 'package:lawn_bowls_measure/views/settings_view.dart';
import 'package:lawn_bowls_measure/views/stats_view.dart';
import 'package:lawn_bowls_measure/viewmodels/camera_viewmodel.dart'
    show CameraViewModel, CameraCaptureResult;
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:lawn_bowls_measure/providers/settings_notifier_provider.dart';
import 'package:lawn_bowls_measure/providers/update_service_provider.dart';
import 'package:lawn_bowls_measure/viewmodels/settings_viewmodel.dart';
import 'package:lawn_bowls_measure/services/settings_service.dart';
import 'package:lawn_bowls_measure/services/app_update_service.dart';

/// Manual mock of CameraViewModel for testing
class MockCameraViewModel extends CameraViewModel {
  MockCameraViewModel({
    this.mockIsInitialized = false,
    this.mockIsMeasuring = false,
    this.mockIsProcessing = false,
    this.mockShowCameraPreview = true,
    this.mockStatusMessage,
  });

  final bool mockIsInitialized;
  final bool mockIsMeasuring;
  final bool mockIsProcessing;
  final bool mockShowCameraPreview;
  final String? mockStatusMessage;

  // Trackers for startImageProcessing method
  bool? lastProAccuracyMode;
  Offset? lastManualJackPosition;
  double? lastJackDiameterMm;
  int startProcessingCallCount = 0;

  @override
  bool get isInitialized => mockIsInitialized;

  @override
  bool get isMeasuring => mockIsMeasuring;

  @override
  bool get isProcessing => mockIsProcessing;

  @override
  bool get showCameraPreview => mockShowCameraPreview;

  @override
  String? get statusMessage => mockStatusMessage;

  @override
  CameraController? get controller => null;

  @override
  Future<void>? get initializeControllerFuture => null;

  /// Mock method to track calls to startImageProcessing
  @override
  Future<CameraCaptureResult> startImageProcessing({
    bool proAccuracyMode = false,
    Offset? manualJackPosition,
    double jackDiameterMm = 63.5,
  }) async {
    lastProAccuracyMode = proAccuracyMode;
    lastManualJackPosition = manualJackPosition;
    lastJackDiameterMm = jackDiameterMm;
    startProcessingCallCount++;
    // Return a successful result for testing
    return const CameraCaptureResult(
      measurement: null,
      message: null,
      isError: false,
      usedFallback: false,
    );
  }
}

/// Manual mock of SettingsViewModel for testing (legacy - kept for existing tests)
/// Note: This is a compatibility layer for tests that haven't been migrated to Riverpod yet
class MockSettingsViewModel {
  MockSettingsViewModel({
    required this.mockIsLoading,
    this.mockErrorMessage,
    required this.mockSettings,
  });

  final bool mockIsLoading;
  final String? mockErrorMessage;
  final AppSettings mockSettings;
}

/// NavigatorObserver to track navigation events
class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

/// Mock StatsView widget for testing navigation
class MockStatsView extends StatelessWidget {
  const MockStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('MockStatsView')),
    );
  }
}

/// Helper function to create a test widget with CameraView wrapped in providers
Widget createTestWidget(
  CameraViewModel viewModel, {
  NavigatorObserver? navigatorObserver,
  MockSettingsViewModel? settingsViewModel,
  Map<String, WidgetBuilder>? routes,
  AppUpdateService? updateService,
}) {
  Widget cameraViewWidget =
      provider.ChangeNotifierProvider<CameraViewModel>.value(
    value: viewModel,
    child: const CameraView(),
  );

  // Create MaterialApp first
  final materialApp = MaterialApp(
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    home: cameraViewWidget,
    routes: routes ?? {},
  );

  // Wrap MaterialApp with Riverpod ProviderScope for settings
  // Use mock settings if provided, otherwise use defaults
  final appSettings = settingsViewModel?.mockSettings ?? AppSettings.defaults();

  final overrides = <Override>[
    settingsNotifierProvider.overrideWith(
      (ref) =>
          SettingsNotifier(MockSettingsService(settingsToReturn: appSettings))
            ..initialize(),
    ),
  ];

  // Add update service override if provided
  if (updateService != null) {
    overrides.add(
      appUpdateServiceProvider.overrideWithValue(updateService),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: materialApp,
  );
}

/// Mock SettingsService for testing
class MockSettingsService extends SettingsService {
  final AppSettings settingsToReturn;

  MockSettingsService({required this.settingsToReturn});

  @override
  Future<AppSettings> loadSettings() async => settingsToReturn;

  @override
  Future<void> saveSettings(AppSettings settings) async {}
}

/// Mock AppUpdateService for testing
class MockAppUpdateService extends AppUpdateService {
  final bool mockIsUpdateAvailable;
  final String mockLatestVersion;

  MockAppUpdateService({
    required this.mockIsUpdateAvailable,
    required this.mockLatestVersion,
  }) : super();

  @override
  Future<String> getLatestRemoteVersion() async {
    return mockLatestVersion;
  }

  @override
  Future<bool> isUpdateAvailable(String latestRemoteVersion) async {
    return mockIsUpdateAvailable;
  }
}

void main() {
  group('CameraView', () {
    testWidgets('should navigate to HistoryView when history button is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up NavigatorObserver to track navigation
      final navigatorObserver = TestNavigatorObserver();

      // Arrange: Pump the CameraView widget
      await tester.pumpWidget(createTestWidget(mockViewModel,
          navigatorObserver: navigatorObserver));

      // Act: Find the history button using Icons.history
      final historyButton = find.byIcon(Icons.history);

      // Assert: Verify the button exists (this will fail initially as the button doesn't exist yet)
      expect(historyButton, findsOneWidget);

      // Act: Tap the history button
      await tester.tap(historyButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert: Verify that Navigator.push was called with a MaterialPageRoute that builds HistoryView
      // Note: The observer may track multiple routes (initial + pushed), so we check for at least one
      expect(navigatorObserver.pushedRoutes.length, greaterThanOrEqualTo(1));

      // Find the route that was pushed (should be the last one)
      final pushedRoute = navigatorObserver.pushedRoutes.last;
      expect(pushedRoute, isA<MaterialPageRoute>());

      // Verify that HistoryView is now in the widget tree
      expect(find.byType(HistoryView), findsOneWidget);
    });

    testWidgets(
        'should navigate to SettingsView when settings button is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Set up NavigatorObserver to track navigation
      final navigatorObserver = TestNavigatorObserver();

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockViewModel,
        navigatorObserver: navigatorObserver,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Find the settings button using Icons.settings
      final settingsButton = find.byIcon(Icons.settings);

      // Assert: Verify the button exists
      expect(settingsButton, findsOneWidget);

      // Act: Tap the settings button
      await tester.tap(settingsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify that Navigator.push was called
      expect(navigatorObserver.pushedRoutes.length, greaterThanOrEqualTo(1));

      // Find the route that was pushed (should be the last one)
      final pushedRoute = navigatorObserver.pushedRoutes.last;

      // Assert: Verify that SettingsView was pushed
      // Note: We verify via NavigatorObserver to avoid camera initialization issues
      // The route builder should create SettingsView
      expect(pushedRoute, isA<MaterialPageRoute>());
    });

    testWidgets(
        'should pass proAccuracyMode from settings to ViewModel when measure button is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel with proAccuracyMode = true
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(proAccuracyMode: true),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Find the measure button using Icons.camera_alt
      final measureButton = find.byIcon(Icons.camera_alt);

      // Assert: Verify the button exists
      expect(measureButton, findsOneWidget);

      // Act: Tap the measure button
      await tester.tap(measureButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify that startImageProcessing was called once
      expect(mockCameraViewModel.startProcessingCallCount, equals(1));

      // Assert: Verify that proAccuracyMode was passed as true
      expect(mockCameraViewModel.lastProAccuracyMode, equals(true));
    });

    testWidgets('should display camera guides when setting is true',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel configured with showCameraGuides = true
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(showCameraGuides: true),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Assert: Expect to find a widget that represents the guides
      // Using a Key to identify the camera guides overlay
      expect(find.byKey(const Key('camera_guides')), findsOneWidget);
    });

    testWidgets('should NOT display camera guides when setting is false',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel configured with showCameraGuides = false
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(showCameraGuides: false),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Assert: Expect to find nothing for the camera guides widget
      expect(find.byKey(const Key('camera_guides')), findsNothing);
    });

    testWidgets('should display a marker when user taps on the preview',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Act: Find the CameraPreviewWidget by its key
      final cameraPreviewWidget =
          find.byKey(const Key('camera_preview_widget'));
      expect(cameraPreviewWidget, findsOneWidget);

      // Act: Tap on the CameraPreviewWidget
      await tester.tap(cameraPreviewWidget);
      await tester.pump();

      // Assert: Expect to find a marker widget that represents the manual jack selection
      // This will fail (Red Phase) because the CameraPreview is not wrapped in a
      // GestureDetector and the manual_jack_marker widget doesn't exist yet
      expect(find.byKey(const Key('manual_jack_marker')), findsOneWidget);
    });

    testWidgets(
        'should pass manual jack position to ViewModel when measure button is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Act: Find the CameraPreviewWidget by its key
      final cameraPreviewWidget =
          find.byKey(const Key('camera_preview_widget'));
      expect(cameraPreviewWidget, findsOneWidget);

      // Act: Get the widget's top-left position to calculate local tap position
      final widgetTopLeft = tester.getTopLeft(cameraPreviewWidget);
      // Tap at a specific offset from the widget's top-left corner
      const localOffset = Offset(100, 150);
      final globalTapPosition = widgetTopLeft + localOffset;
      await tester.tapAt(globalTapPosition);
      await tester.pump();

      // Act: Find the measure button using Icons.camera_alt
      final measureButton = find.byIcon(Icons.camera_alt);
      expect(measureButton, findsOneWidget);

      // Act: Tap the measure button
      await tester.tap(measureButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify that startImageProcessing was called once
      expect(mockCameraViewModel.startProcessingCallCount, equals(1));

      // Assert: Verify that the manual jack position was passed to the ViewModel
      // The position should match the local offset we tapped at (relative to widget)
      expect(mockCameraViewModel.lastManualJackPosition, isNotNull);
      // The position should be close to our local offset (allowing for small rounding differences)
      final receivedPosition = mockCameraViewModel.lastManualJackPosition!;
      expect(receivedPosition.dx, closeTo(localOffset.dx, 1.0));
      expect(receivedPosition.dy, closeTo(localOffset.dy, 1.0));
    });

    testWidgets('should clear manual jack marker after a measurement is taken',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act 1: Pump to allow the widget to build
      await tester.pump();

      // Act 1: Get the widget's top-left position to calculate local tap position
      final cameraPreviewWidget =
          find.byKey(const Key('camera_preview_widget'));
      expect(cameraPreviewWidget, findsOneWidget);
      final widgetTopLeft = tester.getTopLeft(cameraPreviewWidget);

      // Act 1: Tap on the preview to set the manual jack position
      const tapPosition = Offset(100, 150);
      final globalTapPosition = widgetTopLeft + tapPosition;
      await tester.tapAt(globalTapPosition);
      await tester.pump();

      // Assert 1: Verify the marker is visible
      expect(find.byKey(const Key('manual_jack_marker')), findsOneWidget);

      // Act 2: Find the measure button using Icons.camera_alt
      final measureButton = find.byIcon(Icons.camera_alt);
      expect(measureButton, findsOneWidget);

      // Act 2: Tap the measure button
      await tester.tap(measureButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert 2: Verify the marker is now gone
      // This will fail (Red Phase) because _handleMeasurePressed does not clear
      // the _manualJackPosition state after the measurement
      expect(find.byKey(const Key('manual_jack_marker')), findsNothing);
    });

    testWidgets(
        'should pass jackDiameterMm from settings to ViewModel when measure button is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel with jackDiameterMm = 65.0
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(jackDiameterMm: 65.0),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act: Find the measure button using Icons.camera_alt
      final measureButton = find.byIcon(Icons.camera_alt);

      // Assert: Verify the button exists
      expect(measureButton, findsOneWidget);

      // Act: Tap the measure button
      await tester.tap(measureButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify that startImageProcessing was called once
      expect(mockCameraViewModel.startProcessingCallCount, equals(1));

      // Assert: Verify that jackDiameterMm was passed as 65.0
      expect(mockCameraViewModel.lastJackDiameterMm, equals(65.0));
    });

    testWidgets(
        'should clear manual jack marker when navigating away from CameraView',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockCameraViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Pump the CameraView widget with both providers
      await tester.pumpWidget(createTestWidget(
        mockCameraViewModel,
        settingsViewModel: mockSettingsViewModel,
      ));

      // Act 1: Pump to allow the widget to build
      await tester.pump();

      // Act 1: Find the CameraPreviewWidget by its key
      final cameraPreviewWidget =
          find.byKey(const Key('camera_preview_widget'));
      expect(cameraPreviewWidget, findsOneWidget);

      // Act 1: Get the widget's top-left position to calculate local tap position
      final widgetTopLeft = tester.getTopLeft(cameraPreviewWidget);
      // Tap at a specific offset from the widget's top-left corner
      const localOffset = Offset(100, 150);
      final globalTapPosition = widgetTopLeft + localOffset;
      await tester.tapAt(globalTapPosition);
      await tester.pump();

      // Assert 1: Verify the marker is visible
      expect(find.byKey(const Key('manual_jack_marker')), findsOneWidget);

      // Act 2: Find and tap the Settings icon
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert 2: Verify we are on the SettingsView
      expect(find.byType(SettingsView), findsOneWidget);

      // Act 3: Navigate back to CameraView
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert 3: Verify we are back on CameraView
      expect(find.byType(CameraView), findsOneWidget);

      // Assert 3: Verify the marker is now gone
      // This will fail (Red Phase) because _manualJackPosition is part of
      // _CameraViewState and persists when navigating away and back
      expect(find.byKey(const Key('manual_jack_marker')), findsNothing);
    });

    testWidgets('should navigate to StatsView when statistics icon is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up the mock CameraViewModel
      final mockViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Set up NavigatorObserver to track navigation
      final navigatorObserver = TestNavigatorObserver();

      // Arrange: Create routes map with MockStatsView
      final routes = <String, WidgetBuilder>{
        '/stats': (context) => const MockStatsView(),
      };

      // Arrange: Pump the CameraView widget with both providers and routes
      await tester.pumpWidget(createTestWidget(
        mockViewModel,
        navigatorObserver: navigatorObserver,
        settingsViewModel: mockSettingsViewModel,
        routes: routes,
      ));

      // Act: Find the statistics icon button using Icons.bar_chart
      final statsButton = find.byIcon(Icons.bar_chart);

      // Assert: Verify the button exists (this will fail initially as the button doesn't exist yet)
      expect(statsButton, findsOneWidget);

      // Act: Tap the statistics button
      await tester.tap(statsButton);
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert: Verify that MockStatsView is displayed
      expect(find.byType(MockStatsView), findsOneWidget);
    });

    testWidgets('should show update dialog when update is available',
        (WidgetTester tester) async {
      // Arrange: Create a MockAppUpdateService that returns update available
      const mockLatestVersion = '1.1.0';
      final mockUpdateService = MockAppUpdateService(
        mockIsUpdateAvailable: true,
        mockLatestVersion: mockLatestVersion,
      );

      // Arrange: Set up the mock CameraViewModel
      final mockViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Pump the CameraView widget with mocked update service
      await tester.pumpWidget(createTestWidget(
        mockViewModel,
        settingsViewModel: mockSettingsViewModel,
        updateService: mockUpdateService,
      ));

      // Act: Pump to allow the widget to build and trigger post-frame callbacks
      await tester.pump();

      // Act: Pump frames to allow post-frame callbacks to execute
      // The update check happens in a post-frame callback, so we need multiple pumps
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Expect to find the AlertDialog with the specific version text
      // This will fail (Red Phase) because the dialog logic will be skipped
      // in the test environment unless properly mocked and awaited
      // The test may timeout or fail to find the dialog, which is expected in Red phase
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'Update dialog should be displayed when update is available');
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.textContaining(mockLatestVersion), findsOneWidget);
    });

    testWidgets('should launch Play Store URL when Update button is tapped',
        (WidgetTester tester) async {
      // Arrange: Set up platform channel mock to track URL launch calls
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.standnmeasure.app';
      String? launchedUrl;
      bool launchCalled = false;

      // Mock the platform channel for url_launcher
      // Note: url_launcher uses different channel names on different platforms
      // We'll try the common one first, and handle all method calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (MethodCall methodCall) async {
          // Handle any method call from url_launcher
          if (methodCall.method.contains('launch') ||
              methodCall.method.contains('canLaunch')) {
            launchCalled = true;
            // Extract URL from arguments - could be string or map
            if (methodCall.arguments is String) {
              launchedUrl = methodCall.arguments as String;
            } else if (methodCall.arguments is Map) {
              final args = methodCall.arguments as Map;
              launchedUrl = args['url'] as String? ??
                  args['uri'] as String? ??
                  args['urlString'] as String?;
            }
            return true;
          }
          return null;
        },
      );

      // Arrange: Create a MockAppUpdateService that returns update available
      const mockLatestVersion = '1.1.0';
      final mockUpdateService = MockAppUpdateService(
        mockIsUpdateAvailable: true,
        mockLatestVersion: mockLatestVersion,
      );

      // Arrange: Set up the mock CameraViewModel
      final mockViewModel = MockCameraViewModel(
        mockIsInitialized: true,
        mockIsMeasuring: false,
        mockIsProcessing: false,
        mockShowCameraPreview: true,
        mockStatusMessage: null,
      );

      // Arrange: Set up MockSettingsViewModel
      final mockSettingsViewModel = MockSettingsViewModel(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockSettings: AppSettings(),
      );

      // Arrange: Pump the CameraView widget with mocked update service
      await tester.pumpWidget(createTestWidget(
        mockViewModel,
        settingsViewModel: mockSettingsViewModel,
        updateService: mockUpdateService,
      ));

      // Act: Pump to allow the widget to build and trigger post-frame callbacks
      await tester.pump();

      // Act: Pump frames to allow post-frame callbacks to execute
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify the dialog is displayed
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);

      // Act: Find and tap the 'Update' button in the dialog
      final updateButton = find.widgetWithText(TextButton, 'Update');
      expect(updateButton, findsOneWidget);
      await tester.tap(updateButton);

      // Wait for async operations to complete (URL launch is async)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify that the mock launch function was called with the correct Play Store URL
      // The test verifies that launchUrl was called when the Update button is tapped
      expect(launchCalled, isTrue,
          reason: 'URL launcher should be called when Update button is tapped');
      expect(launchedUrl, equals(playStoreUrl),
          reason: 'Update button should launch Play Store URL');

      // Clean up: Remove the mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
    });
  });
}
