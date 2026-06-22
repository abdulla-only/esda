import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Deep base colour lit by three soft, heavily-blurred "aurora" glows, with
/// [child] composited on top. Wired once via [MaterialApp.builder] so every
/// screen (transparent scaffolds) reads through to it.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AuroraTokens.of(context);
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: t.bg)),
        // Blur the whole glow layer once so the radial gradients read as light.
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Stack(
              children: [
                _glow(alignment: const Alignment(-1.1, -1.2), color: t.auroraA),
                _glow(alignment: const Alignment(1.3, -1.0), color: t.auroraB),
                _glow(alignment: const Alignment(0.0, 1.3), color: t.auroraC),
              ],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _glow({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 460,
        height: 460,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
