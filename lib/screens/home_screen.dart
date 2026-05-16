// ============================================================
// RAWBY — Home Screen  |  Command Center
// flutter_animate stagger · glass cards · Instagram stats
// ============================================================
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/user_session_provider.dart';
import '../providers/router_provider.dart';
import '../models/project_model.dart';
import '../services/scoring_service.dart';
import '../theme/app_colors.dart';
import '../constants/ranks.dart';
import '../widgets/projects/submit_modal.dart';
import '../widgets/projects/gear_log_modal.dart';
import '../widgets/projects/record_stats_modal.dart';
import '../widgets/projects/big_project_modal.dart';
import '../widgets/projects/history_list.dart';
import '../widgets/projects/project_summary_modal.dart';
import '../widgets/home/countdown_timer.dart';
import '../widgets/prompts/prompt_confirm_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _jarvisCtrl;

  @override
  void initState() {
    super.initState();
    _jarvisCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _jarvisCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentProject = session.prompts.isNotEmpty ? session.prompts.first : null;
    final deadline = DateTime.tryParse(session.deadline);
    final activeBigProject = session.activeBigProject;
    final isBigProject = activeBigProject != null;

    final daysLeft = deadline != null ? ScoringService.daysUntilDeadline(deadline) : 0;
    final hoursLeft = deadline != null ? ScoringService.hoursUntilDeadline(deadline) : 0;
    final deadlineStatus = deadline != null ? ScoringService.deadlineStatus(deadline) : DeadlineStatus.safe;

    Color deadlineColor;
    String deadlineLabel;
    switch (deadlineStatus) {
      case DeadlineStatus.overdue:
        deadlineColor = theme.colorScheme.error;
        deadlineLabel = 'Overdue!';
      case DeadlineStatus.urgent:
        deadlineColor = RawbyPalette.danger;
        deadlineLabel = '${hoursLeft}h left!';
      case DeadlineStatus.warning:
        deadlineColor = RawbyPalette.caution;
        deadlineLabel = '${daysLeft}d left';
      case DeadlineStatus.safe:
        deadlineColor = theme.colorScheme.primary;
        deadlineLabel = daysLeft == 0 && hoursLeft > 0
            ? '${hoursLeft}h left'
            : '${daysLeft}d left';
    }

    final submitted = session.submittedAt != null;
    final statsReady = session.statsReady;
    final statsRecorded = session.statsRecordedAt != null;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    final name = session.displayName.isNotEmpty ? session.displayName : session.username;

    final rank = Ranks.getRank(session.totalScore);
    final streak = session.streak;
    final recentHistory = session.scoringHistory.reversed.take(3).toList();

    final avgLikes = session.avgLikes;
    final lastLikes = recentHistory.isNotEmpty && recentHistory.first.likes > 0
        ? recentHistory.first.likes
        : 0;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $name',
                                style: theme.textTheme.headlineMedium,
                              ).animate().fadeIn(duration: 400.ms).slideY(
                                    begin: 0.15,
                                    end: 0,
                                    curve: Curves.easeOutCubic,
                                  ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat.yMMMMEEEEd().format(DateTime.now()),
                                style: theme.textTheme.bodySmall,
                              ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                            ],
                          ),
                          // JARVIS pulsing button
                          AnimatedBuilder(
                            animation: _jarvisCtrl,
                            builder: (ctx, _) => GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.go(Routes.aiAssistant);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      theme.colorScheme.tertiary
                                          .withValues(alpha: 0.25 + _jarvisCtrl.value * 0.15),
                                      theme.colorScheme.tertiary.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.tertiary
                                        .withValues(alpha: 0.5 + _jarvisCtrl.value * 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.tertiary
                                          .withValues(alpha: 0.2 + _jarvisCtrl.value * 0.15),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 20,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).scale(
                                begin: const Offset(0.8, 0.8),
                              ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Stats Row ────────────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StatChip(
                              icon: Icons.local_fire_department,
                              label: 'Streak',
                              value: '${streak}w',
                              color: streak > 0 ? RawbyPalette.warning : theme.colorScheme.onSurfaceVariant,
                              delay: 0,
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.military_tech,
                              label: 'Rank',
                              value: rank.label,
                              color: theme.colorScheme.primary,
                              delay: 60,
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.star_rounded,
                              label: 'Score',
                              value: '${session.totalScore}',
                              color: theme.colorScheme.primary,
                              delay: 120,
                            ),
                            if (avgLikes > 0) ...[
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.favorite_rounded,
                                label: 'Avg Likes',
                                value: '$avgLikes',
                                color: RawbyPalette.danger,
                                delay: 180,
                              ),
                            ],
                            if (lastLikes > 0) ...[
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.play_circle_outline,
                                label: 'Last Video',
                                value: '$lastLikes',
                                color: RawbyPalette.info,
                                delay: 240,
                              ),
                            ],
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.access_time_rounded,
                              label: 'Deadline',
                              value: deadlineLabel,
                              color: deadlineColor,
                              delay: 300,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Instagram engagement banner ───────────────
                      if (avgLikes > 0 || lastLikes > 0)
                        _InstagramBanner(
                          avgLikes: avgLikes,
                          lastLikes: lastLikes,
                          theme: theme,
                          isDark: isDark,
                        )
                            .animate(delay: 350.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                      // ── Prompt confirm banner ─────────────────────
                      const PromptConfirmBanner(),
                      const SizedBox(height: 8),

                      // ── Big Project Active Card ───────────────────
                      if (isBigProject) ...[
                        _BigProjectActiveCard(
                          project: activeBigProject,
                          theme: theme,
                          isDark: isDark,
                        )
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDnfBigProject(context),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('DNF Big Project (−150 pts)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Active Weekly Project Card ────────────────
                      if (currentProject != null && !isBigProject && session.isPromptConfirmed) ...[
                        Text('Current Project', style: theme.textTheme.titleSmall)
                            .animate(delay: 250.ms)
                            .fadeIn(),
                        const SizedBox(height: 8),
                        _GlassProjectCard(
                          project: currentProject,
                          deadlineColor: deadlineColor,
                          deadlineLabel: deadlineLabel,
                          theme: theme,
                          isDark: isDark,
                        )
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.08, end: 0),
                        const SizedBox(height: 16),
                      ],

                      // ── Action Buttons ────────────────────────────
                      if (currentProject != null && !isBigProject) ...[
                        if (!submitted)
                          SizedBox(
                            width: double.infinity,
                            child: _GlowButton(
                              label: deadlineStatus == DeadlineStatus.overdue
                                  ? 'Submit Late'
                                  : 'Submit Project',
                              icon: Icons.upload_outlined,
                              color: deadlineStatus == DeadlineStatus.overdue
                                  ? RawbyPalette.danger
                                  : theme.colorScheme.primary,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showSubmitModal(context);
                              },
                            ).animate(delay: 380.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                          ),

                        if (submitted && !statsReady && !statsRecorded) ...[
                          const SizedBox(height: 8),
                          _StatusBanner(
                            icon: Icons.check_circle_outline,
                            color: RawbyPalette.success,
                            title: 'Project Submitted!',
                            subtitle: 'Stats unlock in ${session.statsUnlockDate.difference(DateTime.now()).inDays} days',
                          ).animate(delay: 380.ms).fadeIn(duration: 400.ms),
                        ],

                        if (submitted && statsReady && !statsRecorded) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _GlowButton(
                              label: 'Record Stats  —  Likes / Views',
                              icon: Icons.bar_chart_rounded,
                              color: RawbyPalette.caution,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showRecordStatsModal(context);
                              },
                            ).animate(delay: 380.ms).fadeIn().slideY(begin: 0.1, end: 0),
                          ),
                        ],
                      ],

                      // ── No Active Project — CTA ───────────────────
                      if (currentProject == null && !isBigProject) ...[
                        const SizedBox(height: 8),
                        _EmptyProjectCard(theme: theme, isDark: isDark)
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                      ],

                      // ── Workflow Section ──────────────────────────
                      if (currentProject != null && session.isPromptConfirmed) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Your Workflow', style: theme.textTheme.titleSmall),
                            Text(
                              '${session.workflow.where((t) => t.done).length}/${session.workflow.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ).animate(delay: 400.ms).fadeIn(),
                        const SizedBox(height: 10),

                        if (deadline != null)
                          _DeadlineCard(
                            deadline: deadline,
                            deadlineColor: deadlineColor,
                            deadlineLabel: deadlineLabel,
                            theme: theme,
                          )
                              .animate(delay: 440.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.08, end: 0),
                        const SizedBox(height: 16),

                        Builder(builder: (ctx) {
                          final allDone = session.workflow.every((t) => t.done);
                          if (allDone) {
                            return _StatusBanner(
                              icon: Icons.check_circle,
                              color: RawbyPalette.success,
                              title: 'All tasks complete',
                              subtitle: 'Ready to submit your project!',
                            ).animate(delay: 460.ms).fadeIn();
                          }
                          final nextTask = session.workflow.firstWhere(
                            (t) => !t.done,
                            orElse: () => session.workflow.last,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Up Next', style: theme.textTheme.bodySmall)
                                  .animate(delay: 460.ms)
                                  .fadeIn(),
                              const SizedBox(height: 6),
                              _WorkflowTaskTile(task: nextTask, theme: theme)
                                  .animate(delay: 480.ms)
                                  .fadeIn()
                                  .slideY(begin: 0.06, end: 0),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),

                        Text('All Tasks', style: theme.textTheme.bodySmall)
                            .animate(delay: 500.ms)
                            .fadeIn(),
                        const SizedBox(height: 6),
                        ...session.workflow.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _WorkflowTaskTile(task: e.value, theme: theme)
                                  .animate(delay: Duration(milliseconds: 520 + e.key * 40))
                                  .fadeIn()
                                  .slideX(begin: -0.03, end: 0),
                            )),
                      ],

                      // ── Recent Projects ───────────────────────────
                      if (recentHistory.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Projects', style: theme.textTheme.titleSmall),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('See all'),
                            ),
                          ],
                        ).animate(delay: 600.ms).fadeIn(),
                        const SizedBox(height: 8),
                        ...recentHistory.asMap().entries.map((e) => _MiniHistoryCard(
                              entry: e.value,
                              theme: theme,
                              isDark: isDark,
                            )
                                .animate(delay: Duration(milliseconds: 620 + e.key * 60))
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.06, end: 0)),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Full History ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project History', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      const HistoryList(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── No-project FAB: Start Big Project ────────────────────
          if (currentProject == null && !isBigProject)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => _showBigProjectModal(context),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.movie_creation_outlined, size: 18),
                label: const Text(
                  'Big Project',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ).animate(delay: 500.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
            ),
        ],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project submitted! Stats ready in 7 days.')),
      );
      if (context.mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const GearLogModal(),
        );
        if (context.mounted) {
          final session = ref.read(userSessionProvider);
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ProjectSummaryModal(weekStart: session.weekStart),
          );
        }
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

  Future<void> _showBigProjectModal(BuildContext context) async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BigProjectModal(),
    );
    if (started == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Big project started! Good luck!')),
      );
    }
  }

  Future<void> _confirmDnfBigProject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('DNF Big Project?', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
        content: const Text('You will lose 150 points. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Give Up (−150 pts)',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(userSessionProvider.notifier).dnfBigProject();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Big project DNF — 150 pts deducted.')),
        );
      }
    }
  }
}

