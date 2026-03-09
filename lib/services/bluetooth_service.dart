import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/printer_device.dart';

enum BtConnectionState { disconnected, connecting, connected }

class BluetoothService extends ChangeNotifier {
  FlutterBluetoothSerial get _bluetooth => FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  BtConnectionState _connectionState = BtConnectionState.disconnected;
  PrinterDevice? _connectedDevice;
  StreamSubscription? _scanSubscription;
  final List<PrinterDevice> _discoveredDevices = [];
  bool _isScanning = false;
  String? _permissionError;

  BtConnectionState get connectionState => _connectionState;
  PrinterDevice? get connectedDevice => _connectedDevice;
  List<PrinterDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  bool get isConnected => _connectionState == BtConnectionState.connected;
  bool get isScanning => _isScanning;
  String? get permissionError => _permissionError;

  /// Request all Bluetooth runtime permissions
  Future<bool> requestPermissions() async {
    _permissionError = null;

    if (!Platform.isAndroid) return true;

    // Android 12+ (API 31+): need BLUETOOTH_CONNECT and BLUETOOTH_SCAN
    // Older Android: need ACCESS_FINE_LOCATION
    final List<Permission> permissions = [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ];

    final statuses = await permissions.request();

    final connectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? true;
    final scanGranted =
        statuses[Permission.bluetoothScan]?.isGranted ?? true;
    final locationGranted =
        statuses[Permission.location]?.isGranted ?? true;

    if (!connectGranted || !scanGranted) {
      // Check if permanently denied
      if (statuses[Permission.bluetoothConnect]?.isPermanentlyDenied == true ||
          statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true) {
        _permissionError =
            'Bluetooth permissions permanently denied. Please enable them in Settings.';
      } else {
        _permissionError =
            'Bluetooth permissions are required to find and connect to printers.';
      }
      notifyListeners();
      return false;
    }

    if (!locationGranted) {
      if (statuses[Permission.location]?.isPermanentlyDenied == true) {
        _permissionError =
            'Location permission permanently denied. Required for Bluetooth scanning on this device.';
      } else {
        _permissionError =
            'Location permission is required for Bluetooth device scanning.';
      }
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Check if Bluetooth is enabled
  Future<bool> get isBluetoothEnabled async {
    return await _bluetooth.isEnabled ?? false;
  }

  /// Request to enable Bluetooth
  Future<bool> requestEnableBluetooth() async {
    return await _bluetooth.requestEnable() ?? false;
  }

  /// Get bonded (paired) devices
  Future<List<PrinterDevice>> getBondedDevices() async {
    try {
      final List<BluetoothDevice> bonded = await _bluetooth.getBondedDevices();
      return bonded
          .map((d) => PrinterDevice(
                name: d.name ?? 'Unknown',
                address: d.address,
                isBonded: d.isBonded,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  /// Start scanning for nearby Bluetooth devices
  Future<void> startScan() async {
    if (_isScanning) return;

    // Request permissions first
    final granted = await requestPermissions();
    if (!granted) return;

    _discoveredDevices.clear();
    _isScanning = true;
    _permissionError = null;
    notifyListeners();

    // Add bonded devices first
    final bonded = await getBondedDevices();
    _discoveredDevices.addAll(bonded);
    notifyListeners();

    // Start discovery
    try {
      _scanSubscription = _bluetooth.startDiscovery().listen(
        (BluetoothDiscoveryResult result) {
          final device = PrinterDevice(
            name: result.device.name ?? 'Unknown',
            address: result.device.address,
            isBonded: result.device.isBonded,
          );
          if (!_discoveredDevices.contains(device)) {
            _discoveredDevices.add(device);
            notifyListeners();
          }
        },
        onDone: () {
          _isScanning = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Scan error: $e');
          _isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to start discovery: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a printer device
  Future<void> connect(PrinterDevice device) async {
    if (_connectionState == BtConnectionState.connecting) return;

    // Ensure permissions are granted before connecting
    final granted = await requestPermissions();
    if (!granted) {
      throw Exception(_permissionError ?? 'Bluetooth permissions not granted');
    }

    _connectionState = BtConnectionState.connecting;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(device.address)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Connection timed out after 15 seconds');
      });
      _connectedDevice = device;
      _connectionState = BtConnectionState.connected;

      // Listen for disconnection
      _connection!.input?.listen(
        (_) {},
        onDone: () {
          _handleDisconnect();
        },
        onError: (_) {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _connectionState = BtConnectionState.disconnected;
      _connectedDevice = null;
      _connection = null;
      notifyListeners();
      rethrow;
    }

    notifyListeners();
  }

  void _handleDisconnect() {
    _connectionState = BtConnectionState.disconnected;
    _connectedDevice = null;
    _connection = null;
    notifyListeners();
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _handleDisconnect();
  }

  /// Send raw bytes to the printer.
  ///
  /// All chunks are added to the Bluetooth output buffer first and we await
  /// [allSent] only once at the end. This keeps the BT stream saturated so the
  /// thermal head never stalls mid-image (which would cause horizontal banding).
  Future<void> sendBytes(Uint8List data,
      {int chunkSize = 4096, Duration delay = const Duration(milliseconds: 5)}) async {
    if (_connection == null || !isConnected) {
      throw Exception('Printer not connected');
    }

    final output = _connection!.output;

    // Feed all chunks into the output buffer without waiting between them
    int offset = 0;
    while (offset < data.length) {
      final int end =
          (offset + chunkSize > data.length) ? data.length : offset + chunkSize;
      output.add(Uint8List.fromList(data.sublist(offset, end)));
      offset = end;
      // Tiny yield so the event loop can process ACKs and keep the socket alive
      if (offset < data.length) {
        await Future.delayed(delay);
      }
    }

    // Wait once for all bytes to actually leave the socket
    await output.allSent;
  }

  /// Auto-reconnect to a specific address
  Future<bool> autoReconnect(String address, String name) async {
    try {
      final device = PrinterDevice(name: name, address: address);
      await connect(device);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connection?.close();
    super.dispose();
  }
}
