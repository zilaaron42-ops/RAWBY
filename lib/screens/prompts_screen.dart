// ============================================================
// RAWBY — Prompts Screen
// 3 weekly prompts + silent AI regen + custom + Idea Bank +
// Big Project + submit (with gear log) / record-stats CTAs.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/router_provider.dart';
import '../providers/user_session_provider.dart';
import '../services/prompt_service.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/prompts/custom_prompt_modal.dart';
import '../widgets/prompts/prompt_card.dart';
import '../widgets/projects/gear_log_modal.dart';
import '../widgets/projects/record_stats_modal.dart';
import '../widgets/projects/submit_modal.dart';
import '../widgets/projects/big_project_modal.dart';

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({super.key});

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  bool _regenLoading = false;

  Future<void> _silentRegen() async {
    final session = ref.read(userSessionProvider);
    if (!session.isPro) {
      context.push(Routes.paywall);
      return;
    }
    if (session.regensLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No regenerations left this week.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _regenLoading = true);
    try {
      final ai = session.aiSettings;
      final prefs = session.preferences;
      final service = ref.read(promptServiceProvider);
      final prompts = await service.generateAiPrompts(
        provider: 'groq',
        model: 'llama-3.3-70b-versatile',
        seasonalPrompts: prefs.seasonalPrompts,
        region: prefs.region.isNotEmpty ? prefs.region : 'Central Europe',
        filmmakingGoal: prefs.filmmakingGoal.isNotEmpty ? prefs.filmmakingGoal : 'Grow my audience',
        contentType: prefs.contentType.isNotEmpty ? prefs.contentType : 'Cinematic reels',
      );
      ref.read(userSessionProvider.notifier).setPrompts(prompts);
      ref.read(userSessionProvider.notifier).incrementRegenCount();
      ref.read(userSessionProvider.notifier).setAutoGenPending(false);
      if (mounted) {
        final remaining = ref.read(userSessionProvider).regensLeft;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated · $remaining regens left'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI failed — showing local prompts'), behavior: SnackBarBehavior.floating),
        );
        final service = ref.read(promptServiceProvider);
        final fallback = service.generateLocalPrompts();
        ref.read(userSessionProvider.notifier).setPrompts(fallback);
      }
    } finally {
      if (mounted) setState(() => _regenLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isLocked = session.isLocked;
    final regensLeft = session.regensLeft;

    return Scaffold(
      body: AuraBackground(
        topOnly: true,
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            if (!isLocked) {
              final service = ref.read(promptServiceProvider);
              final prompts = service.generateLocalPrompts();
              ref.read(userSessionProvider.notifier).setPrompts(prompts);
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prompts',
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isLocked
                                        ? 'Prompt locked — keep filming'
                                        : 'Pick one. Three try-out songs included.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            _RoundIcon(
                              icon: Icons.bookmark_border,
                              badge: session.savedPrompts.length,
                              onTap: () => context.push(Routes.ideaBank),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!isLocked)
                          _ActionRow(
                            regensLeft: regensLeft,
                            regenLoading: _regenLoading,
                            onAi: _silentRegen,
                            onCustom: () => _showCustomModal(context),
                            onShuffle: () {
                              final service = ref.read(promptServiceProvider);
                              final prompts = service.generateLocalPrompts();
                              ref.read(userSessionProvider.notifier).setPrompts(prompts);
                            },
                            onBigProject: () => _showBigProjectModal(context),
                          ),
                        if (isLocked)
                          _SubmitPanel(
                            session: session,
                            onSubmit: () => _showSubmitModal(context),
                            onRecord: () => _showRecordStatsModal(context),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              if (session.prompts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prompt = session.prompts[index];
                        final isSelected =
                            session.selectedPromptId == prompt.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: PromptCard(
                            prompt: prompt,
                            isSelected: isSelected,
                            isLocked: isLocked,
                            index: index,
                            onChoose: isLocked
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    ref
                                        .read(userSessionProvider.notifier)
                                        .selectPrompt(prompt.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${prompt.level} chosen · ${prompt.points} pts',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                          ),
                        );
                      },
                      childCount: session.prompts.length,
                    ),
                  ),
                ),

              if (session.prompts.isEmpty && !isLocked)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    onGenerate: () {
                      final service = ref.read(promptServiceProvider);
                      final prompts = service.generateLocalPrompts();
                      ref
                          .read(userSessionProvider.notifier)
                          .setPrompts(prompts);
                    },
                    onAi: _silentRegen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomPromptModal(),
    );
  }

  Future<void> _showBigProjectModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BigProjectModal(),
    );
  }

  Future<void> _showSubmitModal(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubmitModal(),
    );
    if (result == 'submitted' && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GearLogModal(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project submitted! Stats unlock in 7 days.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRecordStatsModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecordStatsModal(),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _RoundIcon({
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final int regensLeft;
  final bool regenLoading;
  final VoidCallback onAi;
  final VoidCallback onCustom;
  final VoidCallback onShuffle;
  final VoidCallback onBigProject;

  const _ActionRow({
    required this.regensLeft,
    required this.regenLoading,
    required this.onAi,
    required this.onCustom,
    required this.onShuffle,
    required this.onBigProject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Pill(
                icon: regenLoading ? Icons.hourglass_top : Icons.auto_awesome,
                label: regenLoading ? 'Generating...' : 'AI Regen',
                sub: '$regensLeft left',
                primary: true,
                onTap: (regensLeft > 0 && !regenLoading) ? onAi : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Pill(
                icon: Icons.edit_outlined,
                label: 'Custom',
                sub: 'Write your own',
                primary: false,
                onTap: onCustom,
              ),
            ),
            const SizedBox(width: 8),
            _Pill(
              icon: Icons.shuffle,
              label: 'Shuffle',
              sub: 'Local',
              primary: false,
              onTap: onShuffle,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Pill(
          icon: Icons.movie_filter_outlined,
          label: 'Big Project',
          sub: '150 pts · 14–24 days',
          primary: false,
          onTap: onBigProject,
          fullWidth: true,
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05);
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool primary;
  final VoidCallback? onTap;
  final bool compact;
  final bool fullWidth;

  const _Pill({
    required this.icon,
    required this.label,
    required this.sub,
    required this.primary,
    this.onTap,
    this.compact = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    final tint = primary
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final widget = Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: compact ? 12 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: primary
                  ? LinearGradient(colors: [
                      theme.colorScheme.primary.withOpacity(0.16),
                      theme.colorScheme.secondary.withOpacity(0.08),
                    ])
                  : null,
              color: primary
                  ? null
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: primary
                    ? theme.colorScheme.primary.withOpacity(0.35)
                    : theme.colorScheme.outline,
              ),
            ),
            child: compact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: tint),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tint,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(icon, size: 16, color: tint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primary
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              sub,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return widget;
  }
}

class _SubmitPanel extends StatelessWidget {
  final dynamic session;
  final VoidCallback onSubmit;
  final VoidCallback onRecord;

  const _SubmitPanel({
    required this.session,
    required this.onSubmit,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final s = session;
    final theme = Theme.of(context);

    Widget content;

    if (s.statsReady) {
      content = _Row(
        title: 'Stats ready',
        subtitle:
            'Tap to record likes & views — your final score posts on submit',
        actionLabel: 'Record stats',
        icon: Icons.bar_chart_rounded,
        onTap: onRecord,
      );
    } else if (s.isSubmitted) {
      final days = s.statsUnlockDate.difference(DateTime.now()).inDays;
      content = _Row(
        title: 'Submitted',
        subtitle:
            'Stats unlock in $days day${days == 1 ? '' : 's'} (7-day rule)',
        actionLabel: 'Locked',
        icon: Icons.hourglass_top_outlined,
      );
    } else {
      content = _Row(
        title: 'Ready to submit?',
        subtitle: 'Paste your Instagram URL — penalty kicks in after deadline',
        actionLabel: 'Submit project',
        icon: Icons.upload_outlined,
        onTap: onSubmit,
        gradient: true,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        radius: 18,
        child: content,
      ).animate().fadeIn().slideY(begin: 0.05),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final bool gradient;

  const _Row({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient
                ? LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ])
                : null,
            color: gradient
                ? null
                : theme.colorScheme.primary.withOpacity(0.12),
          ),
          child: Icon(icon,
              color: gradient ? Colors.white : theme.colorScheme.primary,
              size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          GradientButton(
            label: actionLabel,
            dense: true,
            onTap: onTap,
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  final VoidCallback onAi;

  const _EmptyState({required this.onGenerate, required this.onAi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined,
              size: 56, color: theme.colorScheme.primary.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Nothing this week yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate three story prompts with AI — or shuffle our curated locals.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Generate with AI',
            icon: Icons.auto_awesome,
            onTap: onAi,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.shuffle, size: 16),
            label: const Text('Use local prompts'),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.06),
    );
  }
}
