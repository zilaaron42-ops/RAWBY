import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// RAWBY wordmark — bold "RAWBY" set in a pine / moss-green squircle.
/// Minimalist, brand-fixed (always pine green, independent of accent theme).
class RawbyLogo extends StatelessWidget {
  final double size;

  /// When true, shows just the green block + mark (default). Set [wordmark]
  /// to render the block beside a larger "RAWBY" lockup if needed later.
  const RawbyLogo({super.key, this.size = 48});

  // Pine / moss green — fixed brand colours, not theme-driven.
  static const Color _pine = RawbyPalette.green600; // #3D6B41
  static const Color _moss = RawbyPalette.green700; // #2A4D2D

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _SquircleClipper(radius: size * 0.30),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_pine, _moss],
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'RAWBY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: size * 0.01,
                height: 1,
                fontSize: size * 0.30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquircleClipper extends CustomClipper<Path> {
  final double radius;
  const _SquircleClipper({required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = radius;
    final c = r * 0.552;

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.cubicTo(w - r + c, 0, w, r - c, w, r);
    path.lineTo(w, h - r);
    path.cubicTo(w, h - r + c, w - r + c, h, w - r, h);
    path.lineTo(r, h);
    path.cubicTo(r - c, h, 0, h - r + c, 0, h - r);
    path.lineTo(0, r);
    path.cubicTo(0, r - c, r - c, 0, r, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_SquircleClipper old) => old.radius != radius;
}
