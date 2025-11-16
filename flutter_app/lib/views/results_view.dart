import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/measurement_result.dart';
import '../providers/settings_notifier_provider.dart';
import '../utils/measurement_converter.dart';
import '../services/measurement_history_service.dart';

/// Results view widget that displays measurement results with ranked bowl distances
class ResultsView extends ConsumerStatefulWidget {
  final MeasurementResult measurementResult;
  final bool isNewResult;

  const ResultsView({
    super.key,
    required this.measurementResult,
    this.isNewResult = false,
  });

  @override
  ConsumerState<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<ResultsView> {
  bool _isSaving = false;
  bool _isSaved = false;

  /// Handle the measure again button press
  void _onMeasureAgain(BuildContext context) {
    // Navigate back to camera view
    Navigator.of(context).pop();
  }

  /// Show the delete confirmation dialog
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: const Text('Delete this measurement?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext), // Just close the dialog
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              // 1. Close the dialog
              Navigator.pop(dialogContext);

              // 2. Delete the measurement from the service
              await MeasurementHistoryService.deleteMeasurement(
                widget.measurementResult.id,
              );

              // 3. Pop this view to return to the HistoryView
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Perform the actual save operation with the given name
  Future<void> _performSave(String name) async {
    // Set the saving state
    setState(() {
      _isSaving = true;
    });

    // Create the final MeasurementResult object to save, using copyWith to add the name
    final measurementToSave = widget.measurementResult.copyWith(
      name: name.isNotEmpty ? name : null,
    );

    // Call the service
    await MeasurementHistoryService.saveMeasurement(measurementToSave);

    // Update the UI state
    setState(() {
      _isSaving = false;
      _isSaved = true;
    });

    // Show the SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurement saved to history')),
      );
    }
  }

