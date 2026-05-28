import 'package:flutter/material.dart';

class RawbyLogo extends StatelessWidget {
  final double size;
  const RawbyLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ClipPath(
      clipper: _SquircleClipper(radius: size * 0.28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: primary,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              Color.lerp(primary, Colors.black, 0.25)!,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['R', 'A', 'W'].map((l) => _Key(letter: l, size: size * 0.26)).toList(),
              ),
              SizedBox(height: size * 0.04),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['B', 'Y'].map((l) => _Key(letter: l, size: size * 0.26)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String letter;
  final double size;
  const _Key({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(size * 0.06),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: Offset(0, size * 0.08),
            blurRadius: size * 0.14,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            height: 1,
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
