// ============================================================
// RAWBY — Edit Subscription Modal
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';
import '../../models/gear_model.dart';
import '../../theme/app_colors.dart';

class EditSubscriptionModal extends ConsumerStatefulWidget {
  final Subscription sub;

  const EditSubscriptionModal({super.key, required this.sub});

  @override
  ConsumerState<EditSubscriptionModal> createState() =>
      _EditSubscriptionModalState();
}

class _EditSubscriptionModalState extends ConsumerState<EditSubscriptionModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _costController;
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late String _frequency;

  static const _categories = ['filming', 'editing', 'digital'];
  static const _frequencies = ['monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sub.name);
    _costController = TextEditingController(
      text: widget.sub.costHuf > 0 ? widget.sub.costHuf.toStringAsFixed(0) : '',
    );
    _category = widget.sub.category;
    _frequency = widget.sub.frequency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(userSessionProvider.notifier).editSubscription(
          subId: widget.sub.id,
          name: _nameController.text.trim(),
          costHuf: double.tryParse(_costController.text.trim()) ?? 0.0,
          frequency: _frequency,
          category: _category,
        );
    Navigator.of(context).pop(true);
  }

  void _delete() {
    ref.read(userSessionProvider.notifier).removeSubscription(widget.sub.id);
    Navigator.of(context).pop(true);
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
                        Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Edit Subscription',
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

                // Name
                Text('Subscription Name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  maxLength: 80,
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(hintText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Category
                Text('Category', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _categories
                      .map((c) => ButtonSegment(value: c, label: Text(c)))
                      .toList(),
                  selected: {_category},
                  onSelectionChanged: (v) => setState(() => _category = v.first),
                ),
                const SizedBox(height: 16),

                // Frequency
                Text('Frequency', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _frequencies
                      .map((f) => ButtonSegment(value: f, label: Text(f)))
                      .toList(),
                  selected: {_frequency},
                  onSelectionChanged: (v) => setState(() => _frequency = v.first),
                ),
                const SizedBox(height: 16),

                // Cost
                Text('Cost (HUF)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(hintText: 'Cost per period'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Cost is required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Save
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 8),

                // Delete
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _confirmDelete(context),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    child: const Text('Remove Subscription'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Subscription?'),
        content: Text('Are you sure you want to remove "${widget.sub.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _delete();
  }
}
