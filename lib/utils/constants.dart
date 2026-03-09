import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Printer widths in pixels
  static const int width58mm = 384;
  static const int width80mm = 576;

  // Max image dimension before processing (to save memory)
  static const int maxImageDimension = 2000;

  // Bluetooth write chunk size and delay
  // Large chunks reduce the number of BT transactions; tiny delay prevents
  // buffer overflow on cheap Classic-BT adapters without stalling the head.
  static const int btChunkSize = 4096;
  static const Duration btChunkDelay = Duration(milliseconds: 5);

  // Image processing defaults
  static const double defaultBrightness = 0.0; // -100 to 100
  static const double defaultContrast = 0.0; // -100 to 100

  // Debounce duration for slider changes
  static const Duration sliderDebounce = Duration(milliseconds: 300);

  // SharedPreferences keys
  static const String keyPaperSize = 'paper_size';
  static const String keyAutoPrint = 'auto_print';
  static const String keyPrintDensity = 'print_density';
  static const String keyBrightness = 'brightness';
  static const String keyContrast = 'contrast';
  static const String keyRememberPrinter = 'remember_printer';
  static const String keyEnablePreview = 'enable_preview';
  static const String keyLastPrinterAddress = 'last_printer_address';
  static const String keyLastPrinterName = 'last_printer_name';
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF16213E);
  static const Color highlight = Color(0xFF0F3460);
  static const Color orange = Color(0xFFE94560);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  static const Color connectedGreen = Color(0xFF4CAF50);
  static const Color disconnectedRed = Color(0xFFE53935);
  static const Color thermalPaper = Color(0xFFF5F0E8);
}
