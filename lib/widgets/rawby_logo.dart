import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RawbyLogo extends StatelessWidget {
  final double size;
  const RawbyLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2.5,
      height: size,
      decoration: BoxDecoration(
        color: RawbyPalette.green700,
        borderRadius: BorderRadius.circular(size * 0.15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: 'RAWBY'.split('').map((letter) => _TypewriterKey(
          letter: letter,
          size: size * 0.7,
        )).toList(),
      ),
    );
  }
}

class _TypewriterKey extends StatelessWidget {
  final String letter;
  final double size;
  const _TypewriterKey({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size * 0.04),
      width: size * 0.62,
      height: size * 0.62,
      decoration: BoxDecoration(
        color: RawbyPalette.green600,
        borderRadius: BorderRadius.circular(size * 0.1),
        border: Border.all(color: RawbyPalette.green500.withOpacity(0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: Offset(0, size * 0.05),
            blurRadius: size * 0.08,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: const Color(0xFFE8F5E9),
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ),
    );
  }
}
