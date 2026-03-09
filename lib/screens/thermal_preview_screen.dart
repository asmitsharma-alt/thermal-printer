import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/image_processing_service.dart';
import '../services/printer_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../widgets/image_adjustment_controls.dart';
import '../widgets/thermal_preview_widget.dart';

class ThermalPreviewScreen extends StatefulWidget {
  const ThermalPreviewScreen({super.key});

  @override
  State<ThermalPreviewScreen> createState() => _ThermalPreviewScreenState();
}

class _ThermalPreviewScreenState extends State<ThermalPreviewScreen> {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  bool _isProcessing = false;
  bool _isPrinting = false;
  bool _showAdjustments = false;

  double _brightness = 0.0;
  double _contrast = 0.0;
  bool _invertColors = false;
  int _rotation = 0;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Uint8List) {
        _originalImageBytes = args;
        final settings = context.read<SettingsService>().settings;
        _brightness = settings.brightness;
        _contrast = settings.contrast;
        _processImage();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _processImage() async {
    if (_originalImageBytes == null) return;

    setState(() => _isProcessing = true);

    try {
      final settings = context.read<SettingsService>().settings;
      final processed = await ImageProcessingService.processForThermal(
        imageBytes: _originalImageBytes!,
        settings: settings,
        brightnessOverride: _brightness,
        contrastOverride: _contrast,
        invertOverride: _invertColors,
        rotation: _rotation,
      );

      if (mounted) {
        setState(() {
          _processedImageBytes = processed;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing error: $e'),
            backgroundColor: AppColors.disconnectedRed,
          ),
        );
      }
    }
  }

  void _debouncedProcess() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.sliderDebounce, () {
      _processImage();
    });
  }

  Future<void> _printImage() async {
    if (_processedImageBytes == null) return;

    final bt = context.read<BluetoothService>();
    if (!bt.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer not connected! Go to Bluetooth settings.'),
          backgroundColor: AppColors.disconnectedRed,
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final settings = context.read<SettingsService>().settings;
      final printerService = PrinterService(bt);
      await printerService.printImage(
        _processedImageBytes!,
        density: settings.printDensity.value,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo printed successfully!'),
            backgroundColor: AppColors.connectedGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppColors.disconnectedRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Thermal Preview'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showAdjustments ? Icons.tune : Icons.tune_outlined,
            ),
            onPressed: () {
              setState(() => _showAdjustments = !_showAdjustments);
            },
            tooltip: 'Adjustments',
          ),
        ],
      ),
      body: Column(
        children: [
          // Paper size indicator
          Consumer<SettingsService>(
            builder: (context, ss, _) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[200],
                child: Text(
                  'Paper: ${ss.settings.paperSize.label} (${ss.settings.paperSize.widthPx}px)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),

          // Thermal preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ThermalPreviewWidget(
                processedImageBytes: _processedImageBytes,
                isProcessing: _isProcessing,
                paperWidthPx:
                    context.read<SettingsService>().settings.paperSize.widthPx,
              ),
            ),
          ),

          // Adjustment controls (collapsible)
          if (_showAdjustments)
            ImageAdjustmentControls(
              brightness: _brightness,
              contrast: _contrast,
              invertColors: _invertColors,
              rotation: _rotation,
              onBrightnessChanged: (val) {
                setState(() => _brightness = val);
                _debouncedProcess();
              },
              onContrastChanged: (val) {
                setState(() => _contrast = val);
                _debouncedProcess();
              },
              onInvertChanged: (val) {
                setState(() => _invertColors = val);
                _processImage();
              },
              onRotate: () {
                setState(() => _rotation = (_rotation + 90) % 360);
                _processImage();
              },
            ),

          // Print button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isPrinting || _isProcessing || _processedImageBytes == null
                        ? null
                        : _printImage,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print),
                label: Text(_isPrinting ? 'Printing...' : 'Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
