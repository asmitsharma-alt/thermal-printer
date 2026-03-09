import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_settings.dart';
import '../utils/constants.dart';

class SettingsService extends ChangeNotifier {
  SharedPreferences? _prefsInstance;
  PrintSettings _settings = const PrintSettings();
  bool _initialized = false;

  SharedPreferences get _prefs => _prefsInstance!;
  PrintSettings get settings => _settings;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    _prefsInstance = await SharedPreferences.getInstance();
    _settings = PrintSettings(
      paperSize: _loadPaperSize(),
      autoPrint: _prefs.getBool(AppConstants.keyAutoPrint) ?? false,
      printDensity: _loadPrintDensity(),
      brightness: _prefs.getDouble(AppConstants.keyBrightness) ?? 0.0,
      contrast: _prefs.getDouble(AppConstants.keyContrast) ?? 0.0,
      rememberLastPrinter:
          _prefs.getBool(AppConstants.keyRememberPrinter) ?? true,
      enablePreview: _prefs.getBool(AppConstants.keyEnablePreview) ?? true,
      invertColors: _prefs.getBool('invert_colors') ?? false,
    );
    _initialized = true;
    notifyListeners();
  }

  PaperSize _loadPaperSize() {
    final int idx = _prefs.getInt(AppConstants.keyPaperSize) ?? 0;
    return PaperSize.values[idx.clamp(0, PaperSize.values.length - 1)];
  }

  PrintDensity _loadPrintDensity() {
    final int idx = _prefs.getInt(AppConstants.keyPrintDensity) ?? 1;
    return PrintDensity.values[idx.clamp(0, PrintDensity.values.length - 1)];
  }

  Future<void> updateSettings(PrintSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await Future.wait([
      _prefs.setInt(AppConstants.keyPaperSize,
          PaperSize.values.indexOf(newSettings.paperSize)),
      _prefs.setBool(AppConstants.keyAutoPrint, newSettings.autoPrint),
      _prefs.setInt(AppConstants.keyPrintDensity,
          PrintDensity.values.indexOf(newSettings.printDensity)),
      _prefs.setDouble(AppConstants.keyBrightness, newSettings.brightness),
      _prefs.setDouble(AppConstants.keyContrast, newSettings.contrast),
      _prefs.setBool(
          AppConstants.keyRememberPrinter, newSettings.rememberLastPrinter),
      _prefs.setBool(AppConstants.keyEnablePreview, newSettings.enablePreview),
      _prefs.setBool('invert_colors', newSettings.invertColors),
    ]);
  }

  // Last printer persistence
  Future<void> saveLastPrinter(String name, String address) async {
    await _prefs.setString(AppConstants.keyLastPrinterName, name);
    await _prefs.setString(AppConstants.keyLastPrinterAddress, address);
  }

  String? get lastPrinterName =>
      _prefsInstance?.getString(AppConstants.keyLastPrinterName);
  String? get lastPrinterAddress =>
      _prefsInstance?.getString(AppConstants.keyLastPrinterAddress);
}
