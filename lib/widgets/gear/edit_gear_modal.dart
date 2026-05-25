// ============================================================
// RAWBY — Edit Gear Modal
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';
import '../../models/gear_model.dart';
import '../../theme/app_colors.dart';

class EditGearModal extends ConsumerStatefulWidget {
  final GearItem gear;

  const EditGearModal({super.key, required this.gear});

  @override
  ConsumerState<EditGearModal> createState() => _EditGearModalState();
}

class _EditGearModalState extends ConsumerState<EditGearModal> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  late String _category;

  static const _categories = ['filming', 'editing', 'digital'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gear.name);
    _category = widget.gear.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(userSessionProvider.notifier).editGear(
          gearId: widget.gear.id,
          name: _nameController.text.trim(),
          category: _category,
        );
    Navigator.of(context).pop(true);
  }

  void _delete() {
    ref.read(userSessionProvider.notifier).removeGear(widget.gear.id);
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
                        'Edit Gear',
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
                Text('Gear Name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  maxLength: 80,
                  style: TextStyle(
                    color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(hintText: 'Gear name'),
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
                    child: const Text('Remove Gear'),
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
        title: const Text('Remove Gear?'),
        content: Text('Are you sure you want to remove "${widget.gear.name}"?'),
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
