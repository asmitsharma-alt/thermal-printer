import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../utils/esc_pos_helper.dart';
import 'bluetooth_service.dart';

class PrinterService {
  final BluetoothService _bluetoothService;

  PrinterService(this._bluetoothService);

  /// Print processed image bytes (PNG of dithered monochrome image).
  /// [processedImageBytes] should be the output of ImageProcessingService.
  Future<void> printImage(Uint8List processedImageBytes,
      {int density = 1}) async {
    if (!_bluetoothService.isConnected) {
      throw Exception('Printer not connected');
    }

    // Decode the processed PNG
    final img.Image? monoImage = img.decodeImage(processedImageBytes);
    if (monoImage == null) {
      throw Exception('Failed to decode processed image');
    }

    // Build ESC/POS print job
    final Uint8List printData =
        EscPosHelper.buildPrintJob(monoImage, density: density);

    // Send to printer via Bluetooth with chunked writes
    await _bluetoothService.sendBytes(printData);
  }

  /// Print an img.Image directly (already processed)
  Future<void> printImageDirect(img.Image monoImage,
      {int density = 1}) async {
    if (!_bluetoothService.isConnected) {
      throw Exception('Printer not connected');
    }

    final Uint8List printData =
        EscPosHelper.buildPrintJob(monoImage, density: density);
    await _bluetoothService.sendBytes(printData);
  }
}
