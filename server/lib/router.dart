import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'auth.dart';
import 'handlers/auth_handlers.dart';
import 'handlers/prompt_handlers.dart';
import 'handlers/leaderboard_handlers.dart';
import 'handlers/sync_handlers.dart';
import 'handlers/admin_handlers.dart';
import 'handlers/instagram_handlers.dart';
import 'handlers/ai_handlers.dart';
import 'handlers/admin_prompt_handlers.dart';

Handler buildRouter() {
  final router = Router();

  // ── Health check ───────────────────────────────────────────────
  router.get('/api/health', (Request request) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'rawby-server', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  });

  // ── Public Auth routes ─────────────────────────────────────────
  router.post('/api/login', handleLogin);
  router.post('/api/register', handleRegister);

  // ── Protected routes (wrapped with auth check) ─────────────────

  Handler protect(Future<Response> Function(Request) handler) {
    return const Pipeline().addMiddleware(authMiddleware()).addHandler(handler);
  }

  Handler protectWithParam(Future<Response> Function(Request, String) handler) {
    return const Pipeline().addMiddleware(authMiddleware()).addHandler(
      (Request r) {
        final segments = r.requestedUri.pathSegments;
        final param = segments.last;
        return handler(r, param);
      },
    );
  }

  // Me
  router.get('/api/me', protect(handleGetMe));

  // Prompts
  router.post('/api/generate-prompts', protect(handleGeneratePrompts));

  // Leaderboard
  router.get('/api/leaderboard', protect(handleGetLeaderboard));
  router.get('/api/profile/<username>', protectWithParam(handleGetProfile));

  // Sync
  router.post('/api/sync', protect(handlePushSnapshot));
  router.post('/api/sync-scores', protect(handleSyncScores));

  // Instagram
  router.get('/api/instagram-recent', protect(handleInstagramRecent));
  router.post('/api/fetch-reel-likes', protect(handleFetchReelLikes));

  // Admin
  router.get('/api/feedback', protect(handleGetFeedback));
  router.delete('/api/feedback/<id>', protectWithParam(handleDeleteFeedback));
  router.post('/api/updates', protect(handlePostUpdate));
  router.get('/api/updates', protect(handleGetUpdates));
  router.get('/api/users', protect(handleGetUsers));

  // FCM
  router.post('/api/fcm-token', protect(handleRegisterFcmToken));

  // AI
  router.post('/api/chat', protect(handleAiChat));
  router.post('/api/skill-feedback', protect(handleSkillFeedback));

  // Instagram handle stats (placeholder)
  router.get('/api/instagram-handle', protect(handleInstagramHandleStats));

  // Admin prompt builder
  router.post('/api/admin/prompts', protect(handleSaveAdminPrompt));
  router.get('/api/admin/prompts', protect(handleGetAdminPrompts));

  return router.call;
}
