// ============================================================
// RAWBY — Skill Screen
// Focus on growth, score, and AI-powered learning plans
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_session_provider.dart';
import '../models/user_session.dart';
import '../widgets/skill/skill_feedback_modal.dart';

class SkillScreen extends ConsumerWidget {
  const SkillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skill Growth',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  // — Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Current Skill Score',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${session.skillScore}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Rank: ${session.currentRank.label} ${session.currentRank.icon}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatsSection(theme, session),
                  const SizedBox(height: 24),
                  _buildJournalSection(theme, session),
                  const SizedBox(height: 24),
                  _buildAiPlanSection(context, theme, session, ref),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Global Stats', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(
              label: 'Total Likes',
              value: '${session.totalLikes}',
              icon: Icons.favorite,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Total Views',
              value: '${session.totalViews}',
              icon: Icons.visibility,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJournalSection(ThemeData theme, UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skill Journal', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        if (session.skillEntries.isEmpty)
          Text(
            'No entries yet. Start reflecting on your projects!',
            style: theme.textTheme.bodySmall,
          )
        else
          ...session.skillEntries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.createdAt.toIso8601String().substring(0, 10),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.content, style: theme.textTheme.bodyMedium),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildAiPlanSection(BuildContext context, ThemeData theme, UserSession session, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Learning Plan', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.skillAiPlan.isEmpty
                    ? 'No active plan. Generate one to focus your growth.'
                    : session.skillAiPlan,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showFeedbackModal(context, ref),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate New Plan'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFeedbackModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SkillFeedbackModal(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}