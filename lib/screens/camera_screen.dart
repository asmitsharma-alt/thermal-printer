import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/image_processing_service.dart';
import '../services/printer_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No camera available'),
                backgroundColor: AppColors.disconnectedRed),
          );
        }
        return;
      }
      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Camera error: $e'),
              backgroundColor: AppColors.disconnectedRed),
        );
      }
    }
  }

  Future<void> _setupCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final previous = _controller;
    _controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await previous?.dispose();

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _selectedCameraIndex = index;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to initialize camera: $e'),
              backgroundColor: AppColors.disconnectedRed),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List imageBytes = await File(file.path).readAsBytes();

      if (!mounted) return;

      final settingsService = context.read<SettingsService>();
      final settings = settingsService.settings;

      if (settings.autoPrint && settings.enablePreview == false) {
        // Direct print: process + print immediately
        final bt = context.read<BluetoothService>();
        if (!bt.isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Printer not connected! Go to Bluetooth settings.'),
                backgroundColor: AppColors.disconnectedRed,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }

        final processed = await ImageProcessingService.processForThermal(
          imageBytes: imageBytes,
          settings: settings,
        );

        final printerService = PrinterService(bt);
        await printerService.printImage(
          processed,
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
      } else {
        // Navigate to preview screen
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/preview',
            arguments: imageBytes,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.disconnectedRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _isFlashOn = !_isFlashOn;
    await _controller!
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _setupCamera(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize?.height ?? 0,
                      height: _controller!.value.previewSize?.width ?? 0,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                    Consumer<SettingsService>(
                      builder: (context, ss, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ss.settings.autoPrint
                                ? AppColors.connectedGreen.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ss.settings.autoPrint
                                ? 'AUTO PRINT ON'
                                : 'AUTO PRINT OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Gallery button
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/gallery');
                      },
                      icon: const Icon(Icons.photo_library,
                          color: Colors.white, size: 30),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndProcess,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                )
                              : Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Switch camera button
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.flip_camera_android,
                          color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),

            // Processing overlay
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
