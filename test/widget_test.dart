// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mi_xia/providers/vault_provider.dart';
import 'package:mi_xia/screens/home_screen.dart';
import 'package:mi_xia/screens/settings_screen.dart';
import 'package:mi_xia/theme/app_theme.dart';

void main() {
  testWidgets('iOS-inspired theme renders the app surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Center(child: Text('密匣'))),
      ),
    );

    expect(find.text('密匣'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('密匣'))).colorScheme.primary,
      AppColors.accent,
    );
  });

  testWidgets('vault dashboard adapts without layout overflow', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpDashboard(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => VaultProvider(),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await pumpDashboard(const Size(375, 812));
    expect(find.text('你的数字保险库'), findsOneWidget);
    expect(find.text('保险库概览'), findsOneWidget);

    await pumpDashboard(const Size(812, 375));
    expect(find.text('生成密码'), findsOneWidget);

    await pumpDashboard(const Size(1440, 900));
    expect(find.text('分类浏览'), findsOneWidget);
  });

  testWidgets('light theme keeps settings readable and switches distinct', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VaultProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    final title = tester.widget<Text>(find.text('锁定密码库'));
    expect(title.style?.color, AppColors.lightInk);

    final context = tester.element(find.byType(Switch).first);
    final switchTheme = Theme.of(context).switchTheme;
    final selected = switchTheme.trackColor?.resolve({WidgetState.selected});
    final unselected = switchTheme.trackColor?.resolve({});
    expect(selected, const Color(0xFF0F766E));
    expect(unselected, const Color(0xFFCBD5E1));
    expect(selected, isNot(unselected));
  });
}
