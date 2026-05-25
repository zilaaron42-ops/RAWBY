// ============================================================
// RAWBY — Idea Bank
// Saved prompts grouped by level. Filter tags, search, swipe-
// to-delete, swipe-to-activate. AI Suggest pulls a recommended
// pick based on user prefs.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prompt_model.dart';
import '../providers/user_session_provider.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/prompts/prompt_card.dart';

class IdeaBankScreen extends ConsumerStatefulWidget {
  const IdeaBankScreen({super.key});

  @override
  ConsumerState<IdeaBankScreen> createState() => _IdeaBankScreenState();
}

class _IdeaBankScreenState extends ConsumerState<IdeaBankScreen> {
  String _filter = 'All';
  String _search = '';
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final saved = session.savedPrompts;

    final filtered = _applyFilters(saved);

    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: Column(
            children: [
              _HeaderBar(
                count: saved.length,
                onClear: saved.isEmpty
                    ? null
                    : () => _confirmClearAll(context, ref),
              ),
              if (saved.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: TextField(
                    controller: _searchCtl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search your bank',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchCtl.clear();
                                setState(() => _search = '');
                              },
                            ),
                    ),
                  ),
                ),
                _FilterChips(
                  filter: _filter,
                  onChange: (v) => setState(() => _filter = v),
                  counts: _counts(saved),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: saved.isEmpty
                    ? _Empty()
                    : filtered.isEmpty
                        ? _NoResults()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: filtered.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == 0) {
                                return _AiSuggestCard(saved: filtered);
                              }
                              final p = filtered[i - 1];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Dismissible(
                                  key: ValueKey(p.id),
                                  background: _SwipeBg(
                                    alignment: Alignment.centerLeft,
                                    color: theme.colorScheme.primary,
                                    icon: Icons.bolt,
                                    label: 'Activate',
                                  ),
                                  secondaryBackground: _SwipeBg(
                                    alignment: Alignment.centerRight,
                                    color: theme.colorScheme.error,
                                    icon: Icons.delete_outline,
                                    label: 'Remove',
                                  ),
                                  confirmDismiss: (dir) async {
                                    HapticFeedback.lightImpact();
                                    if (dir == DismissDirection.startToEnd) {
                                      _activate(p);
                                      return false;
                                    }
                                    return true;
                                  },
                                  onDismissed: (_) => ref
                                      .read(userSessionProvider.notifier)
                                      .removeSavedPrompt(p.id),
                                  child: PromptCard(
                                    prompt: p,
                                    index: i - 1,
                                    onChoose: () => _activate(p),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _counts(List<PromptModel> all) {
    final m = <String, int>{};
    for (final p in all) {
      m[p.level] = (m[p.level] ?? 0) + 1;
    }
    return m;
  }

  List<PromptModel> _applyFilters(List<PromptModel> all) {
    return all.where((p) {
      if (_filter != 'All' && p.level != _filter) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return p.text.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.inspiration.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final ad = a.savedAt;
        final bd = b.savedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
  }

  void _activate(PromptModel p) {
    ref.read(userSessionProvider.notifier).setPrompts([p]);
    ref.read(userSessionProvider.notifier).selectPrompt(p.id);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activated · ${p.level} (${p.points} pts)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Idea Bank?'),
        content:
            const Text('All saved prompts will be removed. Cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Clear all',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(userSessionProvider.notifier).clearSavedPrompts();
    }
  }
}

// ── Subcomponents ──────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final int count;
  final VoidCallback? onClear;

  const _HeaderBar({required this.count, this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Idea Bank',
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$count saved · swipe ➜ activate, ⬅ remove',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onClear != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onChange;
  final Map<String, int> counts;

  const _FilterChips({
    required this.filter,
    required this.onChange,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final levels = ['All', 'Sequence', 'Short Story', 'Story + Character'];
    final theme = Theme.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final l = levels[i];
          final active = filter == l;
          final n = l == 'All'
              ? counts.values.fold<int>(0, (a, b) => a + b)
              : (counts[l] ?? 0);
          return GestureDetector(
            onTap: () => onChange(l),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ])
                    : null,
                color:
                    active ? null : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : theme.colorScheme.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w800 : FontWeight.w600,
                      color: active
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (n > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.25)
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestCard extends ConsumerWidget {
  final List<PromptModel> saved;

  const _AiSuggestCard({required this.saved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (saved.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final session = ref.watch(userSessionProvider);
    final pick = _suggest(session, saved);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        gradient: [
          theme.colorScheme.primary.withValues(alpha: 0.14),
          theme.colorScheme.secondary.withValues(alpha: 0.06),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  'AURORA SUGGESTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.4,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                FilmTag(
                  label: pick.level,
                  gradient: LevelGradient.forLevel(pick.level),
                  fontSize: 9,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pick.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Based on your streak, region & recent activity.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                GradientButton(
                  label: 'Activate',
                  icon: Icons.bolt,
                  dense: true,
                  onTap: () {
                    ref
                        .read(userSessionProvider.notifier)
                        .setPrompts([pick]);
                    ref
                        .read(userSessionProvider.notifier)
                        .selectPrompt(pick.id);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.05),
    );
  }

  PromptModel _suggest(dynamic session, List<PromptModel> saved) {
    final streak = session.streak as int;
    String target;
    if (streak < 2) {
      target = 'Sequence';
    } else if (streak < 5) {
      target = 'Short Story';
    } else {
      target = 'Story + Character';
    }
    return saved.firstWhere(
      (p) => p.level == target,
      orElse: () => saved.first,
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border,
              size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Your bank is empty', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Tap the bookmark on any prompt\nto save it for later weeks.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _NoResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('No matches', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Try a different filter or search term.',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
