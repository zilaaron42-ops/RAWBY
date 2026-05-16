// ============================================================
// RAWBY — Prompt Card  |  Creator's Brief
// Dramatic presentation · flutter_animate · level gradients
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/prompt_model.dart';
import '../../providers/user_session_provider.dart';
import '../../theme/app_colors.dart';

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

class _PromptCardState extends ConsumerState<PromptCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(userSessionProvider);
    final isSaved = session.savedPrompts.any((p) => p.id == widget.prompt.id);
    final p = widget.prompt;

    final levelColor = _levelColor(p.level, theme);
    final levelIcon = _levelIcon(p.level);
    final levelGradient = _levelGradient(p.level, theme);

    final hasDetails = p.shots.isNotEmpty || p.songs.isNotEmpty || p.outcome.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isSelected
              ? levelColor
              : (isDark ? const Color(0xFF1E1E1E) : RawbyPalette.lightBorder),
          width: widget.isSelected ? 1.5 : 1,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: levelColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Level Header Band ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: levelGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Text(levelIcon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.level.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          '${p.points} points',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Source badge
                  if (p.source == 'ai')
                    _SourceBadge(label: 'AI', color: Colors.white.withValues(alpha: 0.25)),
                  if (p.source == 'custom')
                    _SourceBadge(label: 'CUSTOM', color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 8),
                  // Star button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isSaved) {
                        ref.read(userSessionProvider.notifier).removeSavedPrompt(p.id);
                      } else {
                        ref.read(userSessionProvider.notifier).savePrompt(p);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to Idea Bank')),
                        );
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        key: ValueKey(isSaved),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Prompt Text ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Text(
                p.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFEEEEEE) : RawbyPalette.textLight,
                ),
              ),
            ),

            // ── Inspiration ────────────────────────────────────
            if (p.inspiration.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: levelColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Inspired by ${p.inspiration}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: levelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Meta chips (outcome/purpose/emotion) ───────────
            if (p.outcome.isNotEmpty || p.purpose.isNotEmpty || p.emotion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (p.outcome.isNotEmpty)
                      _MetaTag(label: '🎯 ${p.outcome}', isDark: isDark),
                    if (p.purpose.isNotEmpty)
                      _MetaTag(label: '💡 ${p.purpose}', isDark: isDark),
                    if (p.emotion.isNotEmpty)
                      _MetaTag(label: '🎭 ${p.emotion}', isDark: isDark),
                  ],
                ),
              ),

            // ── Expand toggle ──────────────────────────────────
            if (hasDetails)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: _toggleExpanded,
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Hide details' : 'Shot list & music',
                        style: TextStyle(
                          color: levelColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: levelColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Expandable Details ─────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shots
                    if (p.shots.isNotEmpty) ...[
                      _SectionLabel(label: 'Shot List', icon: Icons.videocam_outlined),
                      const SizedBox(height: 8),
                      ...p.shots.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: levelColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${e.key + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: levelColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],

                    // Songs
                    if (p.songs.isNotEmpty) ...[
                      _SectionLabel(label: 'Music Suggestions', icon: Icons.music_note_rounded),
                      const SizedBox(height: 8),
                      ...p.songs.map((song) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : RawbyPalette.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.music_note_rounded,
                                      size: 14,
                                      color: levelColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${song.title} — ${song.artist}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: levelColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        song.type,
                                        style: TextStyle(
                                          color: levelColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (song.whyItWorks.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    song.whyItWorks,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                    ],

                    // License-free keywords
                    if (p.licenseFreeKeywords.isNotEmpty) ...[
                      _SectionLabel(
                          label: 'Royalty-free search terms',
                          icon: Icons.search_rounded),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.licenseFreeKeywords
                            .map((kw) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(kw, style: theme.textTheme.labelSmall),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),

            // ── Choose Button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: widget.isLocked
                  ? _LockedButton(
                      isSelected: widget.isSelected,
                      levelColor: levelColor,
                      theme: theme,
                    )
                  : _ChooseButton(
                      isSelected: widget.isSelected,
                      levelColor: levelColor,
                      levelGradient: levelGradient,
                      onTap: widget.isSelected ? null : () {
                        HapticFeedback.mediumImpact();
                        widget.onChoose?.call();
                      },
                    ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + widget.index * 100))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }

  Color _levelColor(String level, ThemeData theme) {
    switch (level) {
      case 'Short Story': return theme.colorScheme.secondary;
      case 'Story + Character': return RawbyPalette.basic500;
      default: return theme.colorScheme.primary;
    }
  }

  String _levelIcon(String level) {
    switch (level) {
      case 'Short Story': return '🎬';
      case 'Story + Character': return '🎭';
      default: return '🎞️';
    }
  }

  List<Color> _levelGradient(String level, ThemeData theme) {
    switch (level) {
      case 'Short Story':
        return [const Color(0xFF1A6B3A), const Color(0xFF0D4A28)];
      case 'Story + Character':
        return [const Color(0xFF7C4DFF), const Color(0xFF5E35B1)];
      default:
        return [
          theme.colorScheme.primary.withValues(alpha: 0.9),
          theme.colorScheme.primary.withValues(alpha: 0.6),
        ];
    }
  }
}

// ── Choose Button ────────────────────────────────────────────

class _ChooseButton extends StatelessWidget {
  final bool isSelected;
  final Color levelColor;
  final List<Color> levelGradient;
  final VoidCallback? onTap;

  const _ChooseButton({
    required this.isSelected,
    required this.levelColor,
    required this.levelGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: levelGradient.map((c) => c.withValues(alpha: 0.15)).toList(),
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: levelColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 16, color: levelColor),
            const SizedBox(width: 8),
            Text(
              'Chosen',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: levelColor,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: levelGradient),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: levelColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Start This Challenge',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Locked Button ────────────────────────────────────────────

class _LockedButton extends StatelessWidget {
  final bool isSelected;
  final Color levelColor;
  final ThemeData theme;

  const _LockedButton({
    required this.isSelected,
    required this.levelColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        isSelected ? '✓ This Week\'s Prompt' : 'Locked Until Next Cycle',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: levelColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Source Badge ─────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SourceBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ── Meta Tag ─────────────────────────────────────────────────

class _MetaTag extends StatelessWidget {
  final String label;
  final bool isDark;
  const _MetaTag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : RawbyPalette.lightBorder,
        ),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
