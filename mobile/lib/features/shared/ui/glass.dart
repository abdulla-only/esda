import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Frosted-glass surface: translucent fill + backdrop blur + hairline border,
/// with an optional soft brand [glow]. The reusable building block for cards,
/// tiles, panels and dialog bodies across the app.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.glow,
    this.onTap,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? glow;
  final VoidCallback? onTap;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final t = AuroraTokens.of(context);
    final radius = BorderRadius.circular(borderRadius);
    Widget surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: t.glassFill,
            borderRadius: radius,
            border: Border.all(color: t.glassBorder),
          ),
          child: child,
        ),
      ),
    );
    if (glow != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: glow!.withValues(alpha: 0.28),
              blurRadius: 40,
              spreadRadius: -6,
            ),
          ],
        ),
        child: surface,
      );
    }
    if (onTap != null) {
      surface = InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: surface,
      );
    }
    return surface;
  }
}

/// A [GlassContainer] preset with card padding, for list tiles and panels.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.glow,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? glow;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      glow: glow,
      onTap: onTap,
      child: child,
    );
  }
}
