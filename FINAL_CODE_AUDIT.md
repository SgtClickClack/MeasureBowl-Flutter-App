# Final Code Audit

## 1. State Management Pattern Review
- **Global ChangeNotifier wiring** keeps settings available app-wide, but it couples navigation to manual provider forwarding. When `ResultsView` is pushed from history the same notifier is re-wrapped, which becomes fragile as more routes require the settings scope.
```28:33:flutter_app/lib/main.dart
    return ChangeNotifierProvider<SettingsViewModel>(
      create: (context) => SettingsViewModel()..initialize(),
      child: Consumer<SettingsViewModel>(
```
```124:133:flutter_app/lib/views/history_view.dart
        final settingsViewModel =
            Provider.of<SettingsViewModel>(context, listen: false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ChangeNotifierProvider<SettingsViewModel>.value(
              value: settingsViewModel,
              child: ResultsView(measurementResult: measurement),
```
- **Settings persistence lives inside the notifier**, so UI state management, storage, and dependency creation are intertwined. That makes testability harder and blocks swapping storage implementations.
```12:33:flutter_app/lib/viewmodels/settings_viewmodel.dart
  SettingsViewModel({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();
  ...
      _settings = await _settingsService.loadSettings();
```
- **Recommendations**
  - Introduce a container-based approach (Riverpod `StateNotifierProvider` or Bloc + repository) so service injection happens at the provider layer instead of inside `ChangeNotifier`. A Riverpod ref like `final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>` would expose a single source of truth without manual cloning.
  - Split persistence into a `SettingsRepository` that wraps `SettingsService` (and caches `SharedPreferences.getInstance()`), then inject that repository into the state notifier. This removes repeated async calls and improves testability.
  - Replace `ChangeNotifierProvider.value` hand-offs with route-level `ProviderScope`/`BlocProvider.value` so navigation simply reads the global provider; no widget needs to remember to pass the notifier along.

## 2. Isolate & Concurrency Safety Audit
- **Manual jack coordinates are not isolate-safe.** `compute` serialises arguments using `StandardMessageCodec`; `Offset` is not supported, so passing it will throw `Illegal argument in isolate message` when manual placement is used.
```177:188:flutter_app/lib/services/image_processor.dart
    return await compute(processImageInBackground, {
      'imageBytes': imageBytes,
      'imagePath': imagePath,
      'detectionConfig': configMap,
      'teamAColor': teamAColor,
      'teamBColor': teamBColor,
      'proAccuracyMode': proAccuracyMode,
      'manualJackPosition': manualJackPosition,
      'jackDiameterMm': jackDiameterMm,
    });
```
```124:129:flutter_app/lib/services/image_processing/image_processing_isolate.dart
  final Offset? manualJackPosition = params['manualJackPosition'] != null
      ? (params['manualJackPosition'] as Offset)
      : null;
```
  - **Action**: Serialise the coordinate before calling `compute` (e.g., pass `manualJackPosition != null ? {'x': manualJackPosition.dx, 'y': manualJackPosition.dy} : null`) and rebuild an `Offset` inside the isolate. Update the tests that assume an `Offset` to handle the new structure.
- **Large image payloads are copied between isolates.** `Uint8List` arguments to `compute` incur a full clone for each call, which increases latency on high-resolution captures. Migrating to `TransferableTypedData` (or `Isolate.run` with `TransferableTypedData`) would avoid extra allocations and reduce GC pressure.
- **Default manual-jack radius is a magic heuristic** (`30px`) that can distort measurements for high-resolution images.
```247:254:flutter_app/lib/services/image_processing/image_processing_isolate.dart
      const defaultJackRadiusPixels = 30.0;
      jack = DetectedObject(
        centerX: manualJackPosition.dx,
        centerY: manualJackPosition.dy,
        majorAxis: defaultJackRadiusPixels * 2,
```
  - **Action**: Derive the initial radius from the detected scale (e.g., infer from image dimensions) or require the manual workflow to collect jack diameter explicitly, then normalise before distance calculations.
