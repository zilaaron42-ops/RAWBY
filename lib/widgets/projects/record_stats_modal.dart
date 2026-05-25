// ============================================================
// RAWBY — Record Stats Modal
// Unlocks 7 days after submission. User enters likes/views.
// Score is calculated and added to history.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/project_model.dart';
import '../../providers/user_session_provider.dart';
import '../../services/api_service.dart';
import '../../services/scoring_service.dart';
import '../../theme/app_colors.dart';

class RecordStatsModal extends ConsumerStatefulWidget {
  /// Pass a [pendingStats] to record stats for a past week.
  /// If null, records stats for the current week.
  final PendingStats? pendingStats;

  const RecordStatsModal({super.key, this.pendingStats});

  @override
  ConsumerState<RecordStatsModal> createState() => _RecordStatsModalState();
}

class _RecordStatsModalState extends ConsumerState<RecordStatsModal> {
  final _likesController = TextEditingController();
  final _viewsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _fetching = false;
  String? _fetchStatus;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing
    if (widget.pendingStats != null) {
      _likesController.text = widget.pendingStats!.likes > 0
          ? '${widget.pendingStats!.likes}'
          : '';
      _viewsController.text = widget.pendingStats!.views > 0
          ? '${widget.pendingStats!.views}'
          : '';
    }
  }

  String? get _reelUrl {
    if (widget.pendingStats != null) {
      return widget.pendingStats!.instagramUrl.isNotEmpty
          ? widget.pendingStats!.instagramUrl
          : null;
    }
    final session = ref.read(userSessionProvider);
    return session.instagramUrl.isNotEmpty ? session.instagramUrl : null;
  }

  Future<void> _autoFetch() async {
    final url = _reelUrl;
    if (url == null) return;
    setState(() {
      _fetching = true;
      _fetchStatus = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.fetchReelLikes(url);
      final likes = result['likes'] as int? ?? 0;
      final views = result['views'] as int? ?? 0;
      if (likes > 0 || views > 0) {
        setState(() {
          _likesController.text = '$likes';
          _viewsController.text = views > 0 ? '$views' : '';
          _fetchStatus = 'Fetched: $likes likes${views > 0 ? ', $views views' : ''}';
          _fetching = false;
        });
      } else {
        setState(() {
          _fetchStatus = result['message'] as String? ?? 'Could not auto-fetch — enter manually.';
          _fetching = false;
        });
      }
    } catch (_) {
      setState(() {
        _fetchStatus = 'Auto-fetch failed — enter stats manually.';
        _fetching = false;
      });
    }
  }

  @override
  void dispose() {
    _likesController.dispose();
    _viewsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final likes = int.tryParse(_likesController.text.trim()) ?? 0;
    final views = int.tryParse(_viewsController.text.trim()) ?? 0;

    if (widget.pendingStats != null) {
      ref.read(userSessionProvider.notifier).recordPendingStats(
            pendingId: widget.pendingStats!.id,
            likes: likes,
            views: views,
          );
    } else {
      ref.read(userSessionProvider.notifier).recordStats(
            likes: likes,
            views: views,
          );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine which data to show
    final pending = widget.pendingStats;
    final promptText = pending?.promptText ??
        (session.prompts.isNotEmpty ? session.prompts.first.text : '');
    final level = pending?.level ??
        (session.prompts.isNotEmpty ? session.prompts.first.level : 'Sequence');
    final points = pending?.points ??
        (session.prompts.isNotEmpty ? session.prompts.first.points : 10);
    final submittedAt = pending != null
        ? DateTime.tryParse(pending.submittedAt) ?? DateTime.now()
        : (session.submittedAt != null
            ? DateTime.tryParse(session.submittedAt!) ?? DateTime.now()
            : DateTime.now());
    final deadline = pending != null
        ? DateTime.tryParse(pending.deadline) ?? DateTime.now()
        : DateTime.tryParse(session.deadline) ?? DateTime.now();

    // Preview score
    final likesPreview = int.tryParse(_likesController.text.trim()) ?? 0;
    final previewScore = ScoringService.calculateScore(
      likes: likesPreview,
      promptPoints: points,
      submittedAt: submittedAt,
      deadline: deadline,
    );
    final multiplier = ScoringService.penaltyMultiplier(submittedAt, deadline);
    final isTestRun = ScoringService.isTestRun(submittedAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RawbyPalette.darkSurface : RawbyPalette.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record Stats', style: theme.textTheme.titleLarge),
                          Text(
                            'Stats are ready — enter your numbers',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Project summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            level == 'Sequence'
                                ? '🎞️'
                                : level == 'Short Story'
                                    ? '🎬'
                                    : '🎭',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$level · $points pts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isTestRun) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TEST RUN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (promptText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          promptText,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        ScoringService.penaltyLabel(submittedAt, deadline),
                        style: TextStyle(
                          fontSize: 11,
                          color: multiplier < 1.0
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Auto-fetch banner
                if (_reelUrl != null) ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _fetchStatus != null
                        ? Container(
                            key: const ValueKey('status'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _fetchStatus!.startsWith('Fetched')
                                  ? RawbyPalette.success.withValues(alpha: 0.08)
                                  : theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _fetchStatus!.startsWith('Fetched')
                                    ? RawbyPalette.success.withValues(alpha: 0.3)
                                    : theme.colorScheme.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _fetchStatus!.startsWith('Fetched')
                                      ? Icons.check_circle_outline
                                      : Icons.info_outline,
                                  size: 15,
                                  color: _fetchStatus!.startsWith('Fetched')
                                      ? RawbyPalette.success
                                      : theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _fetchStatus!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _fetchStatus!.startsWith('Fetched')
                                          ? RawbyPalette.success
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            key: const ValueKey('fetch-btn'),
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _fetching ? null : _autoFetch,
                              icon: _fetching
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download_outlined, size: 16),
                              label: Text(
                                _fetching ? 'Fetching from Instagram...' : 'Auto-fetch from Instagram',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Likes input
                Text('Instagram Likes', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _likesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 20,
                    ),
                    prefixIcon: const Icon(Icons.favorite_border, size: 18),
                    filled: true,
                    fillColor: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your like count (0 if none)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Views input
                Text('Views (optional)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _viewsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 20,
                    ),
                    prefixIcon: const Icon(Icons.play_circle_outline, size: 18),
                    filled: true,
                    fillColor: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Score preview
                if (likesPreview > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Score Preview',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTestRun ? '0 pts (test run)' : '$previewScore pts',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!isTestRun && multiplier < 1.0)
                          Text(
                            '$likesPreview × $points × ${multiplier}x penalty',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          )
                        else if (!isTestRun)
                          Text(
                            '$likesPreview likes × $points pts',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Stats',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
