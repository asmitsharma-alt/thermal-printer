import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/print_settings.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          final settings = settingsService.settings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Printer settings section
              _buildSectionHeader('Printer'),
              _buildCard(
                children: [
                  // Paper size
                  ListTile(
                    leading: const Icon(Icons.straighten),
                    title: const Text('Paper Size'),
                    subtitle: Text(settings.paperSize.label),
                    trailing: DropdownButton<PaperSize>(
                      value: settings.paperSize,
                      underline: const SizedBox(),
                      items: PaperSize.values
                          .map((size) => DropdownMenuItem(
                                value: size,
                                child: Text(size.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          settingsService.updateSettings(
                            settings.copyWith(paperSize: value),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // Print density
                  ListTile(
                    leading: const Icon(Icons.opacity),
                    title: const Text('Print Density'),
                    subtitle: Text(settings.printDensity.label),
                    trailing: DropdownButton<PrintDensity>(
                      value: settings.printDensity,
                      underline: const SizedBox(),
                      items: PrintDensity.values
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          settingsService.updateSettings(
                            settings.copyWith(printDensity: value),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Camera settings section
              _buildSectionHeader('Camera'),
              _buildCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.bolt),
                    title: const Text('Auto Print After Capture'),
                    subtitle: const Text(
                        'Automatically print photo after taking it'),
                    value: settings.autoPrint,
                    onChanged: (value) {
                      settingsService.updateSettings(
                        settings.copyWith(autoPrint: value),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Image settings section
              _buildSectionHeader('Image Processing'),
              _buildCard(
                children: [
                  // Default brightness
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Default Brightness'),
                    subtitle: Slider(
                      value: settings.brightness,
                      min: -100,
                      max: 100,
                      divisions: 200,
                      label: settings.brightness.round().toString(),
                      onChanged: (value) {
                        settingsService.updateSettings(
                          settings.copyWith(brightness: value),
                        );
                      },
                    ),
                    trailing: Text(
                      '${settings.brightness.round()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),

                  // Default contrast
                  ListTile(
                    leading: const Icon(Icons.contrast),
                    title: const Text('Default Contrast'),
                    subtitle: Slider(
                      value: settings.contrast,
                      min: -100,
                      max: 100,
                      divisions: 200,
                      label: settings.contrast.round().toString(),
                      onChanged: (value) {
                        settingsService.updateSettings(
                          settings.copyWith(contrast: value),
                        );
                      },
                    ),
                    trailing: Text(
                      '${settings.contrast.round()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Connection settings section
              _buildSectionHeader('Connection'),
              _buildCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.bluetooth),
                    title: const Text('Remember Last Printer'),
                    subtitle: const Text(
                        'Auto-reconnect to the last used printer'),
                    value: settings.rememberLastPrinter,
                    onChanged: (value) {
                      settingsService.updateSettings(
                        settings.copyWith(rememberLastPrinter: value),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Preview settings
              _buildSectionHeader('Preview'),
              _buildCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.preview),
                    title: const Text('Enable Thermal Preview'),
                    subtitle: const Text(
                        'Show preview before printing'),
                    value: settings.enablePreview,
                    onChanged: (value) {
                      settingsService.updateSettings(
                        settings.copyWith(enablePreview: value),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Thermal Photo Studio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.highlight,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}
