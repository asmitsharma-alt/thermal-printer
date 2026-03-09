import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts a monochrome (black & white) image to ESC/POS raster bitmap bytes.
/// Uses the GS v 0 command for widest printer compatibility and correct
/// 1:1 proportions.
class EscPosHelper {
  EscPosHelper._();

  /// ESC/POS initialize command
  static List<int> get initCommand => [0x1B, 0x40];

  /// Feed n lines
  static List<int> feedLines(int n) {
    return [0x1B, 0x64, n.clamp(0, 255)];
  }

  /// Set print density
  static List<int> setDensity(int density) {
    final int val = [4, 7, 15][density.clamp(0, 2)];
    return [0x1D, 0x37, val];
  }

  /// Convert a dithered monochrome image to ESC/POS GS v 0 raster bytes.
  /// The image must already be sized to printer width.
  static Uint8List imageToEscPosRaster(img.Image monoImage) {
    final int width = monoImage.width;
    final int height = monoImage.height;
    final int byteWidth = (width + 7) ~/ 8;

    // GS v 0 command header: 1D 76 30 m xL xH yL yH
    final List<int> header = [
      0x1D, 0x76, 0x30, 0x00,
      byteWidth & 0xFF, (byteWidth >> 8) & 0xFF,
      height & 0xFF, (height >> 8) & 0xFF,
    ];

    final Uint8List bitmapData = Uint8List(byteWidth * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = monoImage.getPixel(x, y);
        final int luminance = img.getLuminance(pixel).round();
        if (luminance < 128) {
          final int byteIndex = y * byteWidth + (x ~/ 8);
          final int bitIndex = 7 - (x % 8);
          bitmapData[byteIndex] |= (1 << bitIndex);
        }
      }
    }

    final Uint8List result = Uint8List(header.length + bitmapData.length);
    result.setAll(0, header);
    result.setAll(header.length, bitmapData);
    return result;
  }

  /// Build complete print job bytes: init + density + image + feed
  static Uint8List buildPrintJob(img.Image monoImage, {int density = 1}) {
    final List<int> bytes = [];
    bytes.addAll(initCommand);
    bytes.addAll(setDensity(density));
    bytes.addAll(imageToEscPosRaster(monoImage));
    bytes.addAll(feedLines(4));
    return Uint8List.fromList(bytes);
  }
}
