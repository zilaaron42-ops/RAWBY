// ============================================================
// RAWBY — Custom Prompt Modal
// User writes their own prompt text and picks a level
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';
import '../../services/prompt_service.dart';
import '../../theme/app_colors.dart';

class CustomPromptModal extends ConsumerStatefulWidget {
  const CustomPromptModal({super.key});

  @override
  ConsumerState<CustomPromptModal> createState() => _CustomPromptModalState();
}

class _CustomPromptModalState extends ConsumerState<CustomPromptModal> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _level = 'Short Story';

  static const _levels = [
    _LevelOption(
      level: 'Sequence',
      points: 10,
      icon: '🎞️',
      description: 'Purely visual, no talking, music/sound only.',
    ),
    _LevelOption(
      level: 'Short Story',
      points: 30,
      icon: '🎬',
      description: 'Solo on screen, self-filmed, story arc, no dialogue.',
    ),
    _LevelOption(
      level: 'Story + Character',
      points: 50,
      icon: '🎭',
      description: 'You + 1–2 people, 1 spoken line max per scene.',
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(promptServiceProvider);
    final prompt = service.buildCustomPrompt(
      text: _textController.text.trim(),
      level: _level,
    );

    // Replace current prompts with just this custom one
    ref.read(userSessionProvider.notifier).setPrompts([prompt]);
    ref.read(userSessionProvider.notifier).setAutoGenPending(false);

    Navigator.of(context).pop(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RawbyPalette.darkSurface : RawbyPalette.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Custom Prompt',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(null),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Prompt text field
                Text('Your Prompt', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  maxLength: 500,
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Describe your filmmaking idea...\ne.g. "Film a morning routine but make it feel like a film trailer."',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF8A8A7A)
                          : const Color(0xFF9A9A8A),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? RawbyPalette.darkCard
                        : RawbyPalette.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: theme.textTheme.bodySmall,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Write your prompt first';
                    }
                    if (v.trim().length < 10) {
                      return 'Prompt is too short (min 10 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Level selector
                Text('Difficulty Level', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ..._levels.map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _level = opt.level),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _level == opt.level
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _level == opt.level
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: _level == opt.level ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(opt.icon,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt.level,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        color: _level == opt.level
                                            ? theme.colorScheme.primary
                                            : null,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      opt.description,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _level == opt.level
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.15)
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${opt.points} pts',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _level == opt.level
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Use This Prompt',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

class _LevelOption {
  final String level;
  final int points;
  final String icon;
  final String description;

  const _LevelOption({
    required this.level,
    required this.points,
    required this.icon,
    required this.description,
  });
}
