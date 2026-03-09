import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../models/canvas_item.dart';
import '../services/bluetooth_service.dart';
import '../services/settings_service.dart';
import '../utils/dithering.dart';
import '../utils/esc_pos_helper.dart';

class StickerPrintScreen extends StatefulWidget {
  const StickerPrintScreen({super.key});

  @override
  State<StickerPrintScreen> createState() => _StickerPrintScreenState();
}

class _StickerPrintScreenState extends State<StickerPrintScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<CanvasItem> _items = [];
  int _nextId = 0;
  String? _selectedItemId;
  bool _isPrinting = false;
  int _borderStyle = 0; // 0=none,1=solid,2=double,3=dashed,4=decorative

  static const List<String> _emojis = [
    '😀', '😎', '🥳', '😍', '🤩', '😂', '🥰', '🤗',
    '🔥', '⭐', '❤️', '💎', '🎉', '🎁', '🌟', '💯',
    '👍', '👏', '✌️', '🤟', '💪', '🙌', '🎵', '🎶',
    '☀️', '🌈', '🌺', '🍀', '🦋', '🐾', '🏆', '👑',
  ];

  static const List<String> _symbols = [
    '★', '☆', '♥', '♦', '♣', '♠', '●', '○',
    '■', '□', '▲', '△', '▼', '▽', '◆', '◇',
    '✦', '✧', '✪', '✫', '✿', '❀', '❁', '❂',
    '⚡', '☎', '✈', '☮', '☯', '♫', '✂', '☁',
  ];

  static const List<String> _borderLabels = [
    'None', 'Solid', 'Double', 'Dashed', 'Decorative',
  ];

  // ─── item management ──────────────────────────────────────

  void _addTextItem() {
    final controller = TextEditingController(text: 'Hello');
    double fontSize = 28;
    bool bold = false;
    bool italic = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            title: const Text('Add Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(labelText: 'Text content'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Size:'),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 10,
                          max: 80,
                          onChanged: (v) => setS(() => fontSize = v),
                        ),
                      ),
                      Text(fontSize.round().toString()),
                    ],
                  ),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Bold'),
                        selected: bold,
                        onSelected: (v) => setS(() => bold = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Italic'),
                        selected: italic,
                        onSelected: (v) => setS(() => italic = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  _addItem(CanvasItem(
                    id: 'item_${_nextId++}',
                    type: CanvasItemType.text,
                    content: controller.text.trim(),
                    fontSize: fontSize,
                    bold: bold,
                    italic: italic,
                  ));
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    ).then((_) => controller.dispose());
  }

  void _showEmojiPicker() {
    _showGridPicker('Pick Emoji', _emojis, CanvasItemType.emoji, 36);
  }

  void _showStickerPicker() {
    _showGridPicker('Pick Symbol', _symbols, CanvasItemType.symbol, 32);
  }

  void _showGridPicker(
      String title, List<String> items, CanvasItemType type, double size) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items.map((item) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addItem(CanvasItem(
                        id: 'item_${_nextId++}',
                        type: type,
                        content: item,
                        fontSize: size,
                      ));
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item, style: TextStyle(fontSize: size * 0.7)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBorderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Border Style',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...List.generate(_borderLabels.length, (i) {
                return ListTile(
                  leading: Icon(
                    i == _borderStyle
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: i == _borderStyle ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(_borderLabels[i]),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _borderStyle = i);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _addItem(CanvasItem item) {
    setState(() {
      _items.add(item);
      _selectedItemId = item.id;
    });
  }

  void _deleteSelected() {
    if (_selectedItemId == null) return;
    setState(() {
      _items.removeWhere((i) => i.id == _selectedItemId);
      _selectedItemId = null;
    });
  }

  // ─── canvas capture & print ───────────────────────────────

  Future<void> _captureAndPrint() async {
    final bt = context.read<BluetoothService>();
    final settings = context.read<SettingsService>().settings;
    if (!bt.isConnected) {
      _showSnack('Printer not connected');
      return;
    }
    if (_items.isEmpty && _borderStyle == 0) {
      _showSnack('Canvas is empty');
      return;
    }

    setState(() => _isPrinting = true);

    try {
      // Capture canvas to image
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Canvas not ready');

      final ui.Image uiImage = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose();

      if (byteData == null) throw Exception('Failed to capture canvas');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Decode, resize to printer width, grayscale, dither
      final int printerWidth = settings.paperSize.widthPx;

      img.Image? decoded = img.decodePng(pngBytes);
      if (decoded == null) throw Exception('Failed to decode captured image');

      // Resize to printer width keeping aspect ratio
      if (decoded.width != printerWidth) {
        decoded = img.copyResize(decoded, width: printerWidth);
      }

      // Grayscale
      img.grayscale(decoded);

      // Floyd-Steinberg dither
      final img.Image dithered = floydSteinbergDithering(decoded);

      // Build ESC/POS job & send
      final Uint8List printData = EscPosHelper.buildPrintJob(dithered,
          density: settings.printDensity.value);
      await bt.sendBytes(printData);

      if (mounted) _showSnack('Printed successfully!');
    } catch (e) {
      if (mounted) _showSnack('Print failed: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  // ─── border decoration ────────────────────────────────────

  BoxDecoration? _buildBorderDecoration() {
    switch (_borderStyle) {
      case 1:
        return BoxDecoration(border: Border.all(color: Colors.black, width: 3));
      case 2:
        return BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              spreadRadius: 0,
              blurRadius: 0,
              offset: Offset.zero,
            ),
          ],
        );
      case 3:
        return BoxDecoration(
          border: Border.all(color: Colors.black54, width: 2),
        );
      case 4:
        return BoxDecoration(
          border: Border.all(color: Colors.black, width: 4),
          borderRadius: BorderRadius.circular(12),
        );
      default:
        return null;
    }
  }

  // ─── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker & Text'),
        actions: [
          if (_selectedItemId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelected,
              tooltip: 'Delete selected',
            ),
          IconButton(
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print),
            onPressed: _isPrinting ? null : _captureAndPrint,
            tooltip: 'Print',
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.7,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      color: Colors.white,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Border
                          if (_borderStyle > 0)
                            Positioned.fill(
                              child: Container(
                                decoration: _buildBorderDecoration(),
                              ),
                            ),
                          // Draggable items
                          ..._items.map((item) => _buildDraggableItem(item)),
                          // Tap to deselect
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () =>
                                  setState(() => _selectedItemId = null),
                            ),
                          ),
                          // Draggable items on top of deselect gesture
                          ..._items.map((item) => _buildDraggableItem(item)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Toolbar
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.text_fields,
                  label: 'Text',
                  onTap: _addTextItem,
                ),
                _ToolButton(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Emoji',
                  onTap: _showEmojiPicker,
                ),
                _ToolButton(
                  icon: Icons.star_outline,
                  label: 'Sticker',
                  onTap: _showStickerPicker,
                ),
                _ToolButton(
                  icon: Icons.border_style,
                  label: 'Border',
                  onTap: _showBorderPicker,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(CanvasItem item) {
    final bool isSelected = item.id == _selectedItemId;

    Widget child;
    switch (item.type) {
      case CanvasItemType.text:
        child = Text(
          item.content,
          style: TextStyle(
            fontSize: item.fontSize,
            fontWeight: item.bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
            color: Colors.black,
          ),
        );
      case CanvasItemType.emoji:
      case CanvasItemType.symbol:
        child = Text(
          item.content,
          style: TextStyle(fontSize: item.fontSize),
        );
    }

    return Positioned(
      left: item.x,
      top: item.y,
      child: GestureDetector(
        onTap: () => setState(() => _selectedItemId = item.id),
        onPanUpdate: (details) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx == -1) return;
            _items[idx] = item.copyWith(
              x: item.x + details.delta.dx,
              y: item.y + details.delta.dy,
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
