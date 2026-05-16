// ============================================================
// RAWBY — User Bar
// Injected at the top of every page.
// Shows: Name, Rank icon + label, Streak, Admin gear icon
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_session_provider.dart';
import '../providers/router_provider.dart';
import '../theme/app_colors.dart';

class UserBar extends ConsumerWidget {
  const UserBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rank = session.currentRank;
    final streak = session.streak;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? RawbyPalette.darkSurface : RawbyPalette.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank icon
          Text(
            rank.icon,
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),

          // Name + rank label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.displayName.isNotEmpty
                      ? session.displayName
                      : session.username,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  rank.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
            ),
            child: Text(
              '${session.totalScore} pts',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Streak badge
          if (streak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '$streak',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Menu button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.menu,
              color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            color: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 40),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go(Routes.profile);
                  break;
                case 'settings':
                  context.push(Routes.settings);
                  break;
                case 'admin':
                  context.go(Routes.admin);
                  break;
                case 'theme':
                  final prefs = session.preferences;
                  ref.read(userSessionProvider.notifier).updatePreferences(
                        prefs.copyWith(
                          theme: prefs.theme == 'dark' ? 'light' : 'dark',
                        ),
                      );
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 10),
                    Text('Profile', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 10),
                    Text('Settings', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Text(isDark ? 'Light Mode' : 'Dark Mode', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (session.isAdmin)
                PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('Admin', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
