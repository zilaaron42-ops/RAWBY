// ============================================================
// RAWBY — Prompts Screen (Full Implementation)
// Shows the Weekly 3 prompts with AI regen, custom, Idea Bank
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_session_provider.dart';
import '../providers/router_provider.dart';
import '../services/prompt_service.dart';
import '../widgets/prompts/prompt_card.dart';
import '../widgets/prompts/ai_generate_modal.dart';
import '../widgets/prompts/custom_prompt_modal.dart';
import '../widgets/prompts/prompt_confirm_banner.dart';
import '../theme/app_colors.dart';

class PromptsScreen extends ConsumerWidget {
  const PromptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isLocked = session.isLocked;
    final regensLeft = session.regensLeft;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Pull-to-refresh regenerates local prompts
          if (!isLocked) {
            final service = ref.read(promptServiceProvider);
            final prompts = service.generateLocalPrompts();
            ref.read(userSessionProvider.notifier).setPrompts(prompts);
          }
        },
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                                'This Week\'s Prompts',
                                style: theme.textTheme.headlineMedium,
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                              const SizedBox(height: 2),
                              Text(
                                isLocked
                                    ? 'Prompt locked — project in progress'
                                    : 'Choose one to start your project',
                                style: theme.textTheme.bodySmall,
                              ).animate(delay: 80.ms).fadeIn(),
                            ],
                          ),
                        ),
                        // Idea Bank button
                        IconButton(
                          onPressed: () => context.go(Routes.ideaBank),
                          icon: Stack(
                            children: [
                              const Icon(Icons.bookmark_border),
                              if (session.savedPrompts.isNotEmpty)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          tooltip: 'Idea Bank',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Action buttons ───────────────────────────
                    if (!isLocked) ...[
                      Row(
                        children: [
                          // AI Generate
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.auto_awesome,
                              label: 'AI Generate',
                              sublabel: '$regensLeft left',
                              onTap: regensLeft > 0
                                  ? () => _showAiModal(context, ref)
                                  : null,
                              isPrimary: true,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Custom Prompt
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Custom',
                              sublabel: 'Write your own',
                              onTap: () => _showCustomModal(context, ref),
                              isPrimary: false,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Shuffle local
                          _ActionButton(
                            icon: Icons.shuffle,
                            label: 'Shuffle',
                            sublabel: 'Local',
                            onTap: () {
                              final service = ref.read(promptServiceProvider);
                              final prompts = service.generateLocalPrompts();
                              ref
                                  .read(userSessionProvider.notifier)
                                  .setPrompts(prompts);
                            },
                            isPrimary: false,
                            theme: theme,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Locked banner ────────────────────────────
                    if (isLocked)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You\'ve submitted this week. Prompts unlock next cycle.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const PromptConfirmBanner(),
                  ],
                ),
              ),
            ),

            // ── Prompt Cards ─────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prompt = session.prompts[index];
                    final isSelected = session.selectedPromptId == prompt.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PromptCard(
                        prompt: prompt,
                        isSelected: isSelected,
                        isLocked: isLocked,
                        index: index,
                        onChoose: isLocked
                            ? null
                            : () {
                                ref
                                    .read(userSessionProvider.notifier)
                                    .selectPrompt(prompt.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${prompt.level} chosen! ${prompt.points} pts',
                                    ),
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

            // ── Empty state ──────────────────────────────────────
            if (session.prompts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No prompts yet',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final service = ref.read(promptServiceProvider);
                          final prompts = service.generateLocalPrompts();
                          ref
                              .read(userSessionProvider.notifier)
                              .setPrompts(prompts);
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Generate Local Prompts'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiGenerateModal(),
    );
  }

  Future<void> _showCustomModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomPromptModal(),
    );
  }
}

// ── Action Button ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool compact;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    required this.isPrimary,
    required this.theme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? theme.colorScheme.primary.withOpacity(0.1)
                : (isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrimary
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : (isDark
                      ? RawbyPalette.darkBorder
                      : RawbyPalette.lightBorder),
            ),
          ),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isPrimary
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isPrimary
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            sublabel,
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
    );
  }
}
