// ============================================================
// RAWBY — Gear Screen (Full Implementation)
// Shows gear list with usage state, rest suggestions, and subscriptions
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_session_provider.dart';
import '../models/gear_model.dart';
import '../widgets/gear/add_gear_modal.dart';
import '../widgets/gear/add_subscription_modal.dart';
import '../widgets/gear/edit_gear_modal.dart';
import '../widgets/gear/edit_subscription_modal.dart';

class GearScreen extends ConsumerStatefulWidget {
  const GearScreen({super.key});

  @override
  ConsumerState<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends ConsumerState<GearScreen> {
  String _categoryFilter = 'all'; // 'all', 'filming', 'editing', 'digital'
  String _statusFilter = 'all';   // 'all', 'active', 'rested', 'retired'

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final theme = Theme.of(context);
    final allGear = session.gearPurchases;
    final annualSpend = session.annualSubscriptionSpend;

    // Apply filters
    final gear = allGear.where((g) {
      if (_categoryFilter != 'all' && g.category != _categoryFilter) return false;
      if (_statusFilter != 'all' && g.usageState != _statusFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gear & Kit', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Track your filming equipment and subscriptions', style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),

            // ── Annual Spend Card ────────────────────────────────
            if (annualSpend > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Annual Spend', style: theme.textTheme.bodySmall),
                        Text(
                          '${annualSpend.toStringAsFixed(0)} HUF',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Gear List ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gear Purchases', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => _showAddGearModal(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Gear'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Filters ──────────────────────────────────────────
            if (allGear.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'All', selected: _categoryFilter == 'all', onTap: () => setState(() => _categoryFilter = 'all')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Filming', icon: Icons.videocam_outlined, selected: _categoryFilter == 'filming', onTap: () => setState(() => _categoryFilter = 'filming')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Editing', icon: Icons.movie_edit, selected: _categoryFilter == 'editing', onTap: () => setState(() => _categoryFilter = 'editing')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Digital', icon: Icons.devices_outlined, selected: _categoryFilter == 'digital', onTap: () => setState(() => _categoryFilter = 'digital')),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 24, color: theme.colorScheme.outline),
                    const SizedBox(width: 12),
                    _FilterChip(label: 'Active', selected: _statusFilter == 'active', onTap: () => setState(() => _statusFilter = _statusFilter == 'active' ? 'all' : 'active')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Rested', selected: _statusFilter == 'rested', onTap: () => setState(() => _statusFilter = _statusFilter == 'rested' ? 'all' : 'rested')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Retired', selected: _statusFilter == 'retired', onTap: () => setState(() => _statusFilter = _statusFilter == 'retired' ? 'all' : 'retired')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (gear.isEmpty && allGear.isEmpty)
              _EmptyState(
                icon: Icons.camera_outlined,
                message: 'No gear logged yet',
                subMessage: 'Add your first piece of gear to get started',
                theme: theme,
              )
            else if (gear.isEmpty)
              _EmptyState(
                icon: Icons.filter_list_off,
                message: 'No gear matches filters',
                subMessage: 'Try changing the category or status filter',
                theme: theme,
              )
            else
              ...gear.map((item) => _GearItemCard(gear: item, theme: theme)),

            const SizedBox(height: 32),

            // ── Subscriptions List ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subscriptions', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => _showAddSubscriptionModal(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Subscription'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (session.subscriptions.isEmpty)
              _EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'No subscriptions tracked',
                subMessage: 'Add your digital subscriptions to track annual spend',
                theme: theme,
              )
            else
              ...session.subscriptions.map((sub) => _SubscriptionItemCard(sub: sub, theme: theme)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGearModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGearModal(),
    );
  }

  Future<void> _showAddSubscriptionModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSubscriptionModal(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;
  final ThemeData theme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subMessage,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GearItemCard extends ConsumerWidget {
  final GearItem gear;
  final ThemeData theme;

  const _GearItemCard({
    required this.gear,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPointCost = gear.ownership == 'new_purchase' && gear.pointCost > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gear.shouldSuggestRest
              ? theme.colorScheme.error.withOpacity(0.5)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getGearIcon(gear.category),
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gear.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${gear.category} · ${gear.usageState}'
                  '${hasPointCost ? ' · -${gear.pointCost} pts' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                if (gear.shouldSuggestRest)
                  Text(
                    'Suggest: rest this gear',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (gear.usageState == 'active' && gear.shouldSuggestRest)
            TextButton(
              onPressed: () {
                ref
                    .read(userSessionProvider.notifier)
                    .updateGearUsageState(gear.id, 'rested');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${gear.name} is now rested.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Rest',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (gear.usageState == 'rested')
            TextButton(
              onPressed: () {
                ref
                    .read(userSessionProvider.notifier)
                    .updateGearUsageState(gear.id, 'active');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${gear.name} is now active.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Activate',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          PopupMenuButton<String>(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'active', child: Text('Active')),
              const PopupMenuItem(value: 'rested', child: Text('Rested')),
              const PopupMenuItem(value: 'retired', child: Text('Retired')),
              const PopupMenuItem(value: 'edit', child: Text('Edit Gear')),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditGearModal(gear: gear),
                );
              } else {
                ref
                    .read(userSessionProvider.notifier)
                    .updateGearUsageState(gear.id, value);
              }
            },
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant, size: 18),
          ),
        ],
      ),
    );
  }

  IconData _getGearIcon(String category) {
    switch (category) {
      case 'filming':
        return Icons.camera_alt_outlined;
      case 'editing':
        return Icons.computer_outlined;
      case 'digital':
        return Icons.cloud_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _SubscriptionItemCard extends ConsumerWidget {
  final Subscription sub;
  final ThemeData theme;

  const _SubscriptionItemCard({
    required this.sub,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: sub.isActive ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSubscriptionIcon(sub.category),
            size: 20,
            color: sub.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: sub.isActive ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${sub.frequency} · ${sub.costHuf.toStringAsFixed(0)} HUF'
                  '${sub.isActive ? '' : ' (inactive)'}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Annual: ${sub.annualCostHuf.toStringAsFixed(0)} HUF',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: sub.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'toggle_active', child: Text(sub.isActive ? 'Mark Inactive' : 'Mark Active')),
              const PopupMenuItem(value: 'edit', child: Text('Edit Subscription')),
              const PopupMenuItem(value: 'remove', child: Text('Remove Subscription')),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditSubscriptionModal(sub: sub),
                );
              } else if (value == 'remove') {
                _confirmRemoveSubscription(context, ref, sub);
              } else if (value == 'toggle_active') {
                ref
                    .read(userSessionProvider.notifier)
                    .updateSubscriptionStatus(sub.id, !sub.isActive);
              }
            },
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant, size: 18),
          ),
        ],
      ),
    );
  }

  IconData _getSubscriptionIcon(String category) {
    switch (category) {
      case 'filming':
        return Icons.videocam_outlined;
      case 'editing':
        return Icons.laptop_mac_outlined;
      case 'digital':
        return Icons.cloud_download_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _confirmRemoveSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Subscription?'),
        content: Text('Are you sure you want to remove "${sub.name}"?'),
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
    if (confirmed == true) {
      ref.read(userSessionProvider.notifier).removeSubscription(sub.id);
    }
  }
}
