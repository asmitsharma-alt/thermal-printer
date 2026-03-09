import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/bluetooth_service.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/gallery_preview_screen.dart';
import 'screens/thermal_preview_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sticker_print_screen.dart';
import 'utils/constants.dart';

class ThermalPrinterApp extends StatelessWidget {
  const ThermalPrinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) {
          final service = SettingsService();
          service.init();
          return service;
        }),
      ],
      child: MaterialApp(
        title: 'Thermal Printer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppColors.primary,
          scaffoldBackgroundColor: AppColors.surface,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/bluetooth': (context) => const BluetoothScreen(),
          '/camera': (context) => const CameraScreen(),
          '/gallery': (context) => const GalleryPreviewScreen(),
          '/preview': (context) => const ThermalPreviewScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/sticker': (context) => const StickerPrintScreen(),
        },
      ),
    );
  }
}
