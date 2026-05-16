// ============================================================
// RAWBY — Sync Service
// Debounced pushSnapshot to Render backend
// ============================================================
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import for FCM token
import '../models/user_session.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(apiServiceProvider));
});

class SyncService {
  final ApiService _api;
  Timer? _debounce;

  SyncService(this._api);

  // This method will be called on user login to ensure FCM token is registered.
  Future<void> onUserLogin() async {
    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _api.registerFcmToken(token);
    }
  }

  void scheduleSync(UserSession session) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.syncDebounce, () => _doSync(session));
  }

  Future<void> _doSync(UserSession session) async {
    try {
      final rank = session.currentRank;
      await _api.syncScores({
        'totalScore': session.totalScore,
        'completedWeeks': session.completedWeeks,
        'rankLabel': rank.label,
        'history': session.history.take(50).map((h) => {
              'level': h.level,
              'points': h.points,
              'promptText': h.promptText,
              'likes': h.likes,
              'finalScore': h.finalScore,
              'createdAt': h.createdAt,
            }).toList(),
        'gear': session.gearPurchases.map((g) => {
              'label': g.name,
              'category': g.category,
            }).toList(),
        'pushSnapshot': {
          'weekStart': session.weekStart,
          'deadline': session.deadline,
          'submittedAt': session.submittedAt,
          'selectedPromptId': session.selectedPromptId,
          'workflow': session.workflow.map((t) => {'id': t.id, 'done': t.done}).toList(),
          'pendingStats': session.pendingStats.map((p) => {'id': p.id, 'dueOn': p.dueOn}).toList(),
          'cycleDay': session.preferences.cycleDay,
          'timezone': session.preferences.timezone,
          'streak': session.streak,
          'scores': {
            'total': session.totalScore,
            'skill': session.skillScore,
          },
        },
      });
    } catch (_) {
      // Sync failure is silent — will retry on next save
    }
  }

  void dispose() {
    _debounce?.cancel();
  }
}
