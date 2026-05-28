// ============================================================
// RAWBY — Router (go_router)
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../screens/login_screen.dart";
import "../screens/register_screen.dart";
import "../screens/home_screen.dart";
import "../screens/prompts_screen.dart";
import "../screens/leaderboard_screen.dart";
import "../screens/gear_screen.dart";
import "../screens/profile_screen.dart";
import "../screens/skill_screen.dart";
import "../screens/admin_screen.dart";
import "../screens/idea_bank_screen.dart";
import "../screens/feedback_wall_screen.dart";
import "../screens/assistant_screen.dart";
import "../screens/settings_screen.dart";
import "../screens/paywall_screen.dart";
import "../widgets/navigation/shell_scaffold.dart";
import "user_session_provider.dart";

class Routes {
  Routes._();
  static const login = "/login";
  static const register = "/register";
  static const home = "/";
  static const prompts = "/prompts";
  static const ideaBank = "/prompts/idea-bank";
  static const assistant = "/assistant";
  static const leaderboard = "/leaderboard";
  static const gear = "/gear";
  static const skill = "/skill";
  static const profile = "/profile";
  static const settings = "/settings";
  static const admin = "/admin";
  static const feedbackWall = "/admin/feedback";
  static const paywall = "/paywall";
}

final _isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(
    userSessionProvider.select((s) => s.userId.isNotEmpty),
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen<bool>(_isLoggedInProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: ref.read(_isLoggedInProvider) ? Routes.home : Routes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = ref.read(_isLoggedInProvider);
      final onLogin = state.matchedLocation == Routes.login;
      final onRegister = state.matchedLocation == Routes.register;

      if (!loggedIn && !onLogin && !onRegister) return Routes.login;
      if (loggedIn && onLogin) return Routes.home;
      return null;
    },
    routes: [
      // Login (no shell)
      GoRoute(
        path: Routes.login,
        name: "login",
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const LoginScreen(),
        ),
      ),

      // Register (no shell)
      GoRoute(
        path: Routes.register,
        name: "register",
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const RegisterScreen(),
        ),
      ),

      // Idea Bank — standalone (own AppBar, no shell nav)
      GoRoute(
        path: Routes.ideaBank,
        name: "ideaBank",
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const IdeaBankScreen(),
        ),
      ),

      // Feedback Wall — standalone
      GoRoute(
        path: Routes.feedbackWall,
        name: "feedbackWall",
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const FeedbackWallScreen(),
        ),
      ),

      // Paywall — standalone push overlay
      GoRoute(
        path: Routes.paywall,
        name: "paywall",
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const PaywallScreen(),
        ),
      ),

      // Main app shell (with navigation)
      ShellRoute(
        builder: (context, state, child) {
          return ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.home,
            name: "home",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: Routes.prompts,
            name: "prompts",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const PromptsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.leaderboard,
            name: "leaderboard",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const LeaderboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.gear,
            name: "gear",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const GearScreen(),
            ),
          ),
          GoRoute(
            path: Routes.skill,
            name: "skill",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const SkillScreen(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: "profile",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: Routes.assistant,
            name: "assistant",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const AssistantScreen(),
            ),
          ),
          GoRoute(
            path: Routes.settings,
            name: "settings",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.admin,
            name: "admin",
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const AdminScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

// Smooth fade transition (mirrors document.startViewTransition)
CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}
