// ============================================================
// RAWBY — Settings
// AI provider/model, theme, accent, region, season, language.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_session_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _regions = [
    'Northern Europe',
    'Central Europe',
    'Southern Europe',
    'US Northeast',
    'US South',
    'US West',
    'East Asia',
    'Southeast Asia',
    'Australia',
    'Other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final prefs = session.preferences;
    final theme = Theme.of(context);

    return Scaffold(
      body: AuraBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Text(
                    'Settings',
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(
                  [
                    // ── AI Engine ─────────────────────────────────────
                    const SectionHeader(
                      title: 'AI Engine',
                      subtitle:
                          'Used for prompt generation and the Aurora assistant',
                      padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
                    ),
                    GlassCard(
                      child: Column(
                        children: [
                          _AiProviderTile(
                            provider: 'groq',
                            label: 'Groq · llama-3.3-70b',
                            subtitle: 'Fast, private, always-on',
                            icon: Icons.bolt,
                            selected: session.aiSettings.provider == 'groq',
                            onTap: () => ref.read(userSessionProvider.notifier)
                                .updateAiSettings(session.aiSettings.copyWith(provider: 'groq')),
                          ),
                          if (session.isAdmin) ...[
                            const Divider(height: 1),
                            _AiProviderTile(
                              provider: 'claude',
                              label: 'Claude · Sonnet 4.6',
                              subtitle: 'Admin only · Anthropic',
                              icon: Icons.auto_awesome,
                              selected: session.aiSettings.provider == 'claude',
                              onTap: () => ref.read(userSessionProvider.notifier)
                                  .updateAiSettings(session.aiSettings.copyWith(provider: 'claude')),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05),

                    // ── Appearance ────────────────────────────────────
                    const SectionHeader(title: 'Appearance'),
                    GlassCard(
                      child: Column(
                        children: [
                          _Label('Theme'),
                          const SizedBox(height: 8),
                          _PillSelector(
                            options: const ['dark', 'light'],
                            labels: const ['Dark', 'Light'],
                            current: prefs.theme,
                            onChange: (v) {
                              ref
                                  .read(userSessionProvider.notifier)
                                  .updatePreferences(
                                      prefs.copyWith(theme: v));
                            },
                          ),
                          const SizedBox(height: 16),
                          _Label('Accent'),
                          const SizedBox(height: 8),
                          _AccentSelector(
                            current: prefs.accent,
                            onChange: (v) {
                              ref
                                  .read(userSessionProvider.notifier)
                                  .updatePreferences(
                                      prefs.copyWith(accent: v));
                            },
                          ),
                        ],
                      ),
                    ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.05),

                    // ── Story Context ─────────────────────────────────
                    const SectionHeader(
                      title: 'Story Context',
                      subtitle: 'Feeds into every AI prompt request',
                    ),
                    GlassCard(
                      child: Column(
                        children: [
                          _Label('Region'),
                          const SizedBox(height: 6),
                          _ModelDropdown(
                            value: prefs.region.isEmpty
                                ? _regions[1]
                                : prefs.region,
                            items: _regions,
                            onChange: (v) {
                              if (v == null) return;
                              ref
                                  .read(userSessionProvider.notifier)
                                  .updatePreferences(
                                      prefs.copyWith(region: v));
                            },
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Seasonal prompts',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                                'One of three prompts adapts to current season'),
                            value: prefs.seasonalPrompts,
                            onChanged: (v) {
                              ref
                                  .read(userSessionProvider.notifier)
                                  .updatePreferences(
                                      prefs.copyWith(seasonalPrompts: v));
                            },
                          ),
                          const SizedBox(height: 14),
                          const _Label('Cycle Start Day'),
                          const SizedBox(height: 6),
                          _ModelDropdown(
                            value: prefs.cycleDay.isEmpty ? 'Friday' : prefs.cycleDay,
                            items: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
                            onChange: (v) {
                              if (v == null) return;
                              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(cycleDay: v));
                            },
                          ),
                        ],
                      ),
                    ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.05),

                    // ── Suggestions ──────────────────────────────────
                    const SectionHeader(
                      title: 'Suggestions',
                      subtitle: 'Send feature ideas or feedback to the team',
                    ),
                    _SuggestionSection(isAdmin: session.isAdmin)
                        .animate(delay: 240.ms).fadeIn().slideY(begin: 0.05),

                    // ── Profile ───────────────────────────────────────────────
                    const SectionHeader(
                      title: 'Profile',
                      subtitle: 'Edit your public info and control what others see',
                    ),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Instagram Handle'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: TextEditingController(text: prefs.instagramHandle)
                              ..selection = TextSelection.collapsed(offset: prefs.instagramHandle.length),
                            decoration: const InputDecoration(hintText: '@your_handle'),
                            onChanged: (v) {
                              ref.read(userSessionProvider.notifier).updatePreferences(
                                prefs.copyWith(instagramHandle: v.startsWith('@') ? v.substring(1) : v),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const _Label('Visible to others'),
                          const SizedBox(height: 4),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Score & rank'),
                            value: prefs.showScore,
                            onChanged: (v) => ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showScore: v)),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Streak'),
                            value: prefs.showStreak,
                            onChanged: (v) => ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showStreak: v)),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Engagement stats'),
                            value: prefs.showEngagement,
                            onChanged: (v) => ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showEngagement: v)),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Project history'),
                            value: prefs.showHistory,
                            onChanged: (v) => ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showHistory: v)),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Achievements'),
                            value: prefs.showAchievements,
                            onChanged: (v) => ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showAchievements: v)),
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),

                    // ── About ────────────────────────────────────────
                    const SectionHeader(title: 'About'),
                    GlassCard(
                      child: Column(
                        children: [
                          _InfoRow(
                              label: 'Username',
                              value: '@${session.username}'),
                          _InfoRow(
                              label: 'Role',
                              value: session.displayRole),
                          _InfoRow(
                              label: 'Total Score',
                              value: '${session.totalScore} pts'),
                          _InfoRow(
                              label: 'Rank',
                              value: session.currentRank.label),
                          const Divider(height: 20),
                          _InfoRow(label: 'App', value: 'RAWBY v1.0'),
                          _InfoRow(label: 'Contact', value: 'zaron.films@gmail.com'),
                        ],
                      ),
                    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModelDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChange;

  const _ModelDropdown({
    required this.value,
    required this.items,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          icon: Icon(Icons.expand_more,
              color: theme.colorScheme.onSurfaceVariant, size: 20),
          style: theme.textTheme.bodyMedium,
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(i, style: theme.textTheme.bodyMedium),
                  ))
              .toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}