- **FFI resource cleanup is generally solid.** `processImageInBackground` tracks every `cv.Mat` and disposes them in `finally`, which is the right pattern.
```624:636:flutter_app/lib/services/image_processing/image_processing_isolate.dart
  } finally {
    // --- CRITICAL MEMORY CLEANUP ---
    final disposedMats = <Object>{};
    for (final mat in matsToDispose) {
      if (!disposedMats.contains(mat)) {
        mat.dispose();
        disposedMats.add(mat);
      }
```
  - **Follow-up**: Mirror the same guarded disposal in any helper that creates Mats (`distance_calculator.dart`, `metrology_service.dart`) so future refactors cannot regress.

## 3. Maintainability & Code Smell
- **Monolithic functions**: both the isolate pipeline and camera capture routine are difficult to reason about (~600 and ~160 lines respectively). Breaking them into composable steps will lower cognitive load and make unit testing practical.
```109:613:flutter_app/lib/services/image_processing/image_processing_isolate.dart
Future<Map<String, dynamic>> processImageInBackground(
  Map<String, dynamic> params,
) async {
  // ... existing code ...
}
```
```148:312:flutter_app/lib/viewmodels/camera_viewmodel.dart
  Future<CameraCaptureResult> startImageProcessing({
    bool proAccuracyMode = false,
    Offset? manualJackPosition,
    double jackDiameterMm = 63.5,
  }) async {
    // ... existing code ...
  }
```
  - **Action**: Extract phase-specific helpers (permission gate, capture, compression, cache read/write, isolate orchestration). In the isolate, move contour detection, jack selection, scale validation, and measurement output into dedicated modules under `services/image_processing/`.
- **Heuristic duplication**: `findJack` exists twice (main isolate and background isolate) and can drift over time.
```21:94:flutter_app/lib/services/image_processor.dart
DetectedObject? findJack(
  List<DetectedObject> objects, {
  double maxAspectRatio = 1.8,
  double minRadiusPixels = 15.0,
  double maxRadiusPixels = 150.0,
}) {
  // ... existing code ...
}
```
  - **Action**: Consolidate into `utils/jack_selector.dart` shared by both isolates, or reuse the isolate implementation via a pure-dart helper to keep behaviour identical.
- **Magic numbers** remain scattered (jack diameter `63.5`, bowl ratio bounds `0.5`–`8.0`, timeout `30s`, etc.), which hides domain knowledge.
```52:70:flutter_app/lib/models/app_settings.dart
class AppSettings {
  ...
  AppSettings({
    this.proAccuracyMode = false,
    ...
    this.jackDiameterMm = 63.5,
  });
```
```308:339:flutter_app/lib/services/image_processing/image_processing_isolate.dart
      if (sizeRatio < 0.5 || sizeRatio > 8.0) {
        // ... existing code ...
      }
```
  - **Action**: Centralise these values in `lib/constants/measurement_constants.dart` (with documentation and links to World Bowls specs) so any tuning has a single source of truth.
- **Known technical debt**: ArUco calibration remains stubbed with TODOs, blocking Pro Accuracy parity on real mats.
```56:64:flutter_app/lib/services/metrology_service.dart
      // TODO: ArUco API bindings need to be verified after module compilation
      return {
        'success': false,
        'error':
            'ArUco API bindings not yet available. The contrib modules have been enabled in pubspec.yaml, but the Dart bindings may need to be regenerated after a full rebuild. Please check the opencv_dart documentation for the correct API signatures.',
      };
```
  - **Action**: Track this in the backlog with an explicit milestone so production mode does not silently fall back forever.

---
**Next Priority Recommendation**: Address the manual-jack isolate messaging bug first; it is a deterministic crash in manual override scenarios. Follow that with state-management modularisation (Riverpod/Bloc) before refactoring the image pipeline, so new architecture is in place before breaking apart large functions.