// ── Instagram Engagement Banner ──────────────────────────────

class _InstagramBanner extends StatelessWidget {
  final int avgLikes;
  final int lastLikes;
  final ThemeData theme;
  final bool isDark;

  const _InstagramBanner({
    required this.avgLikes,
    required this.lastLikes,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RawbyPalette.danger.withValues(alpha: 0.08),
            const Color(0xFF833AB4).withValues(alpha: 0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RawbyPalette.danger.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF833AB4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instagram Engagement',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  avgLikes > 0 ? 'Avg $avgLikes likes per video' : 'Log stats to see metrics',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (lastLikes > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 13, color: RawbyPalette.danger),
                    const SizedBox(width: 4),
                    Text(
                      '$lastLikes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: RawbyPalette.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text('last video', style: theme.textTheme.labelSmall),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Glass Project Card ───────────────────────────────────────

class _GlassProjectCard extends StatelessWidget {
  final dynamic project;
  final Color deadlineColor;
  final String deadlineLabel;
  final ThemeData theme;
  final bool isDark;

  const _GlassProjectCard({
    required this.project,
    required this.deadlineColor,
    required this.deadlineLabel,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = project.level == 'Sequence'
        ? '🎞️'
        : project.level == 'Short Story'
            ? '🎬'
            : '🎭';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF141414).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${project.level}  ·  ${project.points} pts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.text,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: deadlineColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: deadlineColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 12, color: deadlineColor),
                              const SizedBox(width: 5),
                              Text(
                                deadlineLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: deadlineColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ── Glow Button ──────────────────────────────────────────────

class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Banner ────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Project Card ───────────────────────────────────────

class _EmptyProjectCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  const _EmptyProjectCard({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : RawbyPalette.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : RawbyPalette.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.videocam_off_outlined, size: 44, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('No active project', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Start your next filmmaking challenge',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go(Routes.prompts),
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              label: const Text('Choose a Prompt'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BigProjectModal(),
              ),
              icon: const Icon(Icons.movie_creation_outlined, size: 16),
              label: const Text('Start a Big Project'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deadline Card ────────────────────────────────────────────

class _DeadlineCard extends StatelessWidget {
  final DateTime deadline;
  final Color deadlineColor;
  final String deadlineLabel;
  final ThemeData theme;

  const _DeadlineCard({
    required this.deadline,
    required this.deadlineColor,
    required this.deadlineLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: deadlineColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: deadlineColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: deadlineColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat.yMMMEd().add_jm().format(deadline),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: deadlineColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: deadlineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  deadlineLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: deadlineColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CountdownTimer(deadline: deadline, accentColor: deadlineColor),
        ],
      ),
    );
  }
}

// ── Big Project Active Card ──────────────────────────────────

class _BigProjectActiveCard extends StatelessWidget {
  final BigProject project;
  final ThemeData theme;
  final bool isDark;

  const _BigProjectActiveCard({
    required this.project,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysElapsed = now.difference(project.startedAt).inDays;
    final daysRemaining = project.deadline.difference(now).inDays.clamp(0, project.durationDays);
    final progress = (daysElapsed / project.durationDays).clamp(0.0, 1.0);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.movie_creation_outlined, size: 16, color: primary),
              const SizedBox(width: 8),
              Text('Big Project', style: theme.textTheme.titleSmall?.copyWith(color: primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(project.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [
              _BigProjectStat(label: 'Days in', value: '$daysElapsed', theme: theme),
              const SizedBox(width: 24),
              _BigProjectStat(label: 'Days left', value: '$daysRemaining', theme: theme),
              const SizedBox(width: 24),
              _BigProjectStat(label: 'Total', value: '${project.durationDays}d', theme: theme),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF222222) : RawbyPalette.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(progress * 100).round()}% complete', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BigProjectStat extends StatelessWidget {
  final String label, value;
  final ThemeData theme;
  const _BigProjectStat({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ── Mini History Card ────────────────────────────────────────

class _MiniHistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final ThemeData theme;
  final bool isDark;

  const _MiniHistoryCard({
    required this.entry,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = entry.level == 'Sequence'
        ? '🎞️'
        : entry.level == 'Short Story'
            ? '🎬'
            : '🎭';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : RawbyPalette.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1F1F1F) : RawbyPalette.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.promptText.isNotEmpty ? entry.promptText : entry.level,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.likes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_rounded, size: 12, color: RawbyPalette.danger),
                        const SizedBox(width: 4),
                        Text('${entry.likes}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: RawbyPalette.danger,
                              fontWeight: FontWeight.w600,
                            )),
                        if (entry.views > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.visibility_rounded, size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${entry.views}', style: theme.textTheme.labelSmall),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            entry.isTestRun ? '—' : '+${entry.score}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: entry.isTestRun
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workflow Task Tile ───────────────────────────────────────

class _WorkflowTaskTile extends ConsumerWidget {
  final WorkflowTask task;
  final ThemeData theme;

  const _WorkflowTaskTile({required this.task, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: task.done
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : (isDark ? const Color(0xFF141414) : RawbyPalette.lightCard),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.done
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.done ? Icons.check_circle_outline : Icons.radio_button_off,
            size: 18,
            color: task.done ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    color: task.done
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  task.done
                      ? 'Done ${DateFormat.yMMMd().format(task.completedAt!)}'
                      : 'Due on ${task.day}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!task.done && !ref.watch(userSessionProvider).isLocked)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(userSessionProvider.notifier).completeWorkflowTask(task.id);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : RawbyPalette.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1F1F1F) : RawbyPalette.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 150 + delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}