class _PillSelector extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String current;
  final ValueChanged<String> onChange;

  const _PillSelector({
    required this.options,
    required this.labels,
    required this.current,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = options[i] == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: active
                      ? LinearGradient(colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ])
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AccentSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChange;

  const _AccentSelector({required this.current, required this.onChange});

  static const _accents = [
    {'key': 'cinema', 'name': 'Cinema', 'color': RawbyPalette.cinema500},
    {'key': 'green', 'name': 'Forest', 'color': RawbyPalette.green500},
    {'key': 'basic', 'name': 'Sepia', 'color': RawbyPalette.basic500},
    {'key': 'grey', 'name': 'Mono', 'color': RawbyPalette.grey500},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _accents.map((a) {
        final selected = a['key'] == current;
        return GestureDetector(
          onTap: () => onChange(a['key'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? (a['color'] as Color).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: a['color'] as Color,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: a['color'] as Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (a['color'] as Color).withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  a['name'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Suggestion Section ─────────────────────────────────────────

class _SuggestionSection extends ConsumerStatefulWidget {
  final bool isAdmin;
  const _SuggestionSection({required this.isAdmin});

  @override
  ConsumerState<_SuggestionSection> createState() => _SuggestionSectionState();
}

class _SuggestionSectionState extends ConsumerState<_SuggestionSection> {
  final _ctrl = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final list = widget.isAdmin
          ? await api.getAllSuggestions()
          : await api.getMySuggestions();
      setState(() { _suggestions = list; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).submitSuggestion(text);
      _ctrl.clear();
      await _load();
    } catch (e) {
      setState(() => _error = 'Failed to send. Try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _reply(String id) async {
    final replyCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply'),
        content: TextField(
          controller: replyCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Your reply...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed == true && replyCtrl.text.trim().isNotEmpty) {
      await ref.read(apiServiceProvider).replySuggestion(id, replyCtrl.text.trim());
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isAdmin) ...[
            TextField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 800,
              decoration: InputDecoration(
                hintText: 'Your suggestion or feature request...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            GradientButton(
              icon: Icons.send_outlined,
              label: _submitting ? 'Sending...' : 'Send suggestion',
              loading: _submitting,
              onTap: _submitting ? null : _submit,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            widget.isAdmin ? 'All suggestions' : 'Your submissions',
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_suggestions.isEmpty)
            Text('No suggestions yet.', style: theme.textTheme.bodySmall)
          else
            ..._suggestions.map((s) {
              final m = s as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isAdmin)
                      Text('@${m['username'] ?? ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                    Text(m['text'] as String? ?? '', style: theme.textTheme.bodyMedium),
                    if (m['adminReply'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.reply, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(m['adminReply'] as String, style: theme.textTheme.bodySmall)),
                          ],
                        ),
                      ),
                    ],
                    if (widget.isAdmin && m['adminReply'] == null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _reply(m['id'] as String),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Reply'),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AiProviderTile extends StatelessWidget {
  final String provider;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AiProviderTile({
    required this.provider,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary)
            else
              Icon(Icons.radio_button_unchecked, size: 18, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
