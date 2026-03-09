import 'package:flutter/material.dart';

class ImageAdjustmentControls extends StatelessWidget {
  final double brightness;
  final double contrast;
  final bool invertColors;
  final int rotation;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<bool> onInvertChanged;
  final VoidCallback onRotate;

  const ImageAdjustmentControls({
    super.key,
    required this.brightness,
    required this.contrast,
    required this.invertColors,
    required this.rotation,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onInvertChanged,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Image Adjustments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Brightness slider
          _buildSlider(
            icon: Icons.brightness_6,
            label: 'Brightness',
            value: brightness,
            min: -100,
            max: 100,
            onChanged: onBrightnessChanged,
          ),
          const SizedBox(height: 8),

          // Contrast slider
          _buildSlider(
            icon: Icons.contrast,
            label: 'Contrast',
            value: contrast,
            min: -100,
            max: 100,
            onChanged: onContrastChanged,
          ),
          const SizedBox(height: 16),

          // Rotate and Invert buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.rotate_right,
                label: 'Rotate $rotation°',
                onTap: onRotate,
              ),
              const SizedBox(width: 24),
              _buildToggleButton(
                icon: Icons.invert_colors,
                label: 'Invert',
                isActive: invertColors,
                onTap: () => onInvertChanged(!invertColors),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '$label: ${value.round()}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: Colors.blue, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? Colors.blue : null),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.blue : null,
                )),
          ],
        ),
      ),
    );
  }
}
