// ============================================================
// RAWBY — Settings Screen (Redesigned with sections)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_session_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final prefs = session.preferences;
    final ai = session.aiSettings;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── SECTION 1: Account ──────────────────────────────────
          _SectionHeader(title: 'Account', icon: Icons.person_outline),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.alternate_email,
            title: 'Username',
            subtitle: '@${session.username}',
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: session.email.isNotEmpty ? session.email : 'Not set',
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.badge_outlined,
            title: 'Display Name',
            subtitle: session.displayName.isNotEmpty ? session.displayName : session.username,
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Bio',
            subtitle: prefs.bio.isNotEmpty ? prefs.bio : 'Add a short bio...',
            onTap: () => _showTextInput(context, ref, 'Bio', prefs.bio, (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(bio: v));
            }),
          ),

          const SizedBox(height: 28),

          // ── SECTION 2: Preferences ──────────────────────────────
          _SectionHeader(title: 'Preferences', icon: Icons.tune_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.language,
            title: 'Prompt Language',
            subtitle: _langLabel(prefs.promptLanguage),
            onTap: () => _showLanguagePicker(context, ref, prefs),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Seasonal Prompts',
            subtitle: 'Adapt prompts to current season & weather',
            trailing: Switch(
              value: prefs.seasonalPrompts,
              onChanged: (v) {
                ref.read(userSessionProvider.notifier).updatePreferences(
                      prefs.copyWith(seasonalPrompts: v),
                    );
              },
            ),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Region',
            subtitle: prefs.region.isNotEmpty ? prefs.region : 'Not set',
            onTap: () => _showRegionPicker(context, ref, prefs),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.movie_filter_outlined,
            title: 'Filmmaking Goal',
            subtitle: prefs.filmmakingGoal.isNotEmpty ? prefs.filmmakingGoal : 'Not set',
            onTap: () => _showGoalPicker(context, ref, prefs),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.videocam_outlined,
            title: 'Content Type',
            subtitle: prefs.contentType.isNotEmpty ? prefs.contentType : 'Not set',
            onTap: () => _showContentTypePicker(context, ref, prefs),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.event,
            title: 'Cycle Start Day',
            subtitle: prefs.cycleDay,
            onTap: () => _showCycleDayPicker(context, ref, prefs),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.access_time,
            title: 'Timezone',
            subtitle: prefs.timezone,
          ),

          // Manual likes info (for regular users)
          if (!session.isAdmin) ...[
            const SizedBox(height: 6),
            _SettingsTile(
              icon: Icons.favorite_border,
              title: 'Manual Likes Entry',
              subtitle: 'Record likes after the 7-day unlock period',
              trailing: session.submittedAt != null &&
                      DateTime.now().isAfter(
                          DateTime.parse(session.submittedAt!).add(const Duration(days: 7)))
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RawbyPalette.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: RawbyPalette.success,
                        ),
                      ),
                    )
                  : null,
            ),
          ],

          const SizedBox(height: 28),

          // ── SECTION 3: Notifications ────────────────────────────
          _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.push_pin_outlined,
            title: 'Push Notifications',
            subtitle: 'Deadline reminders and stats alerts',
            trailing: Switch(
              value: true, // placeholder
              onChanged: (v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon')),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 4: Theme & Accent ───────────────────────────
          _SectionHeader(title: 'Theme & Accent', icon: Icons.palette_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: prefs.theme == 'dark',
              onChanged: (v) {
                ref.read(userSessionProvider.notifier).updatePreferences(
                      prefs.copyWith(theme: v ? 'dark' : 'light'),
                    );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Accent Color', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _AccentChip(
                label: 'Green',
                color: RawbyPalette.green500,
                selected: prefs.accent == 'green',
                onTap: () => ref.read(userSessionProvider.notifier).updatePreferences(
                      prefs.copyWith(accent: 'green'),
                    ),
              ),
              const SizedBox(width: 8),
              _AccentChip(
                label: 'Grey',
                color: RawbyPalette.grey500,
                selected: prefs.accent == 'grey',
                onTap: () => ref.read(userSessionProvider.notifier).updatePreferences(
                      prefs.copyWith(accent: 'grey'),
                    ),
              ),
              const SizedBox(width: 8),
              _AccentChip(
                label: 'Basic',
                color: RawbyPalette.basic500,
                selected: prefs.accent == 'basic',
                onTap: () => ref.read(userSessionProvider.notifier).updatePreferences(
                      prefs.copyWith(accent: 'basic'),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── SECTION 5: AI Settings ──────────────────────────────
          _SectionHeader(title: 'AI Settings', icon: Icons.auto_awesome_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.auto_fix_high,
            title: 'Auto-generate prompts',
            subtitle: 'Generate prompts automatically each week',
            trailing: Switch(
              value: ai.autoGenerate,
              onChanged: (v) {
                ref.read(userSessionProvider.notifier).updateAiSettings(
                      ai.copyWith(autoGenerate: v),
                    );
              },
            ),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: 'AI Provider',
            subtitle: _providerLabel(ai.provider),
            onTap: () => _showProviderPicker(context, ref, ai),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.memory,
            title: 'Model',
            subtitle: ai.model,
            onTap: () => _showModelPicker(context, ref, ai),
          ),

          const SizedBox(height: 28),

          // ── SECTION 6: Social & Profile Visibility ──────────────
          _SectionHeader(title: 'Social & Profile Visibility', icon: Icons.share_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram Handle',
            subtitle: prefs.instagramHandle.isNotEmpty ? '@${prefs.instagramHandle}' : 'Not set',
            onTap: () => _showTextInput(context, ref, 'Instagram Handle', prefs.instagramHandle, (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(instagramHandle: v));
            }),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'YouTube Channel',
            subtitle: prefs.youtubeHandle.isNotEmpty ? prefs.youtubeHandle : 'Not set',
            onTap: () => _showTextInput(context, ref, 'YouTube Channel', prefs.youtubeHandle, (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(youtubeHandle: v));
            }),
          ),

          // Admin: Instagram auto-fetch
          if (session.isAdmin) ...[
            const SizedBox(height: 6),
            _SettingsTile(
              icon: Icons.sync,
              title: 'Auto-fetch Instagram Stats',
              subtitle: 'Fetch like counts from Instagram Reel URLs via API',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Instagram API integration coming soon — admin feature'),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Control what others see on your public profile',
              style: theme.textTheme.bodySmall,
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Bio',
            subtitle: 'Your short bio text',
            trailing: Switch(value: prefs.showBio, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showBio: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.score_outlined,
            title: 'Score & Rank',
            subtitle: 'Total score and rank badge',
            trailing: Switch(value: prefs.showScore, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showScore: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Streak',
            subtitle: 'Weekly project streak',
            trailing: Switch(value: prefs.showStreak, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showStreak: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.bar_chart_outlined,
            title: 'Engagement Stats',
            subtitle: 'Total likes, views, and averages',
            trailing: Switch(value: prefs.showEngagement, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showEngagement: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.history,
            title: 'Project History',
            subtitle: 'Past projects and scores',
            trailing: Switch(value: prefs.showHistory, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showHistory: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.article_outlined,
            title: 'Past Prompts',
            subtitle: 'Prompt text from completed projects',
            trailing: Switch(value: prefs.showPrompts, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showPrompts: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'Earned badges and progress',
            trailing: Switch(value: prefs.showAchievements, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showAchievements: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.camera_outlined,
            title: 'Gear',
            subtitle: 'Equipment and subscriptions',
            trailing: Switch(value: prefs.showGear, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showGear: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            subtitle: 'Show your Instagram handle',
            trailing: Switch(value: prefs.showInstagram, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showInstagram: v));
            }),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'YouTube',
            subtitle: 'Show your YouTube channel',
            trailing: Switch(value: prefs.showYoutube, onChanged: (v) {
              ref.read(userSessionProvider.notifier).updatePreferences(prefs.copyWith(showYoutube: v));
            }),
          ),

          const SizedBox(height: 28),

          // ── SECTION 7: Subscription ─────────────────────────────
          _SectionHeader(title: 'Subscription', icon: Icons.workspace_premium_outlined),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      session.isPaid ? Icons.workspace_premium : Icons.lock_outline,
                      color: session.isPaid ? RawbyPalette.warning : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.isPaid
                          ? session.isOnTrial
                              ? 'Rawby Pro (Trial)'
                              : 'Rawby Pro'
                          : 'Free Tier',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (session.isOnTrial && session.trialStartedAt != null)
                  Text(
                    'Trial expires: ${_formatTrialExpiry(session.trialStartedAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (session.isFree)
                  Text(
                    'Upgrade to unlock all features',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                if (session.isFree)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subscription coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: const Text('Upgrade to Pro — 7 Days Free'),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 8: Danger Zone ──────────────────────────────
          _SectionHeader(title: 'Danger Zone', icon: Icons.warning_amber_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            titleColor: theme.colorScheme.error,
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            titleColor: theme.colorScheme.error,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _formatTrialExpiry(String trialStartedAt) {
    final start = DateTime.parse(trialStartedAt);
    final expiry = start.add(const Duration(days: 7));
    return '${expiry.day}/${expiry.month}/${expiry.year}';
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'groq': return 'Groq (Fast, Free)';
      case 'openai': return 'OpenAI (GPT)';
      case 'anthropic': return 'Anthropic (Claude)';
      case 'google': return 'Google (Gemini)';
      default: return provider;
    }
  }

  // ── Pickers ─────────────────────────────────────────────────

  void _showProviderPicker(BuildContext context, WidgetRef ref, dynamic ai) {
    _showOptionSheet(context, 'AI Provider', [
      _Option('groq', 'Groq', 'Fast & free — Llama models'),
      _Option('openai', 'OpenAI', 'GPT-4o and variants'),
      _Option('anthropic', 'Anthropic', 'Claude Sonnet & Opus'),
      _Option('google', 'Google', 'Gemini 2.0 Flash & 2.5 Pro'),
    ], ai.provider, (v) {
      String model;
      switch (v) {
        case 'groq': model = 'llama-3.3-70b-versatile'; break;
        case 'openai': model = 'gpt-4o'; break;
        case 'anthropic': model = 'claude-sonnet-4-6'; break;
        case 'google': model = 'gemini-2.0-flash'; break;
        default: model = 'llama-3.3-70b-versatile';
      }
      ref.read(userSessionProvider.notifier).updateAiSettings(
            ai.copyWith(provider: v, model: model),
          );
    });
  }

  void _showModelPicker(BuildContext context, WidgetRef ref, dynamic ai) {
    final List<_Option> models;
    switch (ai.provider) {
      case 'openai':
        models = [
          _Option('gpt-4o', 'GPT-4o', 'Recommended, best quality'),
          _Option('gpt-4-turbo', 'GPT-4 Turbo', 'Previous best'),
          _Option('gpt-4o-mini', 'GPT-4o Mini', 'Faster, cheaper'),
        ];
        break;
      case 'anthropic':
        models = [
          _Option('claude-sonnet-4-6', 'Claude Sonnet 4.6', 'Balanced & smart'),
          _Option('claude-opus-4-7', 'Claude Opus 4.7', 'Most capable'),
          _Option('claude-haiku-4-5-20251001', 'Claude Haiku 4.5', 'Fast & efficient'),
        ];
        break;
      case 'google':
        models = [
          _Option('gemini-2.0-flash', 'Gemini 2.0 Flash', 'Fast & capable'),
          _Option('gemini-2.5-pro-preview-06-05', 'Gemini 2.5 Pro', 'Most capable'),
        ];
        break;
      case 'groq':
      default:
        models = [
          _Option('llama-3.3-70b-versatile', 'Llama 3.3 70B', 'Recommended'),
          _Option('mixtral-8x7b-32768', 'Mixtral 8x7B', 'Long context'),
          _Option('llama-3.1-8b-instant', 'Llama 3.1 8B', 'Fastest'),
        ];
    }
    _showOptionSheet(context, 'Model', models, ai.model, (v) {
      ref.read(userSessionProvider.notifier).updateAiSettings(
            ai.copyWith(model: v),
          );
    });
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, dynamic prefs) {
    _showOptionSheet(context, 'Prompt Language', [
      _Option('en', 'English', ''),
      _Option('hu', 'Magyar', ''),
      _Option('de', 'Deutsch', ''),
      _Option('es', 'Español', ''),
      _Option('fr', 'Français', ''),
      _Option('ja', 'Japanese', ''),
    ], prefs.promptLanguage, (v) {
      ref.read(userSessionProvider.notifier).updatePreferences(
            prefs.copyWith(promptLanguage: v),
          );
    });
  }

  void _showRegionPicker(BuildContext context, WidgetRef ref, dynamic prefs) {
    _showOptionSheet(context, 'Region', [
      _Option('Northern Europe', 'Northern Europe', ''),
      _Option('Central Europe', 'Central Europe', ''),
      _Option('Southern Europe', 'Southern Europe', ''),
      _Option('US East', 'US East', ''),
      _Option('US West', 'US West', ''),
      _Option('US South', 'US South', ''),
      _Option('Asia', 'Asia', ''),
      _Option('Other', 'Other', ''),
    ], prefs.region, (v) {
      ref.read(userSessionProvider.notifier).updatePreferences(
            prefs.copyWith(region: v),
          );
    });
  }

  void _showGoalPicker(BuildContext context, WidgetRef ref, dynamic prefs) {
    _showOptionSheet(context, 'Filmmaking Goal', [
      _Option('hobby', 'Hobby Filmmaker', 'Fun & creative expression'),
      _Option('youtube', 'YouTube Creator', 'Build an audience'),
      _Option('cinematic', 'Cinematic Storytelling', 'Narrative films'),
      _Option('documentary', 'Documentary', 'Real-world stories'),
      _Option('commercial', 'Commercial Work', 'Client projects'),
      _Option('music_video', 'Music Videos', 'Visual music art'),
    ], prefs.filmmakingGoal, (v) {
      ref.read(userSessionProvider.notifier).updatePreferences(
            prefs.copyWith(filmmakingGoal: v),
          );
    });
  }

  void _showContentTypePicker(BuildContext context, WidgetRef ref, dynamic prefs) {
    _showOptionSheet(context, 'Content Type', [
      _Option('short_film', 'Short Film', '1-10 min narrative'),
      _Option('reel', 'Reel / Short', 'Under 60 seconds'),
      _Option('vlog', 'Vlog', 'Personal video blog'),
      _Option('cinematic_broll', 'Cinematic B-Roll', 'Visual storytelling'),
      _Option('tutorial', 'Tutorial', 'Educational content'),
      _Option('mixed', 'Mixed', 'All of the above'),
    ], prefs.contentType, (v) {
      ref.read(userSessionProvider.notifier).updatePreferences(
            prefs.copyWith(contentType: v),
          );
    });
  }

  void _showCycleDayPicker(BuildContext context, WidgetRef ref, dynamic prefs) {
    _showOptionSheet(context, 'Cycle Start Day', [
      _Option('Monday', 'Monday', ''),
      _Option('Tuesday', 'Tuesday', ''),
      _Option('Wednesday', 'Wednesday', ''),
      _Option('Thursday', 'Thursday', ''),
      _Option('Friday', 'Friday', ''),
      _Option('Saturday', 'Saturday', ''),
      _Option('Sunday', 'Sunday', ''),
    ], prefs.cycleDay, (v) {
      ref.read(userSessionProvider.notifier).updatePreferences(
            prefs.copyWith(cycleDay: v),
          );
    });
  }

  void _showOptionSheet(
    BuildContext context,
    String title,
    List<_Option> options,
    String currentValue,
    void Function(String) onSelect,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...options.map((opt) => ListTile(
                  title: Text(opt.label),
                  subtitle: opt.desc.isNotEmpty ? Text(opt.desc, style: theme.textTheme.bodySmall) : null,
                  trailing: opt.value == currentValue
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
                      : null,
                  onTap: () {
                    onSelect(opt.value);
                    Navigator.pop(ctx);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showTextInput(BuildContext context, WidgetRef ref, String title, String current, void Function(String) onSave) {
    final controller = TextEditingController(text: current);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Enter $title'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onSave(controller.text.trim());
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Your data is saved. You can log back in anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Log Out', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(userSessionProvider.notifier).logout();
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'To delete your account, please contact support at support@rawby.app. '
          'Account deletion is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _langLabel(String code) {
    switch (code) {
      case 'hu': return 'Magyar';
      case 'de': return 'Deutsch';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'ja': return 'Japanese';
      default: return 'English';
    }
  }
}

// ── Reusable Widgets ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Divider(
          color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: titleColor ?? theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w500,
                    )),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (trailing != null) trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccentChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? color : theme.colorScheme.onSurface,
            )),
          ],
        ),
      ),
    );
  }
}

class _Option {
  final String value;
  final String label;
  final String desc;
  const _Option(this.value, this.label, this.desc);
}
