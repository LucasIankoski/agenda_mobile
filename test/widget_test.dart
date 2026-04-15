import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic material smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Agenda Online'),
        ),
      ),
    );

    expect(find.text('Agenda Online'), findsOneWidget);
  });
}
