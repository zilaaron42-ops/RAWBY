// ============================================================
// RAWBY — Leaderboard Screen
// Podium top 3, full ranked list, user rank panel, overtake alert.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_session_provider.dart';
import '../services/api_service.dart';
import '../constants/ranks.dart';
import '../widgets/leaderboard/achievements_section.dart';
import '../widgets/common/glass_card.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<dynamic> _entries = [];
  bool _loading = true;
  String? _error;
  int? _prevUserPosition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final session = ref.read(userSessionProvider);
    try {
      final api = ref.read(apiServiceProvider);
      if (!api.hasAuthToken) {
        setState(() {
          _error = 'Sign in again to view the leaderboard.';
          _loading = false;
        });
        return;
      }
      final data = await api.getLeaderboard();
      final entries = data['leaderboard'] as List<dynamic>? ?? [];

      // Check for overtake
      final userId = session.userId;
      final newPos = entries.indexWhere((e) => (e as Map<String, dynamic>)['userId'] == userId);
      if (_prevUserPosition != null && newPos != -1 && newPos > _prevUserPosition!) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Someone just passed you on the leaderboard! You dropped to #${newPos + 1}.'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.deepOrange,
            ),
          );
        }
      }
      _prevUserPosition = newPos >= 0 ? newPos : null;

      setState(() {
        _entries = entries;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load leaderboard.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: theme.colorScheme.primary,
        child: _loading
            ? _LoadingShimmer(theme: theme)
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _load();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Builder(
                  builder: (context) {
                    final session = ref.watch(userSessionProvider);
                    final rank = session.currentRank;
                    final nextRank = session.nextRank;
                    final ptsToNext = nextRank != null ? (nextRank.minScore - session.totalScore).clamp(0, 9999) : 0;
                    final userId = session.userId;
                    final userPos = _entries.indexWhere((e) => (e as Map<String, dynamic>)['userId'] == userId);
                    return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                          child: Text('Leaderboard', style: theme.textTheme.headlineMedium),
                        ),
                      ),
                      // ── Your Rank Panel ───────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: GlassCard(
                            gradient: [
                              theme.colorScheme.primary.withOpacity(0.12),
                              theme.colorScheme.secondary.withOpacity(0.04),
                            ],
                            child: Row(
                              children: [
                                Text(rank.icon, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rank.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      Text(
                                        userPos >= 0 ? '#${userPos + 1} · ${session.totalScore} pts' : '${session.totalScore} pts',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (nextRank != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Next: ${nextRank.label}', style: theme.textTheme.labelSmall),
                                      Text('$ptsToNext pts', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.secondary)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Podium for top 3
                      if (_entries.length >= 3)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: _Podium(entries: _entries.take(3).toList(), theme: theme),
                          ),
                        ),
                      // Rest of the list
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final actualIndex = _entries.length >= 3 ? index + 3 : index;
                              if (actualIndex >= _entries.length) return null;
                              final entry = _entries[actualIndex] as Map<String, dynamic>;
                              final rankLabel = entry['rankLabel'] as String? ?? 'Starter';
                              final rankDef = Ranks.all.firstWhere(
                                (r) => r.label == rankLabel,
                                orElse: () => Ranks.all.first,
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.colorScheme.outline),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '#${actualIndex + 1}',
                                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Text(rankDef.icon, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry['displayName'] as String? ?? '',
                                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          Text(rankLabel, style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${entry['totalScore'] ?? 0}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _entries.length >= 3 ? _entries.length - 3 : _entries.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.paddingOf(context).bottom + 80),
                          child: const AchievementsSection(),
                        ),
                      ),
                    ],
                  );
                  },
                ),
      ),
    );
  }
}

// ── Podium Widget ─────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<dynamic> entries;
  final ThemeData theme;

  const _Podium({required this.entries, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();
    final first = entries[0] as Map<String, dynamic>;
    final second = entries[1] as Map<String, dynamic>;
    final third = entries[2] as Map<String, dynamic>;
    final base = MediaQuery.sizeOf(context).height * 0.13;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        Expanded(child: _PodiumTile(entry: second, place: 2, height: base * 0.77, theme: theme)),
        const SizedBox(width: 8),
        // 1st place
        Expanded(child: _PodiumTile(entry: first, place: 1, height: base, theme: theme)),
        const SizedBox(width: 8),
        // 3rd place
        Expanded(child: _PodiumTile(entry: third, place: 3, height: base * 0.62, theme: theme)),
      ],
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int place;
  final double height;
  final ThemeData theme;

  const _PodiumTile({
    required this.entry,
    required this.place,
    required this.height,
    required this.theme,
  });

  Color get _medalColor {
    switch (place) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return theme.colorScheme.outline;
    }
  }

  String get _medal {
    switch (place) {
      case 1:
        return '\u{1F947}';
      case 2:
        return '\u{1F948}';
      case 3:
        return '\u{1F949}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = entry['displayName'] as String? ?? '';
    final score = entry['totalScore'] ?? 0;
    final rankLabel = entry['rankLabel'] as String? ?? 'Starter';
    final rankDef = Ranks.all.firstWhere(
      (r) => r.label == rankLabel,
      orElse: () => Ranks.all.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + medal
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: place == 1 ? 28 : 22,
              backgroundColor: _medalColor.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: place == 1 ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Text(_medal, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          '${rankDef.icon} $rankLabel',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 4),
        // Podium bar
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _medalColor.withOpacity(0.3),
                _medalColor.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: _medalColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '$score',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading Shimmer ──────────────────────────────────────────

class _LoadingShimmer extends StatefulWidget {
  final ThemeData theme;
  const _LoadingShimmer({required this.theme});

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, _) {
        final shimmerColor = widget.theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5 + _animation.value * 0.5);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            // Podium placeholder
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(8, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 64,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            )),
          ],
        );
      },
    );
  }
}
