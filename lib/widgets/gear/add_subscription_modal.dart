// ============================================================
// RAWBY — Add Subscription Modal
// User adds a new subscription, tracks cost and frequency
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ID generation handled by provider
import '../../providers/user_session_provider.dart';
import '../../theme/app_colors.dart';

class AddSubscriptionModal extends ConsumerStatefulWidget {
  const AddSubscriptionModal({super.key});

  @override
  ConsumerState<AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends ConsumerState<AddSubscriptionModal> {
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _adding = false;

  String _category = 'digital';
  String _frequency = 'monthly';

  static const _categories = ['filming', 'editing', 'digital'];
  static const _frequencies = ['monthly', 'yearly'];

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _addSubscription() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _adding = true);

    final name = _nameController.text.trim();
    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;

    ref.read(userSessionProvider.notifier).addSubscription(
          name: name,
          category: _category,
          costHuf: cost,
          frequency: _frequency,
        );

    if (mounted) Navigator.of(context).pop(true);
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
                        Icons.receipt_long_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add New Subscription',
                        style: theme.textTheme.titleLarge,
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

                // Subscription Name
                Text('Subscription Name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  maxLength: 80,
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Adobe Creative Cloud',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
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
                  decoration: const InputDecoration(
                    hintText: 'Monthly or yearly cost in HUF',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Cost is required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _adding ? null : _addSubscription,
                    child: _adding
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Subscription'),
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