import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/measurement_result.dart';
import 'results_view.dart';

/// Camera view widget that displays the camera feed placeholder and measure button
class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _isMeasuring = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize camera controller
  Future<void> _initializeCamera() async {
    try {
      // Get list of available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        // No cameras available
        return;
      }

      // Select the first back camera (or first camera if no back camera)
      CameraDescription selectedCamera = _cameras!.first;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      // Create and initialize the camera controller
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false, // Don't need audio for photos
      );

      _initializeControllerFuture = _controller!.initialize();
      
      // Trigger rebuild to show camera preview
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    // Dispose of the controller to prevent memory leaks
    _controller?.dispose();
    super.dispose();
  }

  /// Handle the measure button press - now captures image
  Future<void> _onMeasurePressed() async {
    // Prevent multiple simultaneous measurements
    if (_isMeasuring || _controller == null) return;

    setState(() {
      _isMeasuring = true;
    });

    try {
      // Wait for camera to initialize
      await _initializeControllerFuture;

      // Get the pictures directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = path.join(appDir.path, 'Pictures');
      await Directory(dirPath).create(recursive: true);
      
      // Create unique filename with timestamp
      final String fileName = 'lawn_bowls_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(dirPath, fileName);

      // Take picture
      final XFile imageFile = await _controller!.takePicture();
      
      // Copy the image to our directory
      await imageFile.saveTo(filePath);

      // Create measurement results with captured image
      final measurementResults = MeasurementResult.fromCapturedImage(
        imagePath: filePath,
      );

      setState(() {
        _isMeasuring = false;
      });

      // Navigate to results view
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultsView(
              measurementResult: measurementResults,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      setState(() {
        _isMeasuring = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build camera preview or loading/error state
  Widget _buildCameraPreview() {
    if (_controller == null || _initializeControllerFuture == null) {
      // Camera not initialized yet or no cameras available
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Camera is initialized, show the preview
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          );
        } else if (snapshot.hasError) {
          // Error initializing camera
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
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else {
          // Camera is still initializing
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing Camera...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview or loading/error state
            _buildCameraPreview(),

            // App title overlay at top
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Lawn Bowls Measure',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'One-shot measurement',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Measure button at bottom center
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _onMeasurePressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isMeasuring ? 100 : 120,
                    height: _isMeasuring ? 100 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMeasuring 
                          ? Colors.blue[300] 
                          : Colors.blue[600],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isMeasuring
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),

            // Instructions at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                _isMeasuring ? 'Measuring...' : 'Tap to measure distances',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}