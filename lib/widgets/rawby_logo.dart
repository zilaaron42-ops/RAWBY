import 'package:flutter/material.dart';

class RawbyLogo extends StatelessWidget {
  final double size;
  const RawbyLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final keySize = size * 0.68;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.14,
        vertical: size * 0.13,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: 'RAWBY'.split('').map((letter) => _TypewriterKey(
          letter: letter,
          size: keySize,
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
      margin: EdgeInsets.symmetric(horizontal: size * 0.05),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: Offset(0, size * 0.08),
            blurRadius: size * 0.12,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
