import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:versz/widgets/common/verz_logo.dart';

void main() {
  testWidgets('Splash logo smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: VerzLogo()),
        ),
      ),
    );

    expect(find.text('V'), findsOneWidget);
  });
}
