import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class IosBackdrop extends StatelessWidget {
  final Widget child;

  const IosBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.bg : AppColors.lightBg;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        gradient: RadialGradient(
          center: const Alignment(0.75, -1),
          radius: 1.25,
          colors: [
            AppColors.accent.withOpacity(isDark ? 0.18 : 0.10),
            background.withOpacity(0),
          ],
        ),
      ),
      child: child,
    );
  }
}

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;

    final surface = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white)
                .withOpacity(isDark ? 0.10 : 0.58),
            borderRadius: borderRadius,
            border: Border.all(color: ink.withOpacity(isDark ? 0.14 : 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: surface,
        ),
      ),
    );
  }
}
