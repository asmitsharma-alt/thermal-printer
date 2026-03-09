import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../utils/constants.dart';

class PrinterStatusBar extends StatelessWidget {
  const PrinterStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothService>(
      builder: (context, bt, _) {
        final bool connected = bt.isConnected;
        final String statusText = connected
            ? 'Connected: ${bt.connectedDevice?.name ?? "Unknown"}'
            : bt.connectionState == BtConnectionState.connecting
                ? 'Connecting...'
                : 'No Printer Connected';

        final Color statusColor = connected
            ? AppColors.connectedGreen
            : bt.connectionState == BtConnectionState.connecting
                ? Colors.orange
                : AppColors.disconnectedRed;

        final IconData statusIcon = connected
            ? Icons.print
            : bt.connectionState == BtConnectionState.connecting
                ? Icons.bluetooth_searching
                : Icons.print_disabled;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: statusColor.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
