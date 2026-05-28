// ============================================================
// RAWBY — Shell Scaffold
// Responsive: mobile (immersive content + glass bottom nav) vs
// desktop (sidebar + top user bar).
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../providers/router_provider.dart';
import '../../providers/user_session_provider.dart';
import '../user_bar.dart';
import 'bottom_nav.dart';
import 'side_nav.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.mobileBreakpoint;
    final session = ref.watch(userSessionProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location, session.isAdmin);

    if (isDesktop) {
      return _DesktopLayout(
        currentIndex: currentIndex,
        isAdmin: session.isAdmin,
        child: child,
      );
    }

    return _MobileLayout(
      currentIndex: currentIndex,
      isAdmin: session.isAdmin,
      child: child,
    );
  }

  int _locationToIndex(String location, bool isAdmin) {
    switch (location) {
      case Routes.home:
        return 0;
      case Routes.prompts:
        return 1;
      case Routes.leaderboard:
        return 2;
      case Routes.gear:
        return 3;
      default:
        return 0;
    }
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool isAdmin;

  const _MobileLayout({
    required this.child,
    required this.currentIndex,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: RawbyBottomNav(
        currentIndex: currentIndex,
        isAdmin: isAdmin,
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool isAdmin;

  const _DesktopLayout({
    required this.child,
    required this.currentIndex,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          RawbySideNav(
            currentIndex: currentIndex,
            isAdmin: isAdmin,
          ),
          VerticalDivider(
            width: 1,
            color: theme.colorScheme.outline,
          ),
          Expanded(
            child: Column(
              children: [
                const UserBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
