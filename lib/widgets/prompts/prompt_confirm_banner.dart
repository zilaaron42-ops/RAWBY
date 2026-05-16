// ============================================================
// RAWBY — Prompt Confirmation Banner
// Shows 1-hour countdown after prompt selection, with
// confirm / cancel buttons
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';

class PromptConfirmBanner extends ConsumerStatefulWidget {
  const PromptConfirmBanner({super.key});

  @override
  ConsumerState<PromptConfirmBanner> createState() => _PromptConfirmBannerState();
}

class _PromptConfirmBannerState extends ConsumerState<PromptConfirmBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    // Only show when prompt is selected but NOT yet confirmed
    if (session.selectedPromptId == null || session.isPromptConfirmed) {
      return const SizedBox.shrink();
    }

    final window = session.projectStartWindow;
    if (window == null) return const SizedBox.shrink();

    final remaining = window.expiresAt.difference(DateTime.now());
    final expired = remaining.isNegative;

    if (expired) {
      // Auto-cancel after expiry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userSessionProvider.notifier).cancelPromptSelection();
      });
    }

    final prompt = session.prompts.isNotEmpty ? session.prompts.first : null;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired
            ? theme.colorScheme.error.withAlpha(25)
            : theme.colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expired
              ? theme.colorScheme.error.withAlpha(80)
              : theme.colorScheme.primary.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                expired ? Icons.timer_off : Icons.timer_outlined,
                size: 18,
                color: expired ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                expired ? 'Time expired!' : 'Confirm within $timeStr',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: expired ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (prompt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${prompt.level} — ${prompt.text}',
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(userSessionProvider.notifier).cancelPromptSelection();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(color: theme.colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: expired
                      ? null
                      : () {
                          ref.read(userSessionProvider.notifier).confirmPrompt();
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
