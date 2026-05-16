import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement_model.dart';
import '../../providers/user_session_provider.dart';

class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final achievements = session.achievements;
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        'Achievements',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: achievements.map((a) => _BadgeChip(achievement: a, theme: theme)).toList(),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final Achievement achievement;
  final ThemeData theme;

  const _BadgeChip({required this.achievement, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isEarned = achievement.earned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEarned ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEarned ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEarned ? achievement.icon : '⬜',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            achievement.label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isEarned ? FontWeight.w600 : FontWeight.normal,
              color: isEarned ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isEarned && achievement.target > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${achievement.progress}/${achievement.target}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
