import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:navodya_spices/main.dart';
import 'package:navodya_spices/providers/app_provider.dart';

void main() {
  testWidgets('Navodya Spices app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const NavodyaSpicesApp(),
      ),
    );

    expect(find.text('NAVODYA SPICES'), findsOneWidget);
  });
}
