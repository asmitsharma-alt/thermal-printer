import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Floyd-Steinberg dithering algorithm.
/// Converts a grayscale image to 1-bit monochrome using error diffusion.
img.Image floydSteinbergDithering(img.Image source) {
  final int width = source.width;
  final int height = source.height;

  // Work with a float buffer for error diffusion precision
  final Float32List pixels = Float32List(width * height);

  // Extract luminance values
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = source.getPixel(x, y);
      pixels[y * width + x] = img.getLuminance(pixel).toDouble();
    }
  }

  // Apply Floyd-Steinberg dithering
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int idx = y * width + x;
      final double oldPixel = pixels[idx];
      final double newPixel = oldPixel < 128.0 ? 0.0 : 255.0;
      pixels[idx] = newPixel;
      final double error = oldPixel - newPixel;

      // Distribute error to neighboring pixels
      if (x + 1 < width) {
        pixels[idx + 1] += error * 7.0 / 16.0;
      }
      if (y + 1 < height) {
        if (x - 1 >= 0) {
          pixels[(y + 1) * width + (x - 1)] += error * 3.0 / 16.0;
        }
        pixels[(y + 1) * width + x] += error * 5.0 / 16.0;
        if (x + 1 < width) {
          pixels[(y + 1) * width + (x + 1)] += error * 1.0 / 16.0;
        }
      }
    }
  }

  // Create output image
  final img.Image output = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int val = pixels[y * width + x] < 128.0 ? 0 : 255;
      output.setPixelRgb(x, y, val, val, val);
    }
  }

  return output;
}
