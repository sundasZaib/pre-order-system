import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pre_order_system/app/canteen_app.dart';

void main() {
  testWidgets('shows login screen on app launch', (WidgetTester tester) async {
    await tester.pumpWidget(const CanteenApp());

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Canteen Preorder'), findsOneWidget);
  });

  testWidgets('navigates to signup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CanteenApp());

    await tester.tap(find.text('New user? Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Signup'), findsOneWidget);
  });
}
