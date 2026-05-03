import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Placeholder test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Text('Test'),
      ),
    ));
    expect(find.text('Test'), findsOneWidget);
  });
}
