import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/printer_device.dart';
import '../services/bluetooth_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final bt = context.read<BluetoothService>();

    // Request Bluetooth permissions first
    final permissionsGranted = await bt.requestPermissions();
    if (!permissionsGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bt.permissionError ?? 'Bluetooth permissions required'),
          backgroundColor: AppColors.disconnectedRed,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    // Check if Bluetooth is enabled
    final isEnabled = await bt.isBluetoothEnabled;
    if (!isEnabled) {
      if (!mounted) return;
      final enabled = await bt.requestEnableBluetooth();
      if (!enabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth must be enabled to connect a printer'),
            backgroundColor: AppColors.disconnectedRed,
          ),
        );
        return;
      }
    }

    if (mounted) bt.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Connect Printer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<BluetoothService>(
            builder: (context, bt, _) {
              return IconButton(
                icon: bt.isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: bt.isScanning ? bt.stopScan : bt.startScan,
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothService>(
        builder: (context, bt, _) {
          return Column(
            children: [
              // Connection status
              if (bt.isConnected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.connectedGreen.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth_connected,
                          color: AppColors.connectedGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connected to ${bt.connectedDevice?.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.connectedGreen,
                              ),
                            ),
                            Text(
                              bt.connectedDevice?.address ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _disconnect(bt),
                        child: const Text('Disconnect',
                            style: TextStyle(color: AppColors.disconnectedRed)),
                      ),
                    ],
                  ),
                ),

              // Scanning indicator
              if (bt.isScanning)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.highlight,
                ),

              // Permission error banner
              if (bt.permissionError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.disconnectedRed.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.disconnectedRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bt.permissionError!,
                          style: const TextStyle(
                            color: AppColors.disconnectedRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => openAppSettings(),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ),

              // Device list
              Expanded(
                child: bt.permissionError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth_disabled,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'Permissions required',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _initBluetooth(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : bt.discoveredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth_searching,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              bt.isScanning
                                  ? 'Searching for devices...'
                                  : 'No devices found',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            if (!bt.isScanning) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Make sure your printer is turned on\nand in pairing mode',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton.icon(
                                  onPressed: bt.startScan,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Scan Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: bt.discoveredDevices.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final device = bt.discoveredDevices[index];
                          final bool isCurrentlyConnected =
                              bt.isConnected &&
                                  bt.connectedDevice?.address ==
                                      device.address;
                          final bool isConnecting =
                              bt.connectionState ==
                                      BtConnectionState.connecting;

                          return _DeviceCard(
                            name: device.name,
                            address: device.address,
                            isBonded: device.isBonded,
                            isConnected: isCurrentlyConnected,
                            isConnecting: isConnecting,
                            onTap: isConnecting
                                ? null
                                : () => _connectToDevice(bt, device),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _connectToDevice(
      BluetoothService bt, PrinterDevice device) async {
    try {
      if (bt.isConnected && bt.connectedDevice?.address == device.address) {
        await _disconnect(bt);
        return;
      }
      if (bt.isConnected) {
        await bt.disconnect();
      }
      await bt.connect(device);

      // Save as last printer
      if (!mounted) return;
      final settings = context.read<SettingsService>();
      if (settings.settings.rememberLastPrinter) {
        await settings.saveLastPrinter(device.name, device.address);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: AppColors.connectedGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: ${e.toString()}'),
          backgroundColor: AppColors.disconnectedRed,
        ),
      );
    }
  }

  Future<void> _disconnect(BluetoothService bt) async {
    await bt.disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer disconnected')),
      );
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final String name;
  final String address;
  final bool isBonded;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback? onTap;

  const _DeviceCard({
    required this.name,
    required this.address,
    required this.isBonded,
    required this.isConnected,
    required this.isConnecting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isConnected ? AppColors.connectedGreen.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.connectedGreen.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: isConnected
                      ? AppColors.connectedGreen
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (isBonded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Paired',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              if (isConnected)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.connectedGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.connectedGreen),
                  ),
                ),
              if (isConnecting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
