# Thermal Photo Printer

A Flutter-based Android application that lets you capture, process, and print photos on Bluetooth thermal printers. Designed for 58mm and 80mm ESC/POS receipt printers.

---

## Features

### Camera Print
- Capture photos directly from the device camera.
- Instantly preview and send to a connected thermal printer.

### Gallery Print
- Pick any image from the device gallery.
- View a real-time thermal preview before printing.

### Sticker & Text Canvas
- Compose custom layouts with text, emojis, and symbols.
- Drag-and-drop canvas with configurable font size, bold, italic.
- Add decorative borders (solid, double, dashed, decorative).
- Render the canvas to a thermal-printable image.

### Image Processing
- Floyd-Steinberg dithering for high-quality monochrome conversion.
- Adjustable **brightness** and **contrast** sliders with live preview.
- **Invert colors** toggle for negative-style prints.
- **Rotation** support (0°, 90°, 180°, 270°).
- Processing runs in a compute isolate to keep the UI responsive.

### Bluetooth Connectivity
- Scan for nearby Bluetooth Classic devices.
- View paired (bonded) devices for quick connection.
- Auto-reconnect to the last used printer (optional).
- Chunked data transfer with configurable chunk size to prevent buffer overflow.

### Print Settings
- **Paper size**: 58mm (384px) or 80mm (576px).
- **Print density**: Light / Medium / Dark.
- **Auto-print** mode.
- **Remember last printer** toggle.
- **Live thermal preview** toggle.
- All settings persisted via `SharedPreferences`.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart SDK ^3.11.1) |
| State Management | Provider (`ChangeNotifierProvider`) |
| Bluetooth | `flutter_bluetooth_serial` (Classic BT) |
| Camera | `camera` plugin |
| Image Processing | `image` package + custom Floyd-Steinberg dithering |
| Persistence | `shared_preferences` |
| Permissions | `permission_handler` |
| Gallery | `image_picker` |

---

## Project Structure

```
lib/
├── main.dart                     # Entry point
├── app.dart                      # MaterialApp with routes & theming
├── models/
│   ├── canvas_item.dart          # Sticker canvas item model
│   ├── print_settings.dart       # Paper size, density, adjustments
│   └── printer_device.dart       # Bluetooth printer model
├── screens/
│   ├── home_screen.dart          # Home dashboard with action cards
│   ├── bluetooth_screen.dart     # Device scanning & connection
│   ├── camera_screen.dart        # Camera capture
│   ├── gallery_preview_screen.dart  # Gallery image picker
│   ├── thermal_preview_screen.dart  # Preview & adjustment before print
│   ├── sticker_print_screen.dart    # Text/emoji/symbol canvas
│   └── settings_screen.dart      # App settings
├── services/
│   ├── bluetooth_service.dart    # BT permissions, scan, connect, send
│   ├── image_processing_service.dart  # Image pipeline (isolate-based)
│   ├── printer_service.dart      # ESC/POS print orchestration
│   └── settings_service.dart     # SharedPreferences wrapper
├── utils/
│   ├── constants.dart            # Colors, sizes, pref keys
│   ├── dithering.dart            # Floyd-Steinberg dithering algorithm
│   └── esc_pos_helper.dart       # ESC/POS raster command builder
└── widgets/
    ├── image_adjustment_controls.dart  # Brightness/contrast/invert sliders
    ├── printer_status_bar.dart         # Connection status indicator
    └── thermal_preview_widget.dart     # Thermal-paper-styled preview
```

---

## Getting Started

### Prerequisites

- **Flutter SDK** ^3.11.1
- **Android Studio** or **VS Code** with Flutter extension
- An Android device with **Bluetooth Classic** support
- A 58mm or 80mm **ESC/POS thermal printer**

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd thermal_printer_app

# Install dependencies
flutter pub get

# Run on a connected Android device
flutter run
```

### Permissions

The app requests the following Android permissions at runtime:

| Permission | Purpose |
|---|---|
| `BLUETOOTH_CONNECT` | Connect to paired printers (Android 12+) |
| `BLUETOOTH_SCAN` | Discover nearby printers (Android 12+) |
| `ACCESS_FINE_LOCATION` | Required for BT discovery on older Android |
| `CAMERA` | Capture photos for printing |
| `READ_EXTERNAL_STORAGE` | Access gallery images |

---

## How It Works

1. **Connect** — Pair and connect to a thermal printer via Bluetooth Classic.
2. **Capture / Select** — Take a photo with the camera or pick one from the gallery.
3. **Preview & Adjust** — View a thermal-paper-styled preview. Tune brightness, contrast, and rotation.
4. **Print** — The image is dithered using Floyd-Steinberg, converted to ESC/POS raster bitmap (`GS v 0`), and sent over Bluetooth in chunks.

---

## ESC/POS Protocol

The app builds raw ESC/POS print jobs:

- `ESC @` — Initialize printer
- `GS 7 n` — Set print density
- `GS v 0` — Print raster bitmap (widest printer compatibility)
- `ESC d n` — Feed paper after print

---

## Configuration

Default settings can be changed from the **Settings** screen:

| Setting | Default | Options |
|---|---|---|
| Paper Size | 58mm | 58mm, 80mm |
| Print Density | Medium | Light, Medium, Dark |
| Auto Print | Off | On/Off |
| Remember Printer | On | On/Off |
| Preview Enabled | On | On/Off |
| Brightness | 0 | -100 to +100 |
| Contrast | 0 | -100 to +100 |

---

## Compatibility

- **Platform**: Android only (Bluetooth Classic requires Android APIs)
- **Printers**: Any ESC/POS compatible 58mm or 80mm thermal receipt printer
- **Tested with**: Generic Bluetooth receipt printers, POS-5802, POS-8002

---

## License

This project is provided as-is for personal and educational use.
