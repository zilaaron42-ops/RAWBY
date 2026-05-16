// ============================================================
// RAWBY — Feedback Wall Screen
// Admin views, manages, and deletes user feedback.
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers/user_session_provider.dart";
import "../services/api_service.dart";

class FeedbackWallScreen extends ConsumerStatefulWidget {
  const FeedbackWallScreen({super.key});

  @override
  ConsumerState<FeedbackWallScreen> createState() => _FeedbackWallScreenState();
}

class _FeedbackWallScreenState extends ConsumerState<FeedbackWallScreen> {
  List<dynamic> _feedback = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getFeedback();
      setState(() {
        _feedback = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load feedback.";
        _loading = false;
      });
    }
  }

  Future<void> _deleteFeedback(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteFeedback(id);
      _loadFeedback(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete feedback: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Feedback?"),
        content: const Text("Are you sure you want to delete this feedback?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Delete",
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteFeedback(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);

    if (!session.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Feedback Wall")),
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
      appBar: AppBar(
        title: const Text("Feedback Wall"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeedback,
        color: theme.colorScheme.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadFeedback,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : _feedback.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.feedback_outlined, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text("No feedback yet", style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              "Users can submit suggestions from the Profile screen.",
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _feedback.length,
                        itemBuilder: (context, index) {
                          final item = _feedback[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item["title"] as String? ?? "No Title",
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      Text(
                                        item["category"] as String? ?? "General",
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        color: theme.colorScheme.error,
                                        onPressed: () => _confirmDelete(item["id"] as String),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item["body"] as String? ?? "",
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (item["user"] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      "From: @${item["user"]["username"]}",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
