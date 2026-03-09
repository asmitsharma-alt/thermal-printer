import 'package:flutter_test/flutter_test.dart';
import 'package:thermal_printer_app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ThermalPrinterApp());
    await tester.pumpAndSettle();

    expect(find.text('Thermal Printer'), findsWidgets);
    expect(find.text('Camera Print'), findsOneWidget);
    expect(find.text('Gallery Print'), findsOneWidget);
  });
}
