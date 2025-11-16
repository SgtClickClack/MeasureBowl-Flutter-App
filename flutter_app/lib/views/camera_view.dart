import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodels/camera_viewmodel.dart';
import '../providers/settings_notifier_provider.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/camera_guides_overlay.dart';
import '../widgets/instruction_text_widget.dart';
import '../widgets/measure_button_widget.dart';
import '../providers/update_service_provider.dart';
import 'help_view.dart';
import 'history_view.dart';
import 'results_view.dart';
import 'settings_view.dart';

/// Camera view widget that displays the camera feed and measure button.
class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key});

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView>
    with WidgetsBindingObserver {
  late final CameraViewModel _viewModel;
  bool _isViewModelFromProvider = false;
  Offset? _manualJackPosition;
  bool _wasRouteActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check if a CameraViewModel is already provided (e.g., in tests)
    try {
      final providedViewModel =
          provider.Provider.of<CameraViewModel>(context, listen: false);
      _viewModel = providedViewModel;
      _isViewModelFromProvider = true;
    } catch (e) {
      // No provider found, create our own instance
      _viewModel = CameraViewModel();
      // Initialize camera after the first frame to ensure app is fully active
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel.initialize();
        }
      });
    }
    // Check for app updates after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  /// Checks for app updates and shows a dialog if an update is available.
  Future<void> _checkForUpdates() async {
    if (!mounted) return;

    try {
      final updateService = ref.read(appUpdateServiceProvider);
      final latestVersion = await updateService.getLatestRemoteVersion();
      final updateAvailable =
          await updateService.isUpdateAvailable(latestVersion);

      if (!mounted) return;

      if (updateAvailable) {
        _showUpdateDialog(latestVersion);
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience if update check fails
      // In production, you might want to log this error
    }
  }

  /// Shows an update dialog when an update is available.
  void _showUpdateDialog(String latestVersion) {
    if (!mounted) return;

    // Define the Play Store URL
    final Uri playStoreUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.standnmeasure.app',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            'A new version ($latestVersion) is available. '
            'Please update the app to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog first

                if (await launchUrl(playStoreUrl)) {
                  debugPrint('Successfully launched Play Store URL.');
                } else {
                  // Optionally show an error if the launcher failed
                  // ScaffoldMessenger.of(context).showSnackBar(...)
                  debugPrint('Could not launch Play Store URL.');
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if route is currently active
    final isRouteActive = ModalRoute.of(context)?.isCurrent ?? false;

    // If route was not active but is now active, clear the manual jack position
    if (!_wasRouteActive && isRouteActive) {
      setState(() {
        _manualJackPosition = null;
      });
    }

    _wasRouteActive = isRouteActive;
  }

  @override
  void deactivate() {
    // Mark that route is no longer active
    _wasRouteActive = false;
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Only dispose if we created the view model ourselves
    if (!_isViewModelFromProvider) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewModel.handleLifecycleChange(state);
  }

  Future<void> _handleMeasurePressed(BuildContext context) async {
    // Get the settings from Riverpod
    final settings = ref.read(settingsNotifierProvider);
    final bool proMode = settings.proAccuracyMode;
    final double jackDiameter = settings.jackDiameterMm;

    final result = await _viewModel.startImageProcessing(
      proAccuracyMode: proMode,
      manualJackPosition: _manualJackPosition,
      jackDiameterMm: jackDiameter,
    );

    // Clear the manual jack position after passing it to the processor
    setState(() {
      _manualJackPosition = null;
    });

    if (!context.mounted) return;

    if (result.message != null) {
      _showSnackBar(
        context,
        result.message!,
        isError: result.isError,
        usedFallback: result.usedFallback,
      );
    }

    if (!result.hasMeasurement) {
      return;
    }

    final measurement = result.measurement!;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultsView(
          measurementResult: measurement,
          isNewResult: true,
        ),
      ),
    );
    if (!context.mounted) return;

    if (result.usedFallback && result.message == null) {
      _showSnackBar(
        context,
        'Showing fallback measurement results.',
        isError: true,
        usedFallback: true,
      );
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool usedFallback = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? (usedFallback ? Colors.orangeAccent : Colors.redAccent)
            : Colors.green,
      ),
    );
  }

  Widget _buildCameraPreview(CameraViewModel viewModel) {
    if (!viewModel.showCameraPreview) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _manualJackPosition = details.localPosition;
        });
      },
      child: CameraPreviewWidget(
        controller: viewModel.controller,
        initializeControllerFuture: viewModel.initializeControllerFuture,
      ),
    );
  }

  Widget _buildStatusBanner(CameraViewModel viewModel) {
    final message = viewModel.statusMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white70),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: () => viewModel.clearStatusMessage(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider<CameraViewModel>.value(
      value: _viewModel,
      child: provider.Consumer<CameraViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  tooltip: 'View Performance Stats',
                  onPressed: () {
                    Navigator.pushNamed(context, '/stats');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'View History',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HistoryView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  _buildCameraPreview(viewModel),
                  // Manual jack marker - displayed when user taps on preview
                  if (_manualJackPosition != null)
                    Positioned(
                      key: const Key('manual_jack_marker'),
                      left: _manualJackPosition!.dx -
                          12, // Offset to center a 24px icon
                      top: _manualJackPosition!.dy - 12,
                      child: const Icon(
                        Icons.add_location_alt,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  // Conditionally display camera guides overlay
                  _CameraGuidesConditional(),
                  const AppHeaderWidget(),
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: MeasureButtonWidget(
                        isMeasuring: viewModel.isMeasuring,
                        isProcessing: viewModel.isProcessing,
                        onPressed: () => _handleMeasurePressed(context),
                      ),
                    ),
                  ),
                  HelpButtonWidget(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpView(),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsView(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  InstructionTextWidget(
                    isProcessing: viewModel.isProcessing,
                    isMeasuring: viewModel.isMeasuring,
                  ),
                  _buildStatusBanner(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper widget that conditionally displays camera guides overlay
/// Only shows when showCameraGuides setting is true
class _CameraGuidesConditional extends ConsumerWidget {
  const _CameraGuidesConditional();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the settings to reactively show/hide guides
    final settings = ref.watch(settingsNotifierProvider);
    if (settings.showCameraGuides) {
      return const CameraGuidesOverlay();
    }
    return const SizedBox.shrink();
  }
}
