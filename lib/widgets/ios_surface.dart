import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class IosBackdrop extends StatelessWidget {
  final Widget child;

  const IosBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.bg : AppColors.lightBg;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF08111F),
                      Color(0xFF0B1424),
                      Color(0xFF0A1020),
                    ]
                  : const [
                      Color(0xFFF8FBFD),
                      Color(0xFFF1F7F7),
                      Color(0xFFF5F4FA),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -180,
          right: -120,
          child: IgnorePointer(
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(isDark ? 0.16 : 0.12),
                    AppColors.accent.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -180,
          bottom: -220,
          child: IgnorePointer(
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent3.withOpacity(isDark ? 0.10 : 0.07),
                    AppColors.accent3.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
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

    final surfaceColor = isDark ? AppColors.bg2 : AppColors.lightSurface;
    final surface = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(isDark ? 0.82 : 0.88),
            borderRadius: borderRadius,
            border: Border.all(color: ink.withOpacity(isDark ? 0.14 : 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
