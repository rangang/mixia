import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color bg = Color(0xFF0B1220);
  static const Color bg2 = Color(0xFF111C2F);
  static const Color bg3 = Color(0xFF18263D);
  static const Color ink = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFFA7B3C5);
  static const Color rule = Color(0xFF2B3A52);
  static const Color accent = Color(0xFF2DD4BF);
  static const Color onAccent = Color(0xFF042F2E);
  static const Color accent2 = Color(0xFFF59E0B);
  static const Color accent3 = Color(0xFF818CF8);
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);

  static const Color lightBg = Color(0xFFF4F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF0F4F8);
  static const Color lightInk = Color(0xFF162033);
  static const Color lightMuted = Color(0xFF5E6B7E);
  static const Color lightRule = Color(0xFFD8E0EA);
}

extension AppThemeColors on BuildContext {
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appElevatedSurface =>
      Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appMutedText => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appBorder => Theme.of(this).colorScheme.outlineVariant;
}

class AppTheme {
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.bg : AppColors.lightBg;
    final surface = isDark ? AppColors.bg2 : AppColors.lightSurface;
    final elevated = isDark ? AppColors.bg3 : AppColors.lightElevated;
    final ink = isDark ? AppColors.ink : AppColors.lightInk;
    final muted = isDark ? AppColors.muted : AppColors.lightMuted;
    final rule = isDark ? AppColors.rule : AppColors.lightRule;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent3,
      onSecondary: const Color(0xFF111827),
      error: AppColors.error,
      onError: const Color(0xFF3A0906),
      surface: surface,
      surfaceContainerHighest: elevated,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: rule,
      outlineVariant: rule.withValues(alpha: 0.7),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'BricolageGrotesque',
      fontFamilyFallback: const [
        'MiXia CJK',
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      brightness: brightness,
      colorScheme: colorScheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: background,
        barBackgroundColor: surface.withOpacity(0.88),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.accent,
          textStyle: TextStyle(color: ink, fontSize: 17),
          navTitleTextStyle: TextStyle(
            color: ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: ink,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
      primaryColor: AppColors.accent,
      splashFactory: InkRipple.splashFactory,
      focusColor: AppColors.accent.withOpacity(0.18),
      hoverColor: ink.withOpacity(0.04),
      pageTransitionsTheme: _pageTransitions,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: background.withOpacity(0.92),
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.accent, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColors.accent,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: rule.withOpacity(0.7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: rule.withOpacity(0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.accent.withOpacity(0.35),
          disabledForegroundColor: AppColors.onAccent.withOpacity(0.55),
          elevation: 0,
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: rule),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent.withOpacity(0.9),
        foregroundColor: AppColors.onAccent,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated.withOpacity(0.96),
        contentTextStyle: TextStyle(color: ink),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionTextColor: AppColors.accent,
      ),
      dividerTheme: DividerThemeData(
        color: rule.withOpacity(0.7),
        thickness: 0.5,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return muted.withOpacity(0.55);
          }
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? const Color(0xFFCBD5E1) : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return elevated;
          }
          if (states.contains(WidgetState.selected)) {
            return isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
          }
          return isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return rule;
        }),
        overlayColor: WidgetStatePropertyAll(
          AppColors.accent.withOpacity(0.12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: ink,
        iconColor: AppColors.accent,
        minTileHeight: 50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface.withOpacity(0.98),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: muted,
          focusColor: AppColors.accent.withOpacity(0.18),
          hoverColor: AppColors.accent.withOpacity(0.08),
          highlightColor: AppColors.accent.withOpacity(0.12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: ink, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: ink, height: 1.5),
        bodyMedium: TextStyle(color: ink, height: 1.5),
        bodySmall: TextStyle(color: muted, height: 1.45),
        labelLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: muted),
        labelSmall: TextStyle(color: muted),
      ),
    );
  }
}
