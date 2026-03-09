class PrinterDevice {
  final String name;
  final String address;
  final bool isBonded;

  const PrinterDevice({
    required this.name,
    required this.address,
    this.isBonded = false,
  });

  @override
  String toString() => 'PrinterDevice($name, $address)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterDevice &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}
