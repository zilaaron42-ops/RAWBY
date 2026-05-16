// ============================================================
// RAWBY — Admin Screen (Full Implementation)
// Admin dashboard for managing global updates, feedback, IG stats.
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/user_session_provider.dart";
import "../providers/router_provider.dart";
import "../services/api_service.dart";
import "../widgets/admin/global_updates_modal.dart";
import "../widgets/admin/instagram_stats_modal.dart";
import "../widgets/admin/admin_prompt_builder_modal.dart";

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);

    if (!session.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text("Admin access only", style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Admin Panel", style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text("Manage the platform", style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),

            // ── Global Updates ───────────────────────────────────
            _AdminSection(
              icon: Icons.campaign_outlined,
              title: "Global Updates",
              subtitle: "Post announcements to all users",
              onTap: () => _showGlobalUpdatesModal(context, ref),
              theme: theme,
            ),

            // ── Feedback Wall ────────────────────────────────────
            _AdminSection(
              icon: Icons.feedback_outlined,
              title: "Feedback Wall",
              subtitle: "View and manage user feedback",
              onTap: () => context.go(Routes.feedbackWall),
              theme: theme,
            ),

            // ── Prompt Builder ───────────────────────────────────
            _AdminSection(
              icon: Icons.edit_note_rounded,
              title: "Prompt Builder",
              subtitle: "Create custom challenges for distribution",
              onTap: () => _showPromptBuilder(context, ref),
              theme: theme,
              accentColor: theme.colorScheme.tertiary,
            ),

            // ── Instagram Stats ──────────────────────────────────
            _AdminSection(
              icon: Icons.camera_alt_outlined,
              title: "Instagram Stats",
              subtitle: "Fetch likes from Reel URLs",
              onTap: () => _showInstagramStatsModal(context, ref),
              theme: theme,
            ),

            // ── User Management (super-admin only) ───────────────
            if (session.isSuperAdmin) ...[
              _AdminSection(
                icon: Icons.admin_panel_settings,
                title: "User Management",
                subtitle: "Full control over users and roles",
                onTap: () => _showUserManagement(context, ref),
                theme: theme,
              ),
            ] else ...[
              _AdminSection(
                icon: Icons.people_outline,
                title: "Users",
                subtitle: "View all registered users",
                onTap: () => _showUserManagement(context, ref),
                theme: theme,
              ),
            ],

            // ── Auto Instagram Fetch (admin) ─────────────────────
            if (session.isSuperAdmin)
              _AdminSection(
                icon: Icons.auto_awesome,
                title: "Auto Instagram Fetch",
                subtitle: "Fetch likes for all pending submissions",
                onTap: () => _autoFetchInstagramLikes(context, ref),
                theme: theme,
              ),

            // ── Force Sync ───────────────────────────────────────
            _AdminSection(
              icon: Icons.sync_outlined,
              title: "Force Sync",
              subtitle: "Push current state to backend immediately",
              onTap: () {
                ref.read(userSessionProvider.notifier).saveNow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sync triggered")),
                );
              },
              theme: theme,
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                session.isSuperAdmin ? "— Super Admin: zaron.films —" : "— Admin panel —",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGlobalUpdatesModal(BuildContext context, WidgetRef ref) async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlobalUpdatesModal(),
    );
    if (posted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Global update posted successfully!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showPromptBuilder(BuildContext context, WidgetRef ref) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminPromptBuilderModal(),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prompt saved to draft collection.")),
      );
    }
  }

  Future<void> _showInstagramStatsModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InstagramStatsModal(),
    );
  }

  Future<void> _showUserManagement(BuildContext context, WidgetRef ref) async {
    final session = ref.read(userSessionProvider);
    final api = ref.read(apiServiceProvider);
    final theme = Theme.of(context);

    try {
      final users = await api.getUsers();
      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Users (${users.length})",
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final user = users[i] as Map<String, dynamic>;
                        final username = user['username'] ?? '';
                        final isAdmin = user['isAdmin'] == true ||
                            username == 'zaron.films';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAdmin
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              size: 18,
                              color: isAdmin
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            username,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isAdmin
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            user['email'] as String? ?? '',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: session.isSuperAdmin &&
                                  username != 'zaron.films'
                              ? PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant),
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'toggle_admin':
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              "Admin toggle for $username — backend endpoint needed"),
                                        ));
                                        break;
                                      case 'view':
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              "View profile: $username"),
                                        ));
                                        break;
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.visibility,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text('View',
                                              style:
                                                  theme.textTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_admin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isAdmin
                                                ? Icons.person_remove
                                                : Icons.admin_panel_settings,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isAdmin
                                                ? 'Remove Admin'
                                                : 'Make Admin',
                                            style:
                                                theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch users: $e")),
        );
      }
    }
  }

  Future<void> _autoFetchInstagramLikes(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiServiceProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fetching Instagram data...")),
    );

    try {
      final result = await api.getInstagramRecent(limit: 500, insights: true);
      final posts = result['data'] as List<dynamic>? ?? [];
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fetched ${posts.length} posts from Instagram API"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Instagram fetch failed: $e")),
        );
      }
    }
  }
}

// ── Admin Section Widget ─────────────────────────────────────

class _AdminSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final ThemeData theme;
  final Color? accentColor;

  const _AdminSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        tileColor: theme.colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}
