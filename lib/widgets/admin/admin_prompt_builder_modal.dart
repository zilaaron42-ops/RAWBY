// ============================================================
// RAWBY — Admin Prompt Builder
// Create · preview · save prompts for distribution
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class AdminPromptBuilderModal extends ConsumerStatefulWidget {
  const AdminPromptBuilderModal({super.key});

  @override
  ConsumerState<AdminPromptBuilderModal> createState() =>
      _AdminPromptBuilderModalState();
}

class _AdminPromptBuilderModalState
    extends ConsumerState<AdminPromptBuilderModal> {
  final _textCtrl = TextEditingController();
  final _inspirationCtrl = TextEditingController();
  String _level = 'Sequence';
  String _difficulty = 'medium';
  bool _saving = false;
  String? _saveError;
  bool _saved = false;

  static const _levels = ['Sequence', 'Short Story', 'Story + Character'];
  static const _difficulties = ['easy', 'medium', 'hard', 'expert'];

  int get _points {
    switch (_difficulty) {
      case 'easy': return 25;
      case 'medium': return 50;
      case 'hard': return 100;
      case 'expert': return 150;
      default: return 50;
    }
  }

  Color _levelColor(ThemeData theme) {
    switch (_level) {
      case 'Short Story': return theme.colorScheme.secondary;
      case 'Story + Character': return RawbyPalette.basic500;
      default: return theme.colorScheme.primary;
    }
  }

  List<Color> _levelGradient(ThemeData theme) {
    switch (_level) {
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

  String _levelIcon() {
    switch (_level) {
      case 'Short Story': return '🎬';
      case 'Story + Character': return '🎭';
      default: return '🎞️';
    }
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _saveError = 'Enter prompt text first.');
      return;
    }
    setState(() { _saving = true; _saveError = null; });
    HapticFeedback.mediumImpact();

    try {
      final api = ref.read(apiServiceProvider);
      await api.saveAdminPrompt({
        'text': text,
        'level': _level,
        'difficulty': _difficulty,
        'points': _points,
        'inspiration': _inspirationCtrl.text.trim(),
        'source': 'admin',
      });
      if (mounted) {
        setState(() { _saving = false; _saved = true; });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'Save failed: ${e.toString().split(':').last.trim()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _inspirationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final levelColor = _levelColor(theme);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_note_rounded,
                        size: 18, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prompt Builder', style: theme.textTheme.titleLarge),
                        Text('Create a challenge for your community',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

            const Divider(height: 24),

            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // ── Level selector ────────────────────────────
                  Text('Difficulty Level',
                      style: theme.textTheme.titleSmall).animate(delay: 50.ms).fadeIn(),
                  const SizedBox(height: 10),
                  Row(
                    children: _levels.map((level) {
                      final selected = _level == level;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: level != _levels.last ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _level = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? levelColor.withValues(alpha: 0.12)
                                    : (isDark
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFFF5F5F5)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? levelColor
                                      : (isDark
                                          ? const Color(0xFF2A2A2A)
                                          : RawbyPalette.lightBorder),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                level,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? levelColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate(delay: 80.ms).fadeIn(),
                  const SizedBox(height: 20),

                  // ── Points/Difficulty ─────────────────────────
                  Text('Points Value',
                      style: theme.textTheme.titleSmall).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 10),
                  Row(
                    children: _difficulties.map((diff) {
                      final selected = _difficulty == diff;
                      final pts = switch (diff) {
                        'easy' => 25,
                        'medium' => 50,
                        'hard' => 100,
                        _ => 150,
                      };
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: diff != _difficulties.last ? 6 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _difficulty = diff),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                    : (isDark
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFFF5F5F5)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : (isDark
                                          ? const Color(0xFF2A2A2A)
                                          : RawbyPalette.lightBorder),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    diff[0].toUpperCase() + diff.substring(1),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '$pts',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate(delay: 120.ms).fadeIn(),
                  const SizedBox(height: 20),

                  // ── Prompt Text ───────────────────────────────
                  Text('Challenge Brief',
                      style: theme.textTheme.titleSmall).animate(delay: 140.ms).fadeIn(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 5,
                    minLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText:
                          'Write a compelling challenge brief...\n\nTip: Start with a constraint, add a location, add a visual rule.',
                      counterStyle: theme.textTheme.labelSmall,
                    ),
                    onChanged: (_) => setState(() {}),
                  ).animate(delay: 160.ms).fadeIn(),
                  const SizedBox(height: 16),

                  // ── Inspiration ───────────────────────────────
                  Text('Inspiration Credit (optional)',
                      style: theme.textTheme.titleSmall).animate(delay: 180.ms).fadeIn(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inspirationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Wong Kar-wai, Chivo, Agnès Varda...',
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 24),

                  // ── Preview ───────────────────────────────────
                  if (_textCtrl.text.isNotEmpty) ...[
                    Text('Preview',
                        style: theme.textTheme.titleSmall).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 10),
                    _PromptPreview(
                      text: _textCtrl.text,
                      level: _level,
                      points: _points,
                      inspiration: _inspirationCtrl.text,
                      levelColor: levelColor,
                      levelGradient: _levelGradient(theme),
                      levelIcon: _levelIcon(),
                      theme: theme,
                      isDark: isDark,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],

                  // ── Error ─────────────────────────────────────
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _saveError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // ── Save Button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: _saved
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: RawbyPalette.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: RawbyPalette.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: RawbyPalette.success, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Saved to Draft Prompts',
                                  style: TextStyle(
                                    color: RawbyPalette.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: _saving ? null : _save,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _levelGradient(theme),
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: levelColor.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _saving
                                  ? Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_rounded,
                                            color: Colors.white, size: 18),
                                        SizedBox(width: 10),
                                        Text(
                                          'Save to Draft Prompts',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                  ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prompt Preview ───────────────────────────────────────────

class _PromptPreview extends StatelessWidget {
  final String text;
  final String level;
  final int points;
  final String inspiration;
  final Color levelColor;
  final List<Color> levelGradient;
  final String levelIcon;
  final ThemeData theme;
  final bool isDark;

  const _PromptPreview({
    required this.text,
    required this.level,
    required this.points,
    required this.inspiration,
    required this.levelColor,
    required this.levelGradient,
    required this.levelIcon,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : RawbyPalette.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: levelGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Text(levelIcon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${level.toUpperCase()}  ·  $points pts',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  if (inspiration.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Inspired by $inspiration',
                      style: theme.textTheme.bodySmall?.copyWith(color: levelColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
