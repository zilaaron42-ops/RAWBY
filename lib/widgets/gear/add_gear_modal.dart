// ============================================================
// RAWBY — Add Gear Modal
// User adds a new piece of gear, deducts points if new purchase
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ID generation handled by provider
import '../../providers/user_session_provider.dart';
import '../../theme/app_colors.dart';

class AddGearModal extends ConsumerStatefulWidget {
  const AddGearModal({super.key});

  @override
  ConsumerState<AddGearModal> createState() => _AddGearModalState();
}

class _AddGearModalState extends ConsumerState<AddGearModal> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _costController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _adding = false;

  String _category = 'filming';
  bool _isNewPurchase = true;

  static const _categories = ['filming', 'editing', 'digital'];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _addGear() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _adding = true);

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final pointCost = int.tryParse(_costController.text.trim()) ?? 0;

    ref.read(userSessionProvider.notifier).addGear(
          name: name,
          brand: brand,
          category: _category,
          pointCost: pointCost,
          isNewPurchase: _isNewPurchase,
        );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentScore = ref.watch(userSessionProvider).totalScore;
    final costPreview = int.tryParse(_costController.text.trim()) ?? 0;
    final newScorePreview = _isNewPurchase ? currentScore - costPreview : currentScore;

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
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_shopping_cart_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add New Gear',
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

                // Gear Name
                Text('Gear Name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  maxLength: 80,
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sony A7III',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                Text('Brand / Maker', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _brandController,
                  maxLength: 60,
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sony, DJI, Adobe',
                  ),
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

                // New Purchase toggle
                SwitchListTile(
                  title: Text('New Purchase', style: theme.textTheme.bodyMedium),
                  subtitle: Text('Deducts points from score', style: theme.textTheme.bodySmall),
                  value: _isNewPurchase,
                  onChanged: (v) => setState(() => _isNewPurchase = v),
                ),
                const SizedBox(height: 16),

                // Point Cost
                if (_isNewPurchase) ...[
                  Text('Point Cost', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Points to deduct',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score after: $newScorePreview pts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: newScorePreview < 0 ? RawbyPalette.danger : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _adding ? null : _addGear,
                    child: _adding
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Gear'),
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