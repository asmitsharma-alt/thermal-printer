import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/print_settings.dart';
import '../utils/dithering.dart';

/// Parameters passed to the isolate for image processing.
class _ProcessParams {
  final Uint8List imageBytes;
  final int targetWidth;
  final double brightness;
  final double contrast;
  final bool invertColors;
  final int rotation; // 0, 90, 180, 270

  _ProcessParams({
    required this.imageBytes,
    required this.targetWidth,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.invertColors = false,
    this.rotation = 0,
  });
}

class ImageProcessingService {
  /// Process image for thermal printing. Runs in a compute isolate.
  static Future<Uint8List> processForThermal({
    required Uint8List imageBytes,
    required PrintSettings settings,
    double? brightnessOverride,
    double? contrastOverride,
    bool? invertOverride,
    int rotation = 0,
  }) async {
    final params = _ProcessParams(
      imageBytes: imageBytes,
      targetWidth: settings.paperSize.widthPx,
      brightness: brightnessOverride ?? settings.brightness,
      contrast: contrastOverride ?? settings.contrast,
      invertColors: invertOverride ?? settings.invertColors,
      rotation: rotation,
    );
    return compute(_processImage, params);
  }

  /// Get processed image as img.Image (for preview rendering)
  static Future<img.Image?> processForPreview({
    required Uint8List imageBytes,
    required PrintSettings settings,
    double? brightnessOverride,
    double? contrastOverride,
    bool? invertOverride,
    int rotation = 0,
  }) async {
    final processed = await processForThermal(
      imageBytes: imageBytes,
      settings: settings,
      brightnessOverride: brightnessOverride,
      contrastOverride: contrastOverride,
      invertOverride: invertOverride,
      rotation: rotation,
    );
    return img.decodeImage(processed);
  }

  /// The actual processing pipeline, runs in an isolate.
  static Uint8List _processImage(_ProcessParams params) {
    // Step 1: Decode image
    img.Image? image = img.decodeImage(params.imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Pre-process: limit size to avoid memory issues
    if (image.width > 2000 || image.height > 2000) {
      final double scale = 2000.0 /
          (image.width > image.height ? image.width : image.height);
      image = img.copyResize(image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear);
    }

    // Step 2: Apply rotation
    if (params.rotation == 90) {
      image = img.copyRotate(image, angle: 90);
    } else if (params.rotation == 180) {
      image = img.copyRotate(image, angle: 180);
    } else if (params.rotation == 270) {
      image = img.copyRotate(image, angle: 270);
    }

    // Step 3: Resize to printer width, maintaining aspect ratio
    final int targetWidth = params.targetWidth;
    final double aspectRatio = image.height / image.width;
    final int targetHeight = (targetWidth * aspectRatio).round();
    image = img.copyResize(image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear);

    // Step 4: Convert to grayscale
    image = img.grayscale(image);

    // Step 5: Adjust brightness
    if (params.brightness != 0.0) {
      // brightness range: -100 to 100, map to -255..255
      final int brightnessVal = (params.brightness * 2.55).round();
      image = img.adjustColor(image, brightness: 1.0 + brightnessVal / 255.0);
    }

    // Step 6: Adjust contrast
    if (params.contrast != 0.0) {
      // contrast range: -100 to 100
      image = img.adjustColor(image, contrast: 1.0 + params.contrast / 100.0);
    }

    // Step 7: Invert if requested
    if (params.invertColors) {
      image = img.invert(image);
    }

    // Step 8: Apply Floyd-Steinberg dithering
    image = floydSteinbergDithering(image);

    // Return as PNG bytes
    return Uint8List.fromList(img.encodePng(image));
  }
}
