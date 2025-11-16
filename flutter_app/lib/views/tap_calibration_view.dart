import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tap_calibration_viewmodel.dart';
import '../widgets/camera_preview_widget.dart';

/// One-Tap White Jack Calibration View
///
/// Simple calibration flow where users point the camera at the white jack
/// and tap a button to automatically sample the center pixel and generate HSV ranges.
class TapCalibrationView extends StatefulWidget {
  const TapCalibrationView({super.key});

  @override
  State<TapCalibrationView> createState() => _TapCalibrationViewState();
}

class _TapCalibrationViewState extends State<TapCalibrationView> {
  late final TapCalibrationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TapCalibrationViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final saved = await _viewModel.saveCalibration();
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('White Jack Calibration'),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Consumer<TapCalibrationViewModel>(
          builder: (context, viewModel, child) {
            if (!viewModel.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (viewModel.errorMessage != null &&
                viewModel.errorMessage!.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        viewModel.errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.initialize(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Camera preview with crosshair overlay
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Camera preview
                      CameraPreviewWidget(
                        controller: viewModel.controller,
                        initializeControllerFuture:
                            viewModel.initializeControllerFuture,
                      ),
                      // Crosshair overlay
                      Center(
                        child: Icon(
                          Icons.center_focus_strong,
                          color: Colors.white,
                          size: 60,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Instruction text
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Point the crosshair at the white jack and tap the button below',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status message
                if (viewModel.statusMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.green.withOpacity(0.2),
                    child: Text(
                      viewModel.statusMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Calibration buttons
                Container(
                  color: Colors.grey[900],
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Calibration status
                      Center(
                        child: _buildStatusChip(
                          'White Jack',
                          viewModel.hasWhiteCalibration,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Calibration button
                      ElevatedButton.icon(
                        onPressed: viewModel.isProcessing
                            ? null
                            : viewModel.calibrateWhiteJack,
                        icon: const Icon(Icons.circle, color: Colors.white),
                        label: const Text('Calibrate White Jack'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: viewModel.hasWhiteCalibration
                              ? Colors.green[700]
                              : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Save button
                      ElevatedButton(
                        onPressed: (viewModel.isProcessing ||
                                !viewModel.hasWhiteCalibration)
                            ? null
                            : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: viewModel.isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Calibration',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isCalibrated) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        isCalibrated ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCalibrated ? Colors.green : Colors.grey,
        size: 20,
      ),
      backgroundColor: isCalibrated
          ? Colors.green.withOpacity(0.2)
          : Colors.grey.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isCalibrated ? Colors.green : Colors.grey[400],
        fontWeight: isCalibrated ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
