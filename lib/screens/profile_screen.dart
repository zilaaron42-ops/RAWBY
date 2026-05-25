// ============================================================
// RAWBY — Profile Screen (Full Implementation)
// Shows user stats, achievements, and project history
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_session_provider.dart';
import '../services/api_service.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/projects/history_list.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _fetchingIg = false;
  String? _igStatus;

  Future<void> _refreshInstagramStats() async {
    final session = ref.read(userSessionProvider);
    final handle = session.preferences.instagramHandle;
    if (handle.isEmpty) return;

    setState(() {
      _fetchingIg = true;
      _igStatus = null;
    });
    HapticFeedback.lightImpact();

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.fetchInstagramHandleStats(handle);
      final avgLikes = result['avgLikes'] as int? ?? 0;
      final lastLikes = result['lastPostLikes'] as int? ?? 0;
      final msg = result['message'] as String?;

      setState(() {
        _igStatus = avgLikes > 0
            ? 'Updated: avg $avgLikes likes, last post $lastLikes likes'
            : (msg ?? 'Stats not available — Instagram API not configured.');
        _fetchingIg = false;
      });
    } catch (_) {
      setState(() {
        _igStatus = 'Could not connect to server.';
        _fetchingIg = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final prefs = session.preferences;
    final theme = Theme.of(context);
    final achievements = session.achievements;
    final earned = achievements.where((a) => a.earned).toList();

    return Scaffold(
      body: AuraBackground(
        topOnly: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ]),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        session.displayName.isNotEmpty
                            ? session.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.displayName.isNotEmpty
                                ? session.displayName
                                : session.username,
                            style: theme.textTheme.headlineLarge,
                          ),
                          Text(
                            '@${session.username}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit Profile',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditProfileModal(context),
                    ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.04),
                const SizedBox(height: 16),

            // Rank progress card (always show — it's the core identity)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (ctx, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - v)),
                  child: child,
                ),
              ),
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.currentRank.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.currentRank.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${session.totalScore} points total',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (session.nextRank != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (() {
                                final next = session.nextRank!;
                                final current = session.currentRank;
                                final range = next.minScore - current.minScore;
                                if (range <= 0) return 1.0;
                                return ((session.totalScore - current.minScore) / range).clamp(0.0, 1.0);
                              })(),
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${session.nextRank!.minScore - session.totalScore} pts to ${session.nextRank!.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ), // TweenAnimationBuilder
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                if (prefs.showScore) ...[
                  _StatBox(
                    label: 'Score',
                    value: '${session.totalScore}',
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                ],
                _StatBox(
                  label: 'Projects',
                  value: '${session.scoringHistory.length}',
                  theme: theme,
                ),
                if (prefs.showStreak) ...[
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Streak',
                    value: '${session.streak}🔥',
                    theme: theme,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Achievements
            if (prefs.showAchievements) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Achievements', style: theme.textTheme.headlineSmall),
                Text(
                  '${earned.length}/${achievements.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((a) {
                return Tooltip(
                  message: '${a.label}: ${a.description}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: a.earned
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: a.earned
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.icon,
                          style: TextStyle(
                            fontSize: 14,
                            color: a.earned ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          a.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: a.earned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (a.target > 1 && !a.earned) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${a.progress}/${a.target}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: a.progressPercent,
                              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                a.progressPercent >= 1.0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            ], // end showAchievements

            // Engagement stats
            if (prefs.showEngagement) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Engagement', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (prefs.instagramHandle.isNotEmpty)
                  TextButton.icon(
                    onPressed: _fetchingIg ? null : _refreshInstagramStats,
                    icon: _fetchingIg
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 14),
                    label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            if (_igStatus != null) ...[
              const SizedBox(height: 4),
              Text(
                _igStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _igStatus!.startsWith('Updated')
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _StatBox(
                  label: 'Total Likes',
                  value: '${session.totalLikes}',
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatBox(
                  label: 'Avg Likes',
                  value: '${session.avgLikes}',
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatBox(
                  label: 'Last Video',
                  value: session.history.isNotEmpty && session.history.last.likes > 0
                      ? '${session.history.last.likes}'
                      : '—',
                  theme: theme,
                ),
              ],
            ),
            ], // end showEngagement

            // Project History
            if (prefs.showHistory) ...[
            const SizedBox(height: 32),
            Text(
              'Project History',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const HistoryList(),
            ], // end showHistory

            // Logout
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: Icon(Icons.logout, size: 16, color: theme.colorScheme.error),
                label: Text(
                  'Log Out',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileModal(BuildContext context) async {
    final session = ref.read(userSessionProvider);
    final nameCtrl = TextEditingController(text: session.displayName);
    final bioCtrl = TextEditingController(text: session.preferences.bio);
    final igCtrl = TextEditingController(text: session.preferences.instagramHandle);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Edit Profile', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                Text('Display Name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'Your name'),
                ),
                const SizedBox(height: 16),
                Text('Bio', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(hintText: 'Short bio...'),
                ),
                const SizedBox(height: 16),
                Text('Instagram Handle', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                TextField(
                  controller: igCtrl,
                  decoration: const InputDecoration(hintText: '@yourhandle'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final notifier = ref.read(userSessionProvider.notifier);
                      final prefs = ref.read(userSessionProvider).preferences;
                      notifier.updateDisplayName(nameCtrl.text.trim());
                      notifier.updatePreferences(prefs.copyWith(
                        bio: bioCtrl.text.trim(),
                        instagramHandle: igCtrl.text.trim().replaceFirst('@', ''),
                      ));
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    nameCtrl.dispose();
    bioCtrl.dispose();
    igCtrl.dispose();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Your data is saved. You can log back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Log Out',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(userSessionProvider.notifier).logout();
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatBox({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
