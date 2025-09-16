import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/measurement_result.dart';
import '../services/image_processor.dart';
import 'results_view.dart';
import 'help_view.dart';

/// Top-level function for isolate-based image processing
/// This function runs in a separate isolate to avoid blocking the UI thread
Future<Map<String, dynamic>> _processImageInIsolate(String imagePath) async {
  return await ImageProcessor.processImage(imagePath);
}

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
  bool _isProcessing = false;

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

  /// Handle the measure button press - capture image and process with OpenCV
  Future<void> _onMeasurePressed() async {
    // Prevent multiple simultaneous measurements
    if (_isMeasuring || _isProcessing || _controller == null) return;

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

      setState(() {
        _isMeasuring = false;
        _isProcessing = true;
      });

      // Process the captured image with OpenCV in a separate isolate
      // This prevents UI blocking during heavy image processing
      final Map<String, dynamic> processingResult = 
          await compute(_processImageInIsolate, filePath);

      setState(() {
        _isProcessing = false;
      });

      // Check if processing was successful
      if (!processingResult['success']) {
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(processingResult['error'] ?? 'Processing failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Create measurement results with OpenCV processing data
      final measurementResults = ImageProcessor.createMeasurementResult(
        processingResult,
      );

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
      debugPrint('Error in measurement process: $e');
      setState(() {
        _isMeasuring = false;
        _isProcessing = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
                    width: (_isMeasuring || _isProcessing) ? 100 : 120,
                    height: (_isMeasuring || _isProcessing) ? 100 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isMeasuring || _isProcessing) 
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
                    child: (_isMeasuring || _isProcessing)
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

            // Help button in top-right corner
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpView(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),

            // Instructions at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                _isProcessing 
                    ? 'Processing with OpenCV...'
                    : _isMeasuring 
                        ? 'Capturing image...'
                        : 'Tap to measure distances',
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