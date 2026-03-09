enum CanvasItemType { text, emoji, symbol }

class CanvasItem {
  final String id;
  final CanvasItemType type;
  final String content;
  final double x;
  final double y;
  final double fontSize;
  final bool bold;
  final bool italic;

  const CanvasItem({
    required this.id,
    required this.type,
    required this.content,
    this.x = 50,
    this.y = 50,
    this.fontSize = 24,
    this.bold = false,
    this.italic = false,
  });

  CanvasItem copyWith({
    String? id,
    CanvasItemType? type,
    String? content,
    double? x,
    double? y,
    double? fontSize,
    bool? bold,
    bool? italic,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
    );
  }
}
