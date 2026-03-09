import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../widgets/printer_status_bar.dart';
import '../utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Printer status bar at top
            const PrinterStatusBar(),

            // App header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.print, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thermal Printer',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Photo Print Studio',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main action buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera Print',
                            subtitle: 'Capture & print',
                            color: const Color(0xFF6C63FF),
                            onTap: () =>
                                Navigator.pushNamed(context, '/camera'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery Print',
                            subtitle: 'Print from photos',
                            color: const Color(0xFF00BFA6),
                            onTap: () =>
                                Navigator.pushNamed(context, '/gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.auto_awesome,
                            label: 'Sticker & Text',
                            subtitle: 'Emoji, text, shapes',
                            color: const Color(0xFFFF9800),
                            onTap: () =>
                                Navigator.pushNamed(context, '/sticker'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer<BluetoothService>(
                            builder: (context, bt, _) {
                              return _ActionCard(
                                icon: bt.isConnected
                                    ? Icons.bluetooth_connected
                                    : Icons.bluetooth,
                                label: 'Printer',
                                subtitle: bt.isConnected
                                    ? 'Connected'
                                    : 'Connect now',
                                color: bt.isConnected
                                    ? AppColors.connectedGreen
                                    : const Color(0xFFFF6B6B),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/bluetooth'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ActionCard(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      subtitle: 'Configure app',
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom branding
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Thermal Photo Studio v1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
