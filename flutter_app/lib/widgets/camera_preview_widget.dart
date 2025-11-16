import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Widget that displays the camera preview with loading and error states
class CameraPreviewWidget extends StatefulWidget {
  final CameraController? controller;
  final Future<void>? initializeControllerFuture;

  const CameraPreviewWidget({
    required this.controller,
    required this.initializeControllerFuture,
  }) : super(key: const Key('camera_preview_widget'));

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  @override
  void initState() {
    super.initState();
    // Listen to controller value changes
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update listener if controller changed
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when controller state changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null ||
        widget.initializeControllerFuture == null) {
      return _buildLoadingState();
    }

    // Check if controller is already initialized
    if (widget.controller!.value.isInitialized) {
      return _buildCameraPreview();
    }

    // Check for errors
    if (widget.controller!.value.hasError) {
      return _buildErrorState(
        widget.controller!.value.errorDescription ?? 'Unknown camera error',
      );
    }

    return FutureBuilder<void>(
      future: widget.initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          // Double-check controller is initialized before showing preview
          if (widget.controller != null &&
              widget.controller!.value.isInitialized) {
            return _buildCameraPreview();
          } else {
            return _buildLoadingState(); // Still loading
          }
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else {
          return _buildLoadingState();
        }
      },
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(
        widget.controller!,
        key: const Key('camera_preview'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white54,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Error',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
