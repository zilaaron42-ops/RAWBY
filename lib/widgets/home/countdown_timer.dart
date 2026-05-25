// ============================================================
// RAWBY — Live Countdown Timer Widget
// Ticks every second to show remaining time until deadline
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime deadline;
  final Color accentColor;

  const CountdownTimer({
    super.key,
    required this.deadline,
    required this.accentColor,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.deadline.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = widget.deadline.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = _remaining.isNegative;
    final abs = _remaining.abs();
    final days = abs.inDays;
    final hours = abs.inHours % 24;
    final minutes = abs.inMinutes % 60;
    final seconds = abs.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (days > 0) _TimeUnit(value: days, label: 'd', color: widget.accentColor, theme: theme),
        if (days > 0) _Separator(color: widget.accentColor),
        _TimeUnit(value: hours, label: 'h', color: widget.accentColor, theme: theme),
        _Separator(color: widget.accentColor),
        _TimeUnit(value: minutes, label: 'm', color: widget.accentColor, theme: theme),
        _Separator(color: widget.accentColor),
        _TimeUnit(value: seconds, label: 's', color: widget.accentColor, theme: theme),
        if (isOverdue) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: RawbyPalette.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'OVERDUE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: RawbyPalette.danger,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final ThemeData theme;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  final Color color;

  const _Separator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 3, right: 3),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
