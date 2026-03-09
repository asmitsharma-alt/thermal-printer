import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ThermalPreviewWidget extends StatelessWidget {
  final Uint8List? processedImageBytes;
  final bool isProcessing;
  final int paperWidthPx;

  const ThermalPreviewWidget({
    super.key,
    required this.processedImageBytes,
    this.isProcessing = false,
    this.paperWidthPx = 384,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale paper width to fill most of the screen width
    final double paperDisplayWidth = screenWidth * 0.85;

    return Center(
      child: Container(
        width: paperDisplayWidth,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: AppColors.thermalPaper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildContent(paperDisplayWidth),
        ),
      ),
    );
  }

  Widget _buildContent(double displayWidth) {
    if (isProcessing) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Processing image...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (processedImageBytes == null) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No image to preview',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.memory(
        processedImageBytes!,
        fit: BoxFit.fitWidth,
        width: displayWidth - 16,
        filterQuality: FilterQuality.none, // Keep sharp pixels for thermal
      ),
    );
  }
}
