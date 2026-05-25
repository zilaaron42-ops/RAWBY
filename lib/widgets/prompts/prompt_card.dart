// ============================================================
// RAWBY — Prompt Card
// Cinematic prompt card with gradient hero header per level,
// expandable storyboard (numbered shots), tiered song stack,
// metadata chips, license-free keywords, save + choose actions.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/prompt_model.dart';
import '../../providers/user_session_provider.dart';
import '../../theme/app_colors.dart';
import '../common/glass_card.dart';

class PromptCard extends ConsumerStatefulWidget {
  final PromptModel prompt;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onChoose;
  final int index;

  const PromptCard({
    super.key,
    required this.prompt,
    this.isSelected = false,
    this.isLocked = false,
    this.onChoose,
    this.index = 0,
  });

  @override
  ConsumerState<PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends ConsumerState<PromptCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(userSessionProvider);
    final isSaved = session.savedPrompts.any((p) => p.id == widget.prompt.id);
    final p = widget.prompt;

    final gradient = LevelGradient.forLevel(p.level);
    final icon = LevelGradient.icon(p.level);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isSelected
              ? gradient.first
              : (isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder),
          width: widget.isSelected ? 1.6 : 1,
        ),
        color: isDark ? RawbyPalette.darkCard : Colors.white,
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient hero header ──────────────────────────────
          Container(
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    icon,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LevelChip(level: p.level, points: p.points),
                          const Spacer(),
                          if (p.source == 'ai')
                            _SourceChip(label: 'AI', color: Colors.white),
                          if (p.source == 'custom')
                            _SourceChip(
                                label: 'CUSTOM', color: Colors.white),
                          const SizedBox(width: 6),
                          _SaveStar(
                            saved: isSaved,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (isSaved) {
                                ref
                                    .read(userSessionProvider.notifier)
                                    .removeSavedPrompt(p.id);
                              } else {
                                ref
                                    .read(userSessionProvider.notifier)
                                    .savePrompt(p);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Saved to Idea Bank'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (p.category.isNotEmpty)
                        Text(
                          p.category.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (p.emotion.isNotEmpty)
                      _MetaPill(icon: Icons.psychology_outlined, label: p.emotion),
                    if (p.inspiration.isNotEmpty)
                      InkWell(
                        onTap: p.inspirationProfileUrl.isEmpty
                            ? null
                            : () => _launch(p.inspirationProfileUrl),
                        borderRadius: BorderRadius.circular(40),
                        child: _MetaPill(
                          icon: Icons.alternate_email,
                          label: p.inspiration,
                          accent: true,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Expand toggle ─────────────────────────────────────
          if (p.shots.isNotEmpty ||
              p.songs.isNotEmpty ||
              p.outcome.isNotEmpty ||
              p.licenseFreeKeywords.isNotEmpty)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Hide storyboard' : 'Show storyboard & music',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: _expanded ? _Expanded(p: p) : const SizedBox.shrink(),
          ),

          // ── Footer action ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: widget.isLocked
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'This week\'s prompt',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  )
                : GradientButton(
                    label: widget.isSelected ? 'Chosen' : 'Choose this prompt',
                    icon: widget.isSelected
                        ? Icons.check_circle
                        : Icons.movie_creation_outlined,
                    gradient: gradient,
                    onTap: widget.isSelected ? null : widget.onChoose,
                  ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ── Sub-components ─────────────────────────────────────────────

class _LevelChip extends StatelessWidget {
  final String level;
  final int points;

  const _LevelChip({required this.level, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LevelGradient.icon(level), color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            '$level · $points pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SourceChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SaveStar extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;

  const _SaveStar({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: saved ? Colors.white : Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Icon(
          saved ? Icons.bookmark : Icons.bookmark_border,
          size: 16,
          color: saved ? const Color(0xFFC97E2C) : Colors.white,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: accent
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Expanded extends StatelessWidget {
  final PromptModel p;

  const _Expanded({required this.p});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.outcome.isNotEmpty || p.purpose.isNotEmpty) ...[
            _Detail(
              icon: Icons.flag_outlined,
              title: 'Outcome',
              body: p.outcome,
            ),
            if (p.purpose.isNotEmpty)
              _Detail(
                icon: Icons.menu_book_outlined,
                title: 'Purpose',
                body: p.purpose,
              ),
            const SizedBox(height: 8),
          ],
          if (p.shots.isNotEmpty) ...[
            Text(
              'STORYBOARD',
              style: theme.textTheme.labelMedium
                  ?.copyWith(letterSpacing: 1.4),
            ),
            const SizedBox(height: 8),
            ...List.generate(p.shots.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShotRow(index: i + 1, text: p.shots[i]),
              );
            }),
            const SizedBox(height: 6),
          ],
          if (p.songs.isNotEmpty) ...[
            Text(
              'MUSIC',
              style: theme.textTheme.labelMedium
                  ?.copyWith(letterSpacing: 1.4),
            ),
            const SizedBox(height: 8),
            ...p.songs.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SongTile(song: s),
                )),
          ],
          if (p.licenseFreeKeywords.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'ROYALTY-FREE SEARCH',
              style: theme.textTheme.labelMedium
                  ?.copyWith(letterSpacing: 1.4),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.licenseFreeKeywords
                  .map((k) => FilmTag(
                        label: k,
                        filled: false,
                        color: theme.colorScheme.onSurfaceVariant,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Detail({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShotRow extends StatelessWidget {
  final int index;
  final String text;

  const _ShotRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongSuggestion song;

  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierStyle = _tierStyle(song.type);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tierStyle.gradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(tierStyle.icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tierStyle.gradient),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  tierStyle.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          if (song.whyItWorks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              song.whyItWorks,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _TierStyle _tierStyle(String type) {
    switch (type) {
      case 'trending':
        return _TierStyle(
          label: 'TRENDING',
          icon: Icons.trending_up,
          gradient: const [Color(0xFFE85D75), Color(0xFFB12B5C)],
        );
      case 'classic_fit':
        return _TierStyle(
          label: 'CLASSIC',
          icon: Icons.access_time,
          gradient: const [Color(0xFF7C4DFF), Color(0xFF512DA8)],
        );
      case 'best_match':
      default:
        return _TierStyle(
          label: 'BEST FIT',
          icon: Icons.star,
          gradient: const [Color(0xFFE8B647), Color(0xFFC97E2C)],
        );
    }
  }
}

class _TierStyle {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  _TierStyle({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}
