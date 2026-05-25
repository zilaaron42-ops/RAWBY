// ============================================================
// RAWBY — Shared design primitives
// Glass card, level gradients, bento tile, stat tile, film tag.
// ============================================================
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Frosted glass card with optional gradient border and tap callback.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final List<Color>? gradient;
  final Color? tint;
  final double blur;
  final double borderOpacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.onTap,
    this.gradient,
    this.tint,
    this.blur = 10,
    this.borderOpacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseTint = tint ??
        (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.55));

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? baseTint : null,
            borderRadius: BorderRadius.circular(radius),
            gradient: gradient == null
                ? null
                : LinearGradient(
                    colors: gradient!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: borderOpacity),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// Level → gradient palette.
class LevelGradient {
  LevelGradient._();

  static List<Color> forLevel(String level) {
    switch (level) {
      case 'Story + Character':
        return const [Color(0xFFE85D75), Color(0xFFB12B5C)];
      case 'Short Story':
        return const [Color(0xFFE8B647), Color(0xFFC97E2C)];
      case 'Sequence':
      default:
        return const [Color(0xFF6FA373), Color(0xFF3D6B41)];
    }
  }

  static IconData icon(String level) {
    switch (level) {
      case 'Story + Character':
        return Icons.theater_comedy_outlined;
      case 'Short Story':
        return Icons.movie_outlined;
      case 'Sequence':
      default:
        return Icons.filter_frames_outlined;
    }
  }
}

/// Pill chip used for level / category / tag.
class FilmTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final List<Color>? gradient;
  final Color? color;
  final bool filled;
  final double fontSize;

  const FilmTag({
    super.key,
    required this.label,
    this.icon,
    this.gradient,
    this.color,
    this.filled = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    final bg = filled
        ? null
        : (theme.brightness == Brightness.dark
            ? RawbyPalette.darkCard
            : RawbyPalette.lightCard);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: bg,
        gradient: filled
            ? LinearGradient(
                colors: gradient ?? [c, c.withValues(alpha: 0.7)],
              )
            : null,
        border: filled
            ? null
            : Border.all(color: c.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: filled ? Colors.white : c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: filled ? Colors.white : c,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact stat tile: icon + value + label.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      radius: 14,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Big gradient CTA used for primary actions.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color>? gradient;
  final double height;
  final bool loading;
  final bool dense;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.gradient,
    this.height = 52,
    this.loading = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = gradient ??
        [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.7),
        ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: dense ? 42 : height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: dense ? 13 : 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(0, 24, 0, 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Decorative background — soft radial blobs in accent colors.
class AuraBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final bool topOnly;

  const AuraBackground({
    super.key,
    required this.child,
    this.colors,
    this.topOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = colors ??
        [
          theme.colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.14),
          theme.colorScheme.secondary.withValues(alpha: isDark ? 0.16 : 0.10),
        ];
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: theme.colorScheme.surface),
        Positioned(
          left: -120,
          top: -120,
          child: _blob(c[0], 320),
        ),
        if (!topOnly)
          Positioned(
            right: -100,
            bottom: -120,
            child: _blob(c[1], 280),
          ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: Container(color: Colors.transparent),
          ),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      );
}
