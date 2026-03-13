import 'package:flutter_test/flutter_test.dart';
import 'package:versz/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: VerszApp()));

    // Verify that splash screen text exists (placeholder state)
    expect(find.text('V'), findsOneWidget);
  });
}
