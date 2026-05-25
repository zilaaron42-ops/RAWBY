// ============================================================
// RAWBY — Skill Feedback Modal
// AI-powered practice plan generation based on history & stats
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class SkillFeedbackModal extends ConsumerStatefulWidget {
  const SkillFeedbackModal({super.key});

  @override
  ConsumerState<SkillFeedbackModal> createState() => _SkillFeedbackModalState();
}

class _SkillFeedbackModalState extends ConsumerState<SkillFeedbackModal> {
  bool _isGenerating = false;
  String? _error;
  String? _result;

  final _focusController = TextEditingController();
  final _notesController = TextEditingController();

  static const _focusAreas = [
    'cinematography',
    'editing',
    'sound_design',
    'color_grading',
    'storytelling',
    'directing',
  ];

  String _selectedFocus = 'editing';

  @override
  void dispose() {
    _focusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    final session = ref.read(userSessionProvider);
    final ai = session.aiSettings;

    setState(() {
      _isGenerating = true;
      _error = null;
      _result = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getSkillFeedback(
        provider: ai.provider,
        model: ai.model,
        focusArea: _selectedFocus,
        notes: _notesController.text,
        history: session.history.map((h) => h.toJson()).toList(),
        stats: {
          'totalLikes': session.totalLikes,
          'totalViews': session.totalViews,
          'completedWeeks': session.completedWeeks,
        },
      );

      final content = data['content'] as String? ?? 'No plan generated.';
      setState(() {
        _result = content;
        _isGenerating = false;
      });

      // Update session plan
      ref.read(userSessionProvider.notifier).updateSkillPlan(content);
    } catch (e) {
      setState(() {
        _error = 'Failed to generate plan. Please try again.';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Practice Plan',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_result != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _result!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Got it!'),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                Text('Focus Area', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFocus,
                    isExpanded: true,
                    items: _focusAreas.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (v) => setState(() => _selectedFocus = v!),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Specific Notes (Optional)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Struggling with lighting in dark rooms',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generatePlan,
                    icon: _isGenerating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isGenerating ? 'Analyzing...' : 'Generate Weekly Plan'),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
