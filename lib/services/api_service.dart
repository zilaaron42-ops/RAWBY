// ============================================================
// RAWBY — API Service (Dio HTTP client)
// All calls to the Render backend go through here.
// ============================================================
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../constants/app_constants.dart";

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint("[API] $obj"),
      ));
    }

    // Auth interceptor — injects token if available
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers["Authorization"] = "Bearer $_authToken";
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired — clear auth
          _authToken = null;
        }
        handler.next(error);
      },
    ));
  }

  String? _authToken;

  bool get hasAuthToken => _authToken != null;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post("/api/login", data: {
      "username": username,
      "password": password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post("/api/register", data: {
      "username": username,
      "displayName": displayName,
      "email": email,
      "password": password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get("/api/me");
    return response.data as Map<String, dynamic>;
  }

  // ── Prompts ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> generatePrompts({
    required String provider,
    required String model,
    required List<Map<String, dynamic>> inspirations,
    required bool seasonalPrompts,
    required String region,
    required String filmmakingGoal,
    required String contentType,
  }) async {
    final response = await _dio.post("/api/generate-prompts", data: {
      "provider": provider,
      "model": model,
      "inspirations": inspirations,
      "seasonalPrompts": seasonalPrompts,
      "region": region,
      "filmingGoal": filmmakingGoal,
      "contentType": contentType,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Leaderboard ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getLeaderboard() async {
    final response = await _dio.get("/api/leaderboard");
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile(String username) async {
    final response = await _dio.get("/api/profile/$username");
    return response.data as Map<String, dynamic>;
  }

  // ── Sync ─────────────────────────────────────────────────────

  Future<void> pushSnapshot(Map<String, dynamic> snapshot) async {
    await _dio.post("/api/sync", data: snapshot);
  }

  Future<void> syncScores(Map<String, dynamic> data) async {
    await _dio.post("/api/sync-scores", data: data);
  }

  // ── Instagram ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getInstagramRecent({
    int limit = 500,
    bool insights = false,
  }) async {
    final response = await _dio.get("/api/instagram-recent", queryParameters: {
      "limit": limit,
      "insights": insights,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReelLikes(String reelUrl) async {
    final response = await _dio.post("/api/fetch-reel-likes", data: {
      "url": reelUrl,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Admin ────────────────────────────────────────────────────

  Future<List<dynamic>> getFeedback() async {
    final response = await _dio.get("/api/feedback");
    return response.data as List<dynamic>;
  }

  Future<void> deleteFeedback(String id) async {
    await _dio.delete("/api/feedback/$id");
  }

  Future<void> postUpdate({
    required String title,
    required String body,
    required bool sendPush,
  }) async {
    await _dio.post("/api/updates", data: {
      "title": title,
      "body": body,
      "sendPush": sendPush,
    });
  }

  Future<List<dynamic>> getUpdates() async {
    final response = await _dio.get("/api/updates");
    return response.data as List<dynamic>;
  }

  // ── Notifications ────────────────────────────────────────────

  Future<void> registerFcmToken(String token) async {
    await _dio.post("/api/fcm-token", data: {"token": token});
  }

  Future<Map<String, dynamic>> getSkillFeedback({
    required String provider,
    required String model,
    required String focusArea,
    required String notes,
    required List<dynamic> history,
    required Map<String, dynamic> stats,
  }) async {
    final response = await _dio.post("/api/skill-feedback", data: {
      "provider": provider,
      "model": model,
      "focusArea": focusArea,
      "notes": notes,
      "history": history,
      "stats": stats,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getUsers() async {
    final response = await _dio.get("/api/users");
    return response.data as List<dynamic>;
  }

  Future<String> aiChat({
    required List<Map<String, String>> messages,
    required Map<String, dynamic> context,
    String provider = 'groq',
  }) async {
    final response = await _dio.post(
      "/api/chat",
      data: {
        "messages": messages
            .map((m) => {'role': m['role'], 'content': m['content']})
            .toList(),
        "context": context,
        "provider": provider,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['reply'] as String? ?? 'Something went wrong.';
  }

  Future<Map<String, dynamic>> fetchInstagramHandleStats(String handle) async {
    final response = await _dio.get("/api/instagram-handle", queryParameters: {
      "handle": handle,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> saveAdminPrompt(Map<String, dynamic> prompt) async {
    await _dio.post("/api/admin/prompts", data: prompt);
  }

  Future<List<dynamic>> getAdminPrompts() async {
    final response = await _dio.get("/api/admin/prompts");
    return response.data as List<dynamic>;
  }

  // ── Suggestions ───────────────────────────────────────────────

  Future<void> submitSuggestion(String text) async {
    await _dio.post("/api/suggestions", data: {"text": text});
  }

  Future<List<dynamic>> getMySuggestions() async {
    final response = await _dio.get("/api/suggestions");
    final data = response.data as Map<String, dynamic>;
    return data['suggestions'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getAllSuggestions() async {
    final response = await _dio.get("/api/admin/suggestions");
    final data = response.data as Map<String, dynamic>;
    return data['suggestions'] as List<dynamic>? ?? [];
  }

  Future<void> replySuggestion(String id, String reply) async {
    await _dio.post("/api/admin/suggestions/$id/reply", data: {"reply": reply});
  }
}
