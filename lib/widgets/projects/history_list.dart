// ============================================================
// RAWBY — Project History List
// Shows completed weeks timeline with scores, pending stats
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/project_model.dart';
import '../../providers/user_session_provider.dart';
import '../../services/scoring_service.dart';
import '../../theme/app_colors.dart';
import 'record_stats_modal.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final history = session.scoringHistory;
    final pending = session.pendingStats;

    if (history.isEmpty && pending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 40,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 10),
              Text(
                'No completed projects yet',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Submit your first project to see history here',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending stats (awaiting 7-day unlock)
        ...pending.map((p) => _PendingStatsCard(pending: p, theme: theme)),

        // Completed history
        ...history.map((entry) => _HistoryCard(entry: entry, theme: theme)),
      ],
    );
  }
}

// ── Pending Stats Card ───────────────────────────────────────

class _PendingStatsCard extends ConsumerWidget {
  final PendingStats pending;
  final ThemeData theme;

  const _PendingStatsCard({required this.pending, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueOn = DateTime.tryParse(pending.dueOn) ?? DateTime.now();
    final now = DateTime.now().toUtc();
    final isReady = now.isAfter(dueOn.toUtc());
    final daysLeft = dueOn.toUtc().difference(now).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReady
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                pending.level == 'Sequence'
                    ? '🎞️'
                    : pending.level == 'Short Story'
                        ? '🎬'
                        : '🎭',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pending.level} · ${pending.points} pts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isReady
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.outline.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isReady ? '📊 Stats ready!' : '⏳ ${daysLeft}d left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isReady
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (pending.promptText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              pending.promptText,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isReady) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => RecordStatsModal(pendingStats: pending),
                  );
                },
                icon: const Icon(Icons.bar_chart, size: 16),
                label: const Text(
                  'Record Stats',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History Card ─────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final ThemeData theme;

  const _HistoryCard({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final submittedAt = DateTime.tryParse(entry.submittedAt);
    final deadline = DateTime.tryParse(entry.deadline);
    final multiplier = (submittedAt != null && deadline != null)
        ? ScoringService.penaltyMultiplier(submittedAt, deadline)
        : 1.0;
    final isLate = multiplier < 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Level icon
          Text(
            entry.level == 'Sequence'
                ? '🎞️'
                : entry.level == 'Short Story'
                    ? '🎬'
                    : '🎭',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.promptText.isNotEmpty
                      ? entry.promptText
                      : entry.level,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (entry.likes > 0) ...[
                      Icon(Icons.favorite, size: 12, color: RawbyPalette.danger),
                      const SizedBox(width: 4),
                      Text('${entry.likes} likes', style: theme.textTheme.labelSmall),
                      if (entry.views > 0) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.visibility, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${entry.views} views', style: theme.textTheme.labelSmall),
                      ],
                      const SizedBox(width: 8),
                    ],
                    if (isLate)
                      Text(
                        '×$multiplier',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    if (entry.isTestRun)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TEST',
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.isTestRun ? '—' : '+${entry.score}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: entry.isTestRun
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
              Text(
                'pts',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