  /// Handle the save button press
  Future<void> _onSavePressed() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Name Measurement'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: "Optional: e.g., 'End 1'"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String name = controller.text.trim();
                Navigator.pop(dialogContext);
                _performSave(name); // Call the new helper
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Build the Save button widget (conditionally shown when isNewResult is true and not yet saved)
  /// or Delete button (when isNewResult is false)
  Widget _buildSaveButton() {
    if (widget.isNewResult && !_isSaved) {
      return IconButton(
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
        onPressed: _isSaving ? null : _onSavePressed,
        tooltip: 'Save to History',
        style: IconButton.styleFrom(
          backgroundColor: Colors.black54,
          padding: const EdgeInsets.all(12),
        ),
        color: Colors.white,
      );
    } else if (!widget.isNewResult) {
      return IconButton(
        icon: const Icon(Icons.delete),
        tooltip: 'Delete Measurement',
        onPressed: _showDeleteConfirmationDialog,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black54,
          padding: const EdgeInsets.all(12),
        ),
        color: Colors.white,
      );
    } else {
      return const SizedBox(width: 48); // Spacer to maintain layout
    }
  }

  /// Get color for bowl based on its team name
  Color _getTeamColor(String teamName) {
    switch (teamName.toLowerCase()) {
      case 'team a':
        return Colors.blue[700]!;
      case 'team b':
        return Colors.red[700]!;
      case 'unknown':
        return Colors.grey[500]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Get rank suffix (1st, 2nd, 3rd, etc.)
  String _getRankSuffix(int rank) {
    switch (rank) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }

  /// Build background image widget - either captured photo or placeholder
  Widget _buildBackgroundImage() {
    if (widget.measurementResult.imagePath != null &&
        widget.measurementResult.imagePath!.isNotEmpty) {
      // Display the captured image
      try {
        final imageFile = File(widget.measurementResult.imagePath!);
        if (imageFile.existsSync()) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(imageFile),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading image: $e');
      }
    }

    // Fallback to placeholder if no image or error
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Colors.black87),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.white24, size: 120),
            SizedBox(height: 16),
            Text(
              'Image Not Available',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get the available size for the image
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight;

            // Get original image dimensions from measurement result
            final int? originalWidth =
                widget.measurementResult.originalImageWidth;
            final int? originalHeight =
                widget.measurementResult.originalImageHeight;

            // Calculate scaling factors if original dimensions are available
            double scaleX = 1.0;
            double scaleY = 1.0;
            double offsetX = 0.0;
            double offsetY = 0.0;

            if (originalWidth != null &&
                originalHeight != null &&
                originalWidth > 0 &&
                originalHeight > 0) {
              // Calculate how the image is rendered with BoxFit.cover
              // BoxFit.cover scales the image to cover the entire container while maintaining aspect ratio
              final double imageAspectRatio = originalWidth / originalHeight;
              final double containerAspectRatio =
                  availableWidth / availableHeight;

              double renderedWidth;
              double renderedHeight;

              if (imageAspectRatio > containerAspectRatio) {
                // Image is wider - it will be scaled to fit height, and width will overflow
                renderedHeight = availableHeight;
                renderedWidth = renderedHeight * imageAspectRatio;
                // Image is centered horizontally, so we need to calculate the offset
                offsetX = (renderedWidth - availableWidth) / 2.0;
              } else {
                // Image is taller - it will be scaled to fit width, and height will overflow
                renderedWidth = availableWidth;
                renderedHeight = renderedWidth / imageAspectRatio;
                // Image is centered vertically, so we need to calculate the offset
                offsetY = (renderedHeight - availableHeight) / 2.0;
              }

              // Calculate scaling factors
              scaleX = renderedWidth / originalWidth;
              scaleY = renderedHeight / originalHeight;

              debugPrint(
                '[ResultsView] Coordinate scaling: original=${originalWidth}x${originalHeight}, '
                'rendered=${renderedWidth.toStringAsFixed(1)}x${renderedHeight.toStringAsFixed(1)}, '
                'scale=${scaleX.toStringAsFixed(3)}x${scaleY.toStringAsFixed(3)}, '
                'offset=${offsetX.toStringAsFixed(1)},${offsetY.toStringAsFixed(1)}',
              );
            }

            return Stack(
              children: [
                // Background image - captured photo or placeholder
                _buildBackgroundImage(),

                // Header with timestamp and back button
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Measured',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTimestamp(
                                    widget.measurementResult.timestamp),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),

                // Measurement overlays - positioned at each bowl's coordinates (with scaling)
                ..._buildMeasurementOverlays(
                    context, scaleX, scaleY, offsetX, offsetY),

                // Measure Again button at bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    onPressed: () => _onMeasureAgain(context),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Measure Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build measurement overlay widgets positioned at each bowl's coordinates
  /// Applies coordinate scaling to match the rendered image size
  List<Widget> _buildMeasurementOverlays(
    BuildContext context,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Get the settings from Riverpod to access measurement unit setting
    final settings = ref.watch(settingsNotifierProvider);
    final unit = settings.measurementUnit;

    // Create a mutable copy and sort it by distance (closest first)
    final sortedBowls =
        List<BowlMeasurement>.from(widget.measurementResult.bowls);
    sortedBowls
        .sort((a, b) => a.distanceFromJack.compareTo(b.distanceFromJack));

    return sortedBowls.asMap().entries.map((entry) {
      final int rank = entry.key + 1; // Rank starts at 1
      final BowlMeasurement bowl = entry.value;

      // Apply coordinate scaling to match the rendered image size
      // Scale the coordinates and subtract the offset (for BoxFit.cover centering)
      final double scaledX = (bowl.x.toDouble() * scaleX) - offsetX;
      final double scaledY = (bowl.y.toDouble() * scaleY) - offsetY;

      // Prepend the rank to the distance text using ordinal format
      final distanceText =
          '${_getRankSuffix(rank)} ${MeasurementConverter.formatDistance(
        bowl.distanceFromJack,
        unit,
      )}';

      return Positioned(
        left: scaledX,
        top: scaledY,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            distanceText, // e.g., "1st 10.0 cm" or "2nd 20.0 cm"
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
