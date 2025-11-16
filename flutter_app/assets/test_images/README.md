# Test Images Directory

This directory contains test images for integration tests.

## Required Test Image

### `bowls_on_green.jpg`

This image is used by the integration test `image_processing_integration_test.dart`.

**Requirements:**
- Must contain a clearly visible white or yellow jack
- Must contain at least 3 clearly visible bowls (preferably different colors: red, blue, yellow)
- Should be taken on a green lawn bowls surface
- Good lighting conditions (avoid heavy shadows)
- Jack and bowls should be clearly separated (not overlapping)
- Recommended resolution: 1920x1080 or higher
- Format: JPEG

**Purpose:**
- Tests the full image processing pipeline
- Verifies OpenCV contour detection
- Validates jack identification
- Tests bowl detection and distance calculation
- Verifies color classification

## Adding Your Test Image

1. Place your test image in this directory as `bowls_on_green.jpg`
2. Ensure the image meets the requirements above
3. Run the integration test: `flutter test integration_test/image_processing_integration_test.dart`

## Note

The test image is not included in the repository by default. You need to add your own test image that meets the requirements above.

