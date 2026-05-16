import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

class PaywallScreen extends ConsumerWidget {
  final String featureName;
  const PaywallScreen({super.key, this.featureName = 'this feature'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upgrade to Rawby Pro'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium, size: 48, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock $featureName',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Upgrade to Rawby Pro to access the full creative toolkit.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _FeatureRow(icon: Icons.mic_rounded, text: 'JARVIS Voice Mode — AI by voice', theme: theme),
              _FeatureRow(icon: Icons.auto_awesome, text: 'Full AI assistant with app control', theme: theme),
              _FeatureRow(icon: Icons.camera_alt_outlined, text: 'Instagram auto-fetch & analytics', theme: theme),
              _FeatureRow(icon: Icons.psychology, text: 'Unlimited AI prompt generation', theme: theme),
              _FeatureRow(icon: Icons.trending_up, text: 'Advanced skill tracking & plans', theme: theme),
              _FeatureRow(icon: Icons.stars_rounded, text: 'Admin prompt access & early drops', theme: theme),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder),
                ),
                child: Column(
                  children: [
                    Text('Rawby Pro', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('7 days free, then billed monthly',
                        style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subscription coming soon!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Start 7-Day Free Trial'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Maybe later', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;
  const _FeatureRow({required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
