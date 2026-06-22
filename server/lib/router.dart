import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'auth.dart';
import 'store.dart';
import 'handlers/auth_handlers.dart';
import 'handlers/prompt_handlers.dart';
import 'handlers/leaderboard_handlers.dart';
import 'handlers/sync_handlers.dart';
import 'handlers/admin_handlers.dart';
import 'handlers/instagram_handlers.dart';
import 'handlers/ai_handlers.dart';
import 'handlers/admin_prompt_handlers.dart';
import 'handlers/suggestion_handlers.dart';

Handler buildRouter() {
  final router = Router();

  // ── Health check ───────────────────────────────────────────────
  // Pings Mongo too, so Render's 10-min keep-alive on this endpoint keeps the
  // DB connection warm and auto-reconnects it if Atlas dropped the socket.
  router.get('/api/health', (Request request) async {
    final dbOk = await Store.instance.pingDb();
    return Response.ok(
      jsonEncode({
        'status': dbOk ? 'ok' : 'degraded',
        'service': 'rawby-server',
        'db': dbOk ? 'connected' : 'disconnected',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // ── Public Auth routes ─────────────────────────────────────────
  router.post('/api/login', handleLogin);
  router.post('/api/register', handleRegister);
  router.get('/api/verify-email', handleVerifyEmail);

  // ── Protected routes (wrapped with auth check) ─────────────────

  // Re-open Mongo if Atlas dropped the idle socket, before the handler runs —
  // turns an opaque 500 into a healthy response that self-heals the connection.
  Middleware _ensureDb() => (Handler inner) => (Request r) async {
        await Store.instance.ensureConnected();
        return inner(r);
      };

  Handler protect(Future<Response> Function(Request) handler) {
    return Pipeline()
        .addMiddleware(_ensureDb())
        .addMiddleware(authMiddleware())
        .addHandler(handler);
  }

  Handler protectWithParam(Future<Response> Function(Request, String) handler) {
    return Pipeline()
        .addMiddleware(_ensureDb())
        .addMiddleware(authMiddleware())
        .addHandler(
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
  // Accepts X-Admin-Secret header (no JWT) or valid admin JWT
  router.delete('/api/admin/users/all', handleDeleteAllUsers);
  // Delete a single user (admin JWT or X-Admin-Secret) — handler guards.
  router.delete('/api/admin/users/<username>', protectWithParam(handleDeleteUser));
  // No JWT needed — protected by X-Admin-Secret header in handler
  router.post('/api/admin/set-admin', handleMakeAdmin);

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

  // Community prompts (user-written, used as AI inspiration)
  router.post('/api/community-prompt', protect((Request r) async {
    final body = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
    final text = (body['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'text required'}), headers: {'content-type': 'application/json'});
    }
    await Store.instance.saveCommunityPrompt({
      'text': text,
      'userId': getUserId(r),
      'category': body['category'] as String? ?? '',
    });
    return Response.ok(jsonEncode({'ok': true}), headers: {'content-type': 'application/json'});
  }));

  // Suggestions
  router.post('/api/suggestions', protect(handleSubmitSuggestion));
  router.get('/api/suggestions', protect(handleGetMySuggestions));
  router.get('/api/admin/suggestions', protect(handleGetAllSuggestions));
  router.post('/api/admin/suggestions/<id>/reply', protectWithParam(handleReplySuggestion));

  return router.call;
}
