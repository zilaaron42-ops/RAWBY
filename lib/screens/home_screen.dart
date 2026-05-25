// ============================================================
// RAWBY — Home Screen
// Bento dashboard. No submit / record buttons here — those live
// on the Prompts screen with the selected prompt. Home shows the
// next step, key stats, workflow progress and history preview.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/user_session.dart';
import '../providers/router_provider.dart';
import '../providers/user_session_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/projects/history_list.dart';

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
    return Scaffold(
      body: AuraBackground(
        topOnly: true,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeaderBar(session: session),
            ),

            // ── Next Step Hero ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _NextStepCard(session: session),
              ),
            ),

            // ── Bento Stats Grid ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: _BentoGrid(session: session),
              ),
            ),

            // ── Aurora CTA ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: _AuroraCTA(),
              ),
            ),

            // ── History ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.paddingOf(context).bottom + 80),
                child: _HistoryPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Bar ───────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final UserSession session;

  const _HeaderBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = session.displayName.isNotEmpty
        ? session.displayName.split(' ').first
        : (session.username.isNotEmpty ? session.username : 'creator');

    final weekStart = DateTime.tryParse(session.weekStart)?.toLocal();
    final deadline = DateTime.tryParse(session.deadline)?.toLocal();
    final weekLabel = (weekStart != null && deadline != null)
        ? '${DateFormat.MMMd().format(weekStart)} → ${DateFormat.MMMd().format(deadline)}'
        : '';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey, $name',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This week',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.04, end: 0),
                  if (weekLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      weekLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(Routes.profile),
              child: Consumer(
                builder: (ctx, ref, _) {
                  final s = ref.watch(userSessionProvider);
                  final name = s.displayName.isNotEmpty ? s.displayName : s.username;
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  final theme = Theme.of(ctx);
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ]),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Next Step Hero Card ──────────────────────────────────────

class _NextStepCard extends ConsumerWidget {
  final UserSession session;

  const _NextStepCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final step = _resolveStep(session);

    return GlassCard(
      onTap: step.onTap == null ? null : () => step.onTap!(context),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      radius: 22,
      gradient: [
        theme.colorScheme.primary.withValues(alpha: 0.15),
        theme.colorScheme.secondary.withValues(alpha: 0.05),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step.icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'NEXT STEP',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (step.badge != null)
                FilmTag(label: step.badge!, fontSize: 10),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            step.title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (step.cta != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  step.cta!,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  _Step _resolveStep(UserSession s) {
    if (s.isSubmitted && !s.statsReady && s.statsRecordedAt == null) {
      final until = s.statsUnlockDate.difference(DateTime.now()).inDays;
      return _Step(
        icon: Icons.hourglass_top_outlined,
        title: 'Submitted — stats unlock soon',
        subtitle: 'Stats become recordable in $until day${until == 1 ? '' : 's'} (7 days post-deadline rule).',
        cta: 'See progress on prompts',
        badge: 'WAITING',
        onTap: (ctx) => ctx.push(Routes.prompts),
      );
    }

    if (s.statsReady) {
      return _Step(
        icon: Icons.bar_chart,
        title: 'Stats ready — record likes',
        subtitle: 'Tap through to log likes & views. Score finalises on entry.',
        cta: 'Go to prompts to record',
        badge: 'ACTION',
        onTap: (ctx) => ctx.push(Routes.prompts),
      );
    }

    if (s.selectedPromptId != null && s.prompts.isNotEmpty) {
      final p = s.prompts.firstWhere(
        (p) => p.id == s.selectedPromptId,
        orElse: () => s.prompts.first,
      );

      if (s.workflow.isNotEmpty) {
        final allDone = s.workflow.every((t) => t.done);
        if (allDone) {
          return _Step(
            icon: Icons.check_circle_outline,
            title: 'Submit project',
            subtitle: 'All workflow steps done! Submit your ${p.level} project to lock in ${p.points} pts.',
            cta: 'Go to Prompts to submit',
            badge: 'READY',
            onTap: (ctx) => ctx.push(Routes.prompts),
          );
        }
        final nextTask = s.workflow.firstWhere((t) => !t.done, orElse: () => s.workflow.first);
        return _Step(
          icon: Icons.arrow_circle_right_outlined,
          title: 'Next step: ${nextTask.label}',
          subtitle: '${p.level} · ${p.points} pts · ${s.workflow.where((t) => t.done).length}/${s.workflow.length} tasks done',
          cta: 'Open prompts',
          badge: 'IN PROGRESS',
          onTap: (ctx) => ctx.push(Routes.prompts),
        );
      }

      return _Step(
        icon: Icons.movie_creation_outlined,
        title: 'Filming: ${p.level}',
        subtitle:
            '${p.points} pts · ${p.inspiration.isNotEmpty ? "inspo: ${p.inspiration}" : "open prompt for shot list & songs"}',
        cta: 'Open prompt detail',
        badge: 'IN PROGRESS',
        onTap: (ctx) => ctx.push(Routes.prompts),
      );
    }

    if (s.prompts.isEmpty) {
      return _Step(
        icon: Icons.auto_awesome,
        title: 'Generate your week',
        subtitle: 'Three new prompts will be ready in seconds. Tap to start.',
        cta: 'Generate prompts',
        badge: 'NEW WEEK',
        onTap: (ctx) => ctx.push(Routes.prompts),
      );
    }

    return _Step(
      icon: Icons.list_alt_outlined,
      title: 'Choose a prompt',
      subtitle: '${s.prompts.length} prompts waiting. Pick one — locks in for the week.',
      cta: 'Browse prompts',
      badge: 'PICK ONE',
      onTap: (ctx) => ctx.push(Routes.prompts),
    );
  }

}

class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? cta;
  final String? badge;
  final void Function(BuildContext)? onTap;

  _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cta,
    this.badge,
    this.onTap,
  });
}

// ── Bento Stats Grid ─────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  final UserSession session;

  const _BentoGrid({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadline = DateTime.tryParse(session.deadline)?.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = deadline == null
        ? null
        : DateTime(deadline.year, deadline.month, deadline.day);
    final daysLeft = deadlineDate == null
        ? 0
        : deadlineDate.difference(today).inDays.clamp(0, 9999);
    final hoursLeft = deadline == null
        ? 0
        : deadline.difference(now).inHours.clamp(0, 9999);
    final deadlineColor = _deadlineColor(theme, deadline);

    final cells = [
      StatTile(
        icon: Icons.local_fire_department_outlined,
        value: '${session.streak}',
        label: 'WEEK STREAK',
        color: const Color(0xFFE85D75),
      ),
      StatTile(
        icon: Icons.score,
        value: '${session.totalScore}',
        label: 'TOTAL POINTS',
        color: theme.colorScheme.primary,
      ),
      StatTile(
        icon: Icons.access_time,
        value: deadline == null
            ? '—'
            : (daysLeft > 0 ? '${daysLeft}d' : '${hoursLeft}h'),
        label: 'TIME LEFT',
        color: deadlineColor,
      ),
      StatTile(
        icon: Icons.favorite_border,
        value: _kFormat(session.avgLikes),
        label: 'AVG LIKES',
        color: const Color(0xFFE8B647),
      ),
      StatTile(
        icon: Icons.bookmark_border,
        value: '${session.savedPrompts.length}',
        label: 'IDEA BANK',
        color: theme.colorScheme.secondary,
        onTap: () => context.push(Routes.ideaBank),
      ),
      StatTile(
        icon: Icons.refresh,
        value: '${session.regensLeft}',
        label: 'REGENS',
        color: const Color(0xFF7C4DFF),
      ),
      StatTile(
        icon: Icons.favorite,
        value: session.history.isNotEmpty ? _kFormat(session.history.last.likes) : '—',
        label: 'LAST LIKES',
        color: const Color(0xFFE85D75),
      ),
      StatTile(
        icon: Icons.stars_rounded,
        value: session.history.isNotEmpty ? '${session.history.last.finalScore}' : '—',
        label: 'LAST PTS',
        color: const Color(0xFFE8B647),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 72,
      ),
      itemCount: cells.length,
      itemBuilder: (ctx, i) {
        return cells[i].animate(delay: (40 * i).ms).fadeIn().slideY(
              begin: 0.08,
              end: 0,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Color _deadlineColor(ThemeData theme, DateTime? d) {
    if (d == null) return theme.colorScheme.onSurfaceVariant;
    final hours = d.difference(DateTime.now()).inHours;
    if (hours < 0) return theme.colorScheme.error;
    if (hours < 24) return RawbyPalette.danger;
    if (hours < 48) return RawbyPalette.caution;
    return theme.colorScheme.primary;
  }

  String _kFormat(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── Aurora CTA ───────────────────────────────────────────────

class _AuroraCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GlassCard(
        onTap: () => context.push(Routes.assistant),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        radius: 20,
        gradient: [
          theme.colorScheme.secondary.withValues(alpha: 0.12),
          theme.colorScheme.primary.withValues(alpha: 0.04),
        ],
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ]),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk to Aurora',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'AI copilot — story, lighting, navigation & voice (Pro)',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
          ],
        ),
      ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.08, end: 0),
    );
  }
}

// ── History Panel ────────────────────────────────────────────

class _HistoryPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'Project History',
            subtitle: 'Past weeks — tap to inspect a submission',
            padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          ),
          HistoryList(),
        ],
      ),
    ).animate(delay: 420.ms).fadeIn();
  }
}
