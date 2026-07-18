// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_xia/theme/app_theme.dart';

void main() {
  testWidgets('iOS-inspired theme renders the app surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: Text('密匣')),
        ),
      ),
    );

    expect(find.text('密匣'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('密匣'))).colorScheme.primary,
      AppColors.accent,
    );
  });
}
