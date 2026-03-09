enum PaperSize {
  mm58(384, '58mm'),
  mm80(576, '80mm');

  final int widthPx;
  final String label;
  const PaperSize(this.widthPx, this.label);
}

enum PrintDensity {
  light(0, 'Light'),
  medium(1, 'Medium'),
  dark(2, 'Dark');

  final int value;
  final String label;
  const PrintDensity(this.value, this.label);
}

class PrintSettings {
  final PaperSize paperSize;
  final bool autoPrint;
  final PrintDensity printDensity;
  final double brightness;
  final double contrast;
  final bool rememberLastPrinter;
  final bool enablePreview;
  final bool invertColors;

  const PrintSettings({
    this.paperSize = PaperSize.mm58,
    this.autoPrint = false,
    this.printDensity = PrintDensity.medium,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.rememberLastPrinter = true,
    this.enablePreview = true,
    this.invertColors = false,
  });

  PrintSettings copyWith({
    PaperSize? paperSize,
    bool? autoPrint,
    PrintDensity? printDensity,
    double? brightness,
    double? contrast,
    bool? rememberLastPrinter,
    bool? enablePreview,
    bool? invertColors,
  }) {
    return PrintSettings(
      paperSize: paperSize ?? this.paperSize,
      autoPrint: autoPrint ?? this.autoPrint,
      printDensity: printDensity ?? this.printDensity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      rememberLastPrinter: rememberLastPrinter ?? this.rememberLastPrinter,
      enablePreview: enablePreview ?? this.enablePreview,
      invertColors: invertColors ?? this.invertColors,
    );
  }
}
