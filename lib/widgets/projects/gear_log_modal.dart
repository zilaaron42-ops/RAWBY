// ============================================================
// RAWBY — Gear Log Modal
// Shown after project submission to log which gear was used
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_session_provider.dart';
import '../../theme/app_colors.dart';

class GearLogModal extends ConsumerStatefulWidget {
  const GearLogModal({super.key});

  @override
  ConsumerState<GearLogModal> createState() => _GearLogModalState();
}

class _GearLogModalState extends ConsumerState<GearLogModal> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gear = session.gearPurchases.where((g) => g.usageState != 'retired').toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RawbyPalette.darkSurface : RawbyPalette.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('What gear did you use?', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Select all equipment used in this project',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              if (gear.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No gear added yet. You can add gear from the Gear tab.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: gear.length,
                    itemBuilder: (ctx, i) {
                      final item = gear[i];
                      final isSelected = _selected.contains(item.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(item.id);
                            } else {
                              _selected.remove(item.id);
                            }
                          });
                        },
                        title: Text(item.name, style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                          '${item.category} · ${item.usageState}',
                          style: theme.textTheme.bodySmall,
                        ),
                        secondary: Icon(
                          item.category == 'filming'
                              ? Icons.videocam_outlined
                              : item.category == 'editing'
                                  ? Icons.computer_outlined
                                  : Icons.devices_outlined,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        dense: true,
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(userSessionProvider.notifier).logProjectGear(
                          _selected.toList(),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text('Log ${_selected.length} items'),
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
