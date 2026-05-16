// ============================================================
// RAWBY — AI Generate Modal
// Triggers Groq/OpenAI prompt generation via Render backend
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';
import '../../services/prompt_service.dart';
import '../../services/season_service.dart';
import '../../theme/app_colors.dart';

class AiGenerateModal extends ConsumerStatefulWidget {
  const AiGenerateModal({super.key});

  @override
  ConsumerState<AiGenerateModal> createState() => _AiGenerateModalState();
}

class _AiGenerateModalState extends ConsumerState<AiGenerateModal> {
  bool _isGenerating = false;
  String? _error;

  // Form state — mirrors UserPreferences
  late String _provider;
  late String _model;
  late bool _seasonalPrompts;
  late String _region;
  late String _filmmakingGoal;
  late String _contentType;

  static const _regions = [
    'Northern Europe',
    'Central Europe',
    'Southern Europe',
    'US Northeast',
    'US South',
    'US West',
    'East Asia',
    'Southeast Asia',
    'Australia',
    'Other',
  ];

  static const _goals = [
    'Grow my audience',
    'Improve my craft',
    'Tell personal stories',
    'Experiment with style',
    'Build a portfolio',
    'Just have fun',
  ];

  static const _contentTypes = [
    'Cinematic reels',
    'Documentary style',
    'Narrative short',
    'Aesthetic / mood',
    'Travel & lifestyle',
    'Street & urban',
  ];

  @override
  void initState() {
    super.initState();
    final session = ref.read(userSessionProvider);
    final prefs = session.preferences;
    final ai = session.aiSettings;
    _provider = ai.provider;
    _model = ai.model;
    _seasonalPrompts = prefs.seasonalPrompts;
    _region = prefs.region.isNotEmpty ? prefs.region : _regions[1];
    _filmmakingGoal = prefs.filmmakingGoal.isNotEmpty ? prefs.filmmakingGoal : _goals[0];
    _contentType = prefs.contentType.isNotEmpty ? prefs.contentType : _contentTypes[0];
  }

  Future<void> _generate() async {
    final session = ref.read(userSessionProvider);
    if (session.regensLeft <= 0) {
      setState(() => _error = 'No regenerations left this week.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    // Save preferences back
    ref.read(userSessionProvider.notifier).updatePreferences(
          session.preferences.copyWith(
            region: _region,
            seasonalPrompts: _seasonalPrompts,
            filmmakingGoal: _filmmakingGoal,
            contentType: _contentType,
          ),
        );
    ref.read(userSessionProvider.notifier).updateAiSettings(
          session.aiSettings.copyWith(
            provider: _provider,
            model: _model,
          ),
        );

    try {
      final service = ref.read(promptServiceProvider);
      final prompts = await service.generateAiPrompts(
        provider: _provider,
        model: _model,
        seasonalPrompts: _seasonalPrompts,
        region: _region,
        filmmakingGoal: _filmmakingGoal,
        contentType: _contentType,
      );

      ref.read(userSessionProvider.notifier).setPrompts(prompts);
      ref.read(userSessionProvider.notifier).incrementRegenCount();
      ref.read(userSessionProvider.notifier).setAutoGenPending(false);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = _parseError(e);
        _isGenerating = false;
      });
    }
  }

  String _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('429') || msg.contains('rate')) {
      return 'AI rate limit hit. Try again in a moment.';
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'API key issue. Check your backend config.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'No connection. Using local prompts instead.';
    }
    return 'Generation failed. Try again or use local prompts.';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final regensLeft = session.regensLeft;

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
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate with AI',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '$regensLeft regen${regensLeft == 1 ? '' : 's'} left this week',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: regensLeft <= 1
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Provider toggle
              Text('AI Provider', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ProviderChip(
                    label: 'Groq (Llama 3)',
                    selected: _provider == 'groq',
                    onTap: () => setState(() {
                      _provider = 'groq';
                      _model = 'llama-3.3-70b-versatile';
                    }),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _ProviderChip(
                    label: 'OpenAI (GPT-4o)',
                    selected: _provider == 'openai',
                    onTap: () => setState(() {
                      _provider = 'openai';
                      _model = 'gpt-4o';
                    }),
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Region
              Text('Your Region', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _DropdownField(
                value: _region,
                items: _regions,
                onChanged: (v) => setState(() => _region = v!),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Filmmaking Goal
              Text('Filmmaking Goal', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _DropdownField(
                value: _filmmakingGoal,
                items: _goals,
                onChanged: (v) => setState(() => _filmmakingGoal = v!),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Content Type
              Text('Content Type', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _DropdownField(
                value: _contentType,
                items: _contentTypes,
                onChanged: (v) => setState(() => _contentType = v!),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Seasonal toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seasonal Mode', style: theme.textTheme.bodyMedium),
                              Text(
                                'Tailor prompts to current season & weather',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _seasonalPrompts,
                          onChanged: (v) => setState(() => _seasonalPrompts = v),
                        ),
                      ],
                    ),
                    if (_seasonalPrompts) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          SeasonService.getSeasonHint(_region, _seasonalPrompts),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isGenerating || regensLeft <= 0) ? null : _generate,
                  icon: _isGenerating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate 3 Prompts',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Use local fallback
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isGenerating
                      ? null
                      : () {
                          final service = ref.read(promptServiceProvider);
                          final prompts = service.generateLocalPrompts();
                          ref.read(userSessionProvider.notifier).setPrompts(prompts);
                          ref.read(userSessionProvider.notifier).setAutoGenPending(false);
                          Navigator.of(context).pop(false);
                        },
                  child: Text(
                    'Use local prompts instead',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────

class _ProviderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ProviderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final ThemeData theme;
  final bool isDark;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? RawbyPalette.inputCreamDark : RawbyPalette.inputCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor:
              isDark ? RawbyPalette.darkCard : RawbyPalette.lightSurface,
          style: TextStyle(
            color: const Color(0xFF2A2A1A),
            fontSize: 14,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF8A8A7A),
            size: 18,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isDark
                            ? RawbyPalette.textDark
                            : const Color(0xFF2A2A1A),
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
