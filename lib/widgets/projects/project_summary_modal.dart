// ============================================================
// RAWBY — Project Summary Modal
// Post-submit reflection: how, what changed, rating, comparison, feeling
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_session.dart';
import '../../providers/user_session_provider.dart';

class ProjectSummaryModal extends ConsumerStatefulWidget {
  final String weekStart; // Used as the summary ID

  const ProjectSummaryModal({
    super.key,
    required this.weekStart,
  });

  @override
  ConsumerState<ProjectSummaryModal> createState() => _ProjectSummaryModalState();
}

class _ProjectSummaryModalState extends ConsumerState<ProjectSummaryModal> {
  final _howController = TextEditingController();
  final _whatController = TextEditingController();
  final _feelingController = TextEditingController();
  int _rating = 5;
  String _comparison = 'same';
  bool _submitting = false;

  @override
  void dispose() {
    _howController.dispose();
    _whatController.dispose();
    _feelingController.dispose();
    super.dispose();
  }

  void _submit() {
    final summary = ProjectSummary(
      id: widget.weekStart,
      howCreated: _howController.text.trim(),
      whatChanged: _whatController.text.trim(),
      rating: _rating,
      comparison: _comparison,
      feeling: _feelingController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    ref.read(userSessionProvider.notifier).saveProjectSummary(summary);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Reflection',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'How did it go? (optional)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // How did you create this?
              TextField(
                controller: _howController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'How did you create this project?',
                  hintText: 'Describe your process...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // What did you change?
              TextField(
                controller: _whatController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'What did you change or try differently?',
                  hintText: 'Any new techniques, gear, or approaches...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rating slider
              Text(
                'Rating: $_rating/10',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _rating.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_rating',
                onChanged: (v) => setState(() => _rating = v.round()),
              ),
              const SizedBox(height: 16),

              // Comparison dropdown
              Text(
                'Compared to previous work:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'better', label: Text('Better')),
                  ButtonSegment(value: 'same', label: Text('Same')),
                  ButtonSegment(value: 'worse', label: Text('Worse')),
                ],
                selected: {_comparison},
                onSelectionChanged: (v) => setState(() => _comparison = v.first),
              ),
              const SizedBox(height: 16),

              // How did you feel?
              TextField(
                controller: _feelingController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'How did you feel?',
                  hintText: 'Your emotional state during the project...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
