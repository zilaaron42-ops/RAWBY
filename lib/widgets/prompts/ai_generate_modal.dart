// ============================================================
// RAWBY — AI Generate Modal
// Provider/model picker lives in Settings — modal only collects
// per-week context (region, season, goal, content type).
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/router_provider.dart';
import '../../providers/user_session_provider.dart';
import '../../services/prompt_service.dart';
import '../common/glass_card.dart';

class AiGenerateModal extends ConsumerStatefulWidget {
  const AiGenerateModal({super.key});

  @override
  ConsumerState<AiGenerateModal> createState() => _AiGenerateModalState();
}

class _AiGenerateModalState extends ConsumerState<AiGenerateModal> {
  bool _isGenerating = false;
  String? _error;

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
    _seasonalPrompts = prefs.seasonalPrompts;
    _region = prefs.region.isNotEmpty ? prefs.region : _regions[1];
    _filmmakingGoal =
        prefs.filmmakingGoal.isNotEmpty ? prefs.filmmakingGoal : _goals[0];
    _contentType =
        prefs.contentType.isNotEmpty ? prefs.contentType : _contentTypes[0];
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

    ref.read(userSessionProvider.notifier).updatePreferences(
          session.preferences.copyWith(
            region: _region,
            seasonalPrompts: _seasonalPrompts,
            filmmakingGoal: _filmmakingGoal,
            contentType: _contentType,
          ),
        );

    try {
      final service = ref.read(promptServiceProvider);
      final ai = session.aiSettings;
      final prompts = await service.generateAiPrompts(
        provider: ai.provider,
        model: ai.model,
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
      return 'API key missing on the server. Check backend env vars.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return 'No connection. Using local prompts instead.';
    }
    return 'Generation failed. Try again or use local prompts.';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final regensLeft = session.regensLeft;
    final ai = session.aiSettings;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Generate prompts',
                                style: theme.textTheme.titleLarge),
                            Text(
                              '$regensLeft regen${regensLeft == 1 ? '' : 's'} left · ${_modelLabel(ai.provider, ai.model)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: regensLeft <= 1
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _LabelRow(
                    label: 'Region',
                    icon: Icons.public_outlined,
                  ),
                  const SizedBox(height: 6),
                  _Dropdown(
                    value: _region,
                    items: _regions,
                    onChanged: (v) => setState(() => _region = v!),
                  ),
                  const SizedBox(height: 14),

                  _LabelRow(
                    label: 'Filmmaking goal',
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 6),
                  _Dropdown(
                    value: _filmmakingGoal,
                    items: _goals,
                    onChanged: (v) => setState(() => _filmmakingGoal = v!),
                  ),
                  const SizedBox(height: 14),

                  _LabelRow(
                    label: 'Content style',
                    icon: Icons.movie_filter_outlined,
                  ),
                  const SizedBox(height: 6),
                  _Dropdown(
                    value: _contentType,
                    items: _contentTypes,
                    onChanged: (v) => setState(() => _contentType = v!),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seasonal mode',
                                  style: theme.textTheme.bodyMedium),
                              Text(
                                'Tailor 1 of 3 prompts to current season',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _seasonalPrompts,
                          onChanged: (v) =>
                              setState(() => _seasonalPrompts = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      context.push(Routes.settings);
                    },
                    icon: const Icon(Icons.tune, size: 16),
                    label: Text(
                      'Change AI model in Settings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.error, size: 16),
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
                  ],
                  const SizedBox(height: 16),

                  GradientButton(
                    icon: Icons.auto_awesome,
                    label: _isGenerating
                        ? 'Generating...'
                        : 'Generate 3 prompts',
                    loading: _isGenerating,
                    onTap: regensLeft <= 0 ? null : _generate,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _isGenerating
                          ? null
                          : () {
                              final service = ref.read(promptServiceProvider);
                              final prompts = service.generateLocalPrompts();
                              ref
                                  .read(userSessionProvider.notifier)
                                  .setPrompts(prompts);
                              ref
                                  .read(userSessionProvider.notifier)
                                  .setAutoGenPending(false);
                              Navigator.of(context).pop(false);
                            },
                      child: Text(
                        'Use local prompts instead',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }

  String _modelLabel(String provider, String model) {
    if (provider == 'openai') return 'OpenAI · $model';
    return 'Groq · $model';
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final IconData icon;

  const _LabelRow({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          style: theme.textTheme.bodyMedium,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
