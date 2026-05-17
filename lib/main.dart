// ============================================================
// RAWBY — Entry Point
// Initializes: Hive, Firebase, Riverpod, go_router
// ============================================================
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_package;

import 'providers/router_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

// ── Background message handler (must be top-level) ──────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background push notifications here
  // No UI interaction possible in this handler
}

// ── Main ─────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lock to portrait on mobile (optional — remove for tablet support)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 2. Initialize timezone data (Europe/Budapest for deadline anchoring)
  tz.initializeTimeZones();
  tz_package.setLocalLocation(tz_package.getLocation('Europe/Budapest')); // Set local timezone

  // 3. Initialize Hive
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.init();

  // 4. Initialize Firebase (mobile only — Windows/Linux have no FCM support)
  bool firebaseReady = false;
  final isMobilePlatform = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (isMobilePlatform) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      firebaseReady = true;
    } catch (_) {
      // Firebase not configured yet — push notifications will be disabled
    }
  }

  // 5. Run app with Riverpod
  runApp(
    ProviderScope(
      overrides: [
        // Inject the pre-initialized StorageService
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: RawbyApp(firebaseReady: firebaseReady),
    ),
  );
}

// ── Root Widget ───────────────────────────────────────────────

class RawbyApp extends ConsumerStatefulWidget {
  final bool firebaseReady;

  const RawbyApp({super.key, required this.firebaseReady});

  @override
  ConsumerState<RawbyApp> createState() => _RawbyAppState();
}

class _RawbyAppState extends ConsumerState<RawbyApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      ref.read(notificationServiceProvider);
    }
    // Brief splash delay for smooth startup feel
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RAWBY',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
      builder: (context, child) {
        if (!_ready) {
          return const SplashScreen();
        }
        final t = Theme.of(context).textTheme;
        return DefaultTextStyle(
          style: t.bodyMedium ?? const TextStyle(color: Color(0xFFF1F1F0)),
          child: _AppWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

// ── App Wrapper (max width constraint for web/desktop) ───────

class _AppWrapper extends StatelessWidget {
  final Widget child;

  const _AppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // On very wide screens (>1200px), center the content
    if (width > 1200) {
      return Center(
        child: SizedBox(
          width: 1200,
          child: child,
        ),
      );
    }

    return child;
  }
}
