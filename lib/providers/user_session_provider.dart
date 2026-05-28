// ============================================================
// RAWBY — UserSession Riverpod Provider
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/user_session.dart';
import '../models/prompt_model.dart';
import '../models/project_model.dart';
import '../models/gear_model.dart';
import '../constants/app_constants.dart';
import '../constants/prompt_templates.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/scoring_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

// ── Provider ─────────────────────────────────────────────────

final userSessionProvider =
    StateNotifierProvider<UserSessionNotifier, UserSession>((ref) {
  return UserSessionNotifier(ref);
});

// ── Notifier ─────────────────────────────────────────────────

class UserSessionNotifier extends StateNotifier<UserSession> {
  final Ref _ref;
  Timer? _syncDebounce;

  UserSessionNotifier(this._ref) : super(_buildInitialSession()) {
    _loadFromStorage();
  }

  // ── Initialization ───────────────────────────────────────────

  static UserSession _buildInitialSession() {
    final now = tz.TZDateTime.now(tz.getLocation(AppConstants.hungaryTz));
    final weekStart = _getCurrentCycleStart(now);
    final deadline = weekStart.add(const Duration(days: 7));
    final prefs = UserPreferences();
    return UserSession(
      seasonStart: tz.TZDateTime(tz.getLocation(AppConstants.hungaryTz), 2026, 5, 1).toIso8601String(),
      weekStart: weekStart.toIso8601String(),
      deadline: deadline.toIso8601String(),
      regenWeek: weekStart.toIso8601String(),
      preferences: prefs,
      aiSettings: AiSettings(),
      prompts: _generateLocalPrompts(),
      workflow: _weeklyWorkflow(prefs.cycleDay),
    );
  }

  Future<void> _loadFromStorage() async {
    final storage = _ref.read(storageServiceProvider);
    // Restore auth token so API calls have it immediately after app restart
    final savedToken = storage.getString(AppConstants.authTokenKey);
    if (savedToken != null) {
      _ref.read(apiServiceProvider).setAuthToken(savedToken);
    }
    final raw = storage.getString(AppConstants.storageKey);
    if (raw == null) {
      _scheduleSave();
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = UserSession.fromJson(json);
      final realigned = _realignCycle(loaded);
      state = realigned;
    } catch (e) {
      state = _buildInitialSession();
      _scheduleSave();
    }
  }

  // ── Cycle Logic ──────────────────────────────────────────────

  static tz.TZDateTime _getCurrentCycleStart(tz.TZDateTime now, {String cycleDay = 'Friday'}) {
    const dayMap = {
      'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
      'Thursday': 4, 'Friday': 5, 'Saturday': 6,
    };
    final anchor = dayMap[cycleDay] ?? 5;
    final currentWeekday = now.weekday % 7; // 0=Sun, 1=Mon...6=Sat
    final daysBack = (currentWeekday - anchor + 7) % 7;
    return tz.TZDateTime(now.location, now.year, now.month, now.day)
        .subtract(Duration(days: daysBack));
  }

  UserSession _realignCycle(UserSession session) {
    final activeBig = session.bigProjects.any(
      (b) => b.status == 'active',
    );
    if (activeBig) return session; // Don't realign if big project is active

    final nowInTz = tz.TZDateTime.now(tz.getLocation(session.preferences.timezone));
    final anchor = _getCurrentCycleStart(
      nowInTz,
      cycleDay: session.preferences.cycleDay,
    ).toIso8601String();

    if (session.weekStart == anchor) return session;

    // New cycle — queue pending stats if needed
    final newPending = List<PendingStats>.from(session.pendingStats);
    if (session.submittedAt != null && session.statsRecordedAt == null) {
      final selectedPrompt = session.prompts.firstWhere(
        (p) => p.id == session.selectedPromptId,
        orElse: () => session.prompts.isNotEmpty ? session.prompts.first : _emptyPrompt(),
      );
      newPending.add(PendingStats(
        id: 'pending_${session.weekStart}',
        weekStart: session.weekStart,
        deadline: session.deadline,
        submittedAt: session.submittedAt!,
        promptText: selectedPrompt.text,
        level: selectedPrompt.level,
        points: selectedPrompt.points,
        inspiration: selectedPrompt.inspiration,
        instagramUrl: session.instagramUrl, // Store URL with pending stats
        dueOn: DateTime.parse(session.deadline)
            .add(const Duration(days: 7))
            .toIso8601String(),
      ));
    }

    final newDeadline = DateTime.parse(anchor)
        .add(const Duration(days: 7))
        .toIso8601String();

    return session.copyWith(
      weekStart: anchor,
      deadline: newDeadline,
      regenWeek: anchor,
      regenCount: 0,
      autoGenPending: true,
      prompts: _generateLocalPrompts(),
      selectedPromptId: null,
      workflow: _weeklyWorkflow(session.preferences.cycleDay),
      submittedAt: null,
      statsRecordedAt: null,
      likes: 0,
      views: 0,
      instagramUrl: '',
      progressLog: [],
      projectStartWindow: null,
      pendingStats: newPending,
      bigProjectSubmitted: false,
    );
  }

  static PromptModel _emptyPrompt() => PromptModel(
        id: 'empty',
        level: 'Sequence',
        points: 10,
        category: '',
        inspiration: '',
        text: '',
        source: 'local',
      );

  // ── Local Prompt Generation ──────────────────────────────────

  static List<PromptModel> _generateLocalPrompts() {
    final creators = List.of(PromptTemplates.creatorStyles)..shuffle();
    final insp = creators.take(3).toList();

    PromptModel build(String level, int points, int idx) {
      final templates = PromptTemplates.byLevel(level);
      final tpl = templates[(DateTime.now().millisecondsSinceEpoch ~/ 1000 + idx) % templates.length];
      final creator = insp[idx];
      return PromptModel(
        id: 'p${points}_${DateTime.now().millisecondsSinceEpoch}',
        level: level,
        points: points,
        category: tpl.cat,
        inspiration: creator.handle,
        inspirationStyle: creator.style,
        inspirationProfileUrl: creator.profileUrl,
        inspirationReferenceHint: creator.referenceHint,
        text: tpl.text,
        source: 'local',
      );
    }

    return [
      build('Sequence', 10, 0),
      build('Short Story', 30, 1),
      build('Story + Character', 50, 2),
    ];
  }

  static List<WorkflowTask> _weeklyWorkflow(String cycleDay) {
    const dayMap = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    const dayIndex = {
      'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
      'Thursday': 4, 'Friday': 5, 'Saturday': 6,
    };
    final idx = dayIndex[cycleDay] ?? 5;
    String d(int offset) => dayMap[(idx + offset) % 7];

    return [
      WorkflowTask(id: 'script_music', label: 'Song & prompt selected', day: cycleDay),
      WorkflowTask(id: 'filming',      label: 'Filming finished',        day: '${d(1)} or ${d(2)}'),
      WorkflowTask(id: 'editing',      label: 'Rough edit done',         day: '${d(3)} or ${d(4)}'),
      WorkflowTask(id: 'vfx',          label: 'VFX & text done',         day: '${d(4)} or ${d(5)}'),
      WorkflowTask(id: 'sound',        label: 'SFX done',                day: '${d(4)} or ${d(5)}'),
      WorkflowTask(id: 'grading',      label: 'Colour done',             day: '${d(5)} or ${d(6)}'),
      WorkflowTask(id: 'publish',      label: 'Polish & publish',        day: cycleDay),
    ];
  }

  // ── State Mutations ──────────────────────────────────────────

  void updateDisplayName(String displayName) {
    state = state.copyWith(displayName: displayName);
    _scheduleSave();
  }

  void updatePreferences(UserPreferences prefs) {
    state = state.copyWith(preferences: prefs);
    _scheduleSave();
  }

  void updateAiSettings(AiSettings settings) {
    state = state.copyWith(aiSettings: settings);
    _scheduleSave();
  }

  void setUser({
    required String userId,
    required String username,
    required String displayName,
    required String email,
    required String role,
  }) {
    state = state.copyWith(
      userId: userId,
      username: username,
      displayName: displayName,
      email: email,
      role: role,
    );
    // Auto-start trial for new users on first login/register
    if (state.trialStartedAt == null) {
      startTrial();
    }
    _scheduleSave();
  }

  void setPrompts(List<PromptModel> prompts) {
    state = state.copyWith(prompts: prompts, selectedPromptId: null);
    _addProgressLog('Prompts updated', 'info');
    _scheduleSave();
  }

  void selectPrompt(String id) {
    if (state.isLocked) return;
    final found = state.prompts.firstWhere(
      (p) => p.id == id,
      orElse: () => _emptyPrompt(),
    );
    if (found.id == 'empty') return;

    final window = ProjectStartWindow(
      type: found.source == 'big' ? 'big' : 'weekly',
      label: found.level,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    state = state.copyWith(
      selectedPromptId: id,
      prompts: [found],
      workflow: _weeklyWorkflow(state.preferences.cycleDay),
      projectStartWindow: window,
      promptConfirmedAt: null, // Reset confirmation — user must confirm within 1h
    );
    _addProgressLog('Prompt chosen: ${found.level} (${found.points} pts) — confirm within 1 hour', 'prompt');
    _scheduleSave();
  }

  void confirmPrompt() {
    if (state.selectedPromptId == null || state.isPromptConfirmed) return;
    if (state.isConfirmationExpired) {
      // Window expired — reset selection
      cancelPromptSelection();
      return;
    }
    state = state.copyWith(
      promptConfirmedAt: DateTime.now().toIso8601String(),
    );
    _addProgressLog('Prompt confirmed — project locked in!', 'prompt');
    _scheduleSave();
  }

  void cancelPromptSelection() {
    if (state.isPromptConfirmed) return; // Can't cancel after confirmation
    state = state.copyWith(
      selectedPromptId: null,
      prompts: [],
      projectStartWindow: null,
      promptConfirmedAt: null,
    );
    _addProgressLog('Prompt selection cancelled', 'info');
    _scheduleSave();
  }

  void logProjectGear(List<String> gearIds) {
    state = state.copyWith(projectGearUsed: gearIds);
    _addProgressLog('Gear logged: ${gearIds.length} items', 'info');
    _scheduleSave();
  }

  void completeWorkflowTask(String taskId) {
    final updated = state.workflow.map((t) {
      if (t.id == taskId) {
        return t.copyWith(done: true, completedAt: DateTime.now());
      }
      return t;
    }).toList();
    state = state.copyWith(workflow: updated);
    _addProgressLog('Task completed: $taskId', 'info');
    _scheduleSave();
  }

  // ── Prompt Saving (Idea Bank) ────────────────────────────────

  void savePrompt(PromptModel prompt) {
    final already = state.savedPrompts.any((p) => p.id == prompt.id);
    if (already) return;
    final saved = prompt.copyWith(isSaved: true, savedAt: DateTime.now());
    state = state.copyWith(savedPrompts: [...state.savedPrompts, saved]);
    _addProgressLog('Prompt saved to Idea Bank', 'info');
    _scheduleSave();
  }

  void removeSavedPrompt(String id) {
    state = state.copyWith(
      savedPrompts: state.savedPrompts.where((p) => p.id != id).toList(),
    );
    _addProgressLog('Prompt removed from Idea Bank', 'info');
    _scheduleSave();
  }

  void clearSavedPrompts() {
    state = state.copyWith(savedPrompts: []);
    _addProgressLog('Idea Bank cleared', 'info');
    _scheduleSave();
  }

  // ── Regen ────────────────────────────────────────────────────

  void incrementRegenCount() {
    state = state.copyWith(regenCount: state.regenCount + 1);
    _scheduleSave();
  }

  void setAutoGenPending(bool value) {
    state = state.copyWith(autoGenPending: value);
    _scheduleSave();
  }

  // ── Project Actions ──────────────────────────────────────────

  void submitProject({
    required String instagramUrl,
  }) {
    final now = tz.TZDateTime.now(tz.getLocation(state.preferences.timezone));
    final deadlineDt = DateTime.parse(state.deadline).toUtc();
    final currentPrompt = state.prompts.firstWhere(
      (p) => p.id == state.selectedPromptId,
      orElse: () => _emptyPrompt(),
    );

    final historyEntry = HistoryEntry(
      id: state.weekStart,
      weekStart: state.weekStart,
      deadline: state.deadline,
      submittedAt: now.toIso8601String(),
      promptText: currentPrompt.text,
      level: currentPrompt.level,
      points: currentPrompt.points,
      inspiration: currentPrompt.inspiration,
      instagramUrl: instagramUrl,
      isTestRun: ScoringService.isTestRun(now),
      createdAt: now.toIso8601String(),
      source: currentPrompt.source,
      // Score and likes/views will be added when stats are recorded
    );

    state = state.copyWith(
      submittedAt: now.toIso8601String(),
      instagramUrl: instagramUrl,
      history: [...state.history, historyEntry],
      pendingStats: [...state.pendingStats, historyEntry.toPendingStats()],
      prompts: [], // Clear prompts for the next cycle
      selectedPromptId: null,
      workflow: _weeklyWorkflow(state.preferences.cycleDay),
      projectStartWindow: null,
      likes: 0, // Reset current week stats
      views: 0,
      statsRecordedAt: null,
    );
    _addProgressLog(
        'Project submitted! Deadline: ${ScoringService.penaltyLabel(now, deadlineDt)}',
        'submit');
    _scheduleSave();
    _ref.read(notificationServiceProvider).scheduleStatsReadyNotification(
      tz.TZDateTime.from(state.statsUnlockDate, tz.local),
    );
  }

  void recordStats({
    required int likes,
    required int views,
  }) {
    final now = tz.TZDateTime.now(tz.getLocation(state.preferences.timezone));
    final submitted = DateTime.parse(state.submittedAt!).toUtc();
    final deadline = DateTime.parse(state.deadline).toUtc();
    // Prompts are cleared after submit — get points from the history entry
    final historyEntry = state.history.where((h) => h.id == state.weekStart).firstOrNull;
    final promptPoints = historyEntry?.points ?? 10;

    final score = ScoringService.calculateScore(
      likes: likes,
      promptPoints: promptPoints,
      submittedAt: submitted,
      deadline: deadline,
    );

    final updatedHistory = state.history.map((entry) {
      if (entry.id == state.weekStart) {
        return entry.copyWith(
          likes: likes,
          views: views,
          finalScore: score,
          statsRecordedAt: now.toIso8601String(),
          penaltyMultiplier: ScoringService.penaltyMultiplier(submitted, deadline),
        );
      }
      return entry;
    }).toList();

    final updatedPending = state.pendingStats.where(
      (p) => p.weekStart != state.weekStart,
    ).toList();

    state = state.copyWith(
      statsRecordedAt: now.toIso8601String(),
      likes: likes,
      views: views,
      totalScore: state.totalScore + score,
      completedWeeks: state.completedWeeks + 1,
      history: updatedHistory,
      pendingStats: updatedPending,
    );
    _addProgressLog(
        'Stats recorded: $likes likes, $views views. Earned $score pts',
        'stats');
    _scheduleSave();
  }

  void recordPendingStats({
    required String pendingId,
    required int likes,
    required int views,
  }) {
    final now = tz.TZDateTime.now(tz.getLocation(state.preferences.timezone));
    final idx = state.pendingStats.indexWhere((p) => p.id == pendingId);
    if (idx == -1) {
      debugPrint('[recordPendingStats] no pending entry with id $pendingId');
      return;
    }
    final pendingEntry = state.pendingStats[idx];

    final submitted = DateTime.parse(pendingEntry.submittedAt).toUtc();
    final deadline = DateTime.parse(pendingEntry.deadline).toUtc();

    final score = ScoringService.calculateScore(
      likes: likes,
      promptPoints: pendingEntry.points,
      submittedAt: submitted,
      deadline: deadline,
    );

    final newHistoryEntry = HistoryEntry(
      id: pendingEntry.weekStart,
      weekStart: pendingEntry.weekStart,
      deadline: pendingEntry.deadline,
      submittedAt: pendingEntry.submittedAt,
      statsRecordedAt: now.toIso8601String(),
      promptText: pendingEntry.promptText,
      level: pendingEntry.level,
      points: pendingEntry.points,
      inspiration: pendingEntry.inspiration,
      instagramUrl: pendingEntry.instagramUrl,
      likes: likes,
      views: views,
      finalScore: score,
      penaltyMultiplier: ScoringService.penaltyMultiplier(submitted, deadline),
      isTestRun: ScoringService.isTestRun(submitted),
      createdAt: pendingEntry.submittedAt, // Use submittedAt as creation for history
      source: 'local', // Assuming local/AI/custom prompts are always weekly
    );

    final updatedHistory = List<HistoryEntry>.from(state.history)
      ..add(newHistoryEntry);

    final updatedPending = state.pendingStats
        .where((p) => p.id != pendingId)
        .toList();

    state = state.copyWith(
      totalScore: state.totalScore + score,
      completedWeeks: state.completedWeeks + 1,
      history: updatedHistory,
      pendingStats: updatedPending,
    );
    _addProgressLog(
        'Past project stats recorded ($pendingId): $likes likes, $views views. Earned $score pts',
        'stats');
    _scheduleSave();
  }

  void startBigProject({
    required String title,
    required int durationDays,
  }) {
    final now = tz.TZDateTime.now(tz.getLocation(state.preferences.timezone));
    final deadline = now.add(Duration(days: durationDays));
    final newBigProject = BigProject(
      id: 'big_${now.millisecondsSinceEpoch}',
      title: title,
      promptText: title, // Use title as prompt text for big projects
      startedAt: now,
      deadline: deadline,
      durationDays: durationDays,
      status: 'active',
    );

    // Clear weekly prompts and lock the system
    state = state.copyWith(
      bigProjects: [...state.bigProjects, newBigProject],
      prompts: [],
      selectedPromptId: null,
      projectStartWindow: null,
      submittedAt: now.toIso8601String(), // Lock the week, essentially
      bigProjectSubmitted: true,
      likes: 0, // Reset current week stats
      views: 0,
      statsRecordedAt: null,
    );
    _addProgressLog('Big Project started: $title ($durationDays days)', 'project');
    _scheduleSave();
  }

  void dnfBigProject() {
    final activeBig = state.activeBigProject;
    if (activeBig == null) return;

    final now = tz.TZDateTime.now(tz.getLocation(state.preferences.timezone));
    final updatedBigProjects = state.bigProjects.map((p) {
      if (p.id == activeBig.id) {
        return p.copyWith(
          status: 'dnf',
          submittedAt: now, // Mark DNF date
        );
      }
      return p;
    }).toList();

    state = state.copyWith(
      bigProjects: updatedBigProjects,
      totalScore: state.totalScore - BigProject.basePoints,
      submittedAt: null, // Unlock regular cycle
      bigProjectSubmitted: false,
      prompts: _generateLocalPrompts(), // Regenerate prompts after DNF
    );
    _addProgressLog('Big Project DNF: ${activeBig.title}. ${BigProject.basePoints} pts deducted.', 'project');
    _scheduleSave();
  }

  // ── Gear Actions ─────────────────────────────────────────────

  void addGear({
    required String name,
    required String brand,
    required String category,
    required int pointCost,
    required bool isNewPurchase,
  }) {
    final now = DateTime.now();
    final newGear = GearItem(
      id: 'gear_${now.millisecondsSinceEpoch}',
      name: name,
      category: category,
      brand: brand,
      ownership: isNewPurchase ? 'new_purchase' : 'already_owned',
      costHuf: 0,
      pointsCost: pointCost,
      owner: '',
      notes: '',
      createdAt: now,
      usageState: 'active',
    );

    int newTotalScore = state.totalScore;
    if (isNewPurchase) {
      newTotalScore -= pointCost;
    }

    state = state.copyWith(
      gearPurchases: [...state.gearPurchases, newGear],
      totalScore: newTotalScore,
    );
    _addProgressLog('Gear added: $name (-$pointCost pts)', 'gear');
    _scheduleSave();
  }

  void updateGearUsageState(String gearId, String newState) {
    final updatedGear = state.gearPurchases.map((g) {
      if (g.id == gearId) {
        return g.copyWith(usageState: newState);
      }
      return g;
    }).toList();
    state = state.copyWith(gearPurchases: updatedGear);
    _addProgressLog('Gear usage updated for $gearId to $newState', 'gear');
    _scheduleSave();
  }

  void editGear({
    required String gearId,
    required String name,
    required String category,
  }) {
    final updatedGear = state.gearPurchases.map((g) {
      if (g.id == gearId) {
        return g.copyWith(name: name, category: category);
      }
      return g;
    }).toList();
    state = state.copyWith(gearPurchases: updatedGear);
    _addProgressLog('Gear edited: $name', 'gear');
    _scheduleSave();
  }

  void removeGear(String gearId) {
    state = state.copyWith(
      gearPurchases: state.gearPurchases.where((g) => g.id != gearId).toList(),
    );
    _addProgressLog('Gear removed: $gearId', 'gear');
    _scheduleSave();
  }

  void addSubscription({
    required String name,
    required double costHuf,
    required String frequency,
    required String category,
  }) {
    final now = tz.TZDateTime.now(tz.getLocation(state.preferences.timezone));
    final newSub = Subscription(
      id: 'sub_${now.millisecondsSinceEpoch}',
      name: name,
      costHuf: costHuf,
      frequency: frequency,
      category: category,
      addedAt: now,
      isActive: true,
    );
    state = state.copyWith(subscriptions: [...state.subscriptions, newSub]);
    _addProgressLog('Subscription added: $name', 'gear');
    _scheduleSave();
  }

  void updateSubscriptionStatus(String subId, bool isActive) {
    final updatedSubs = state.subscriptions.map((s) {
      if (s.id == subId) {
        return s.copyWith(isActive: isActive);
      }
      return s;
    }).toList();
    state = state.copyWith(subscriptions: updatedSubs);
    _addProgressLog('Subscription status updated for $subId to $isActive', 'gear');
    _scheduleSave();
  }

  void editSubscription({
    required String subId,
    required String name,
    required double costHuf,
    required String frequency,
    required String category,
  }) {
    final updatedSubs = state.subscriptions.map((s) {
      if (s.id == subId) {
        return s.copyWith(
          name: name,
          costHuf: costHuf,
          frequency: frequency,
          category: category,
        );
      }
      return s;
    }).toList();
    state = state.copyWith(subscriptions: updatedSubs);
    _addProgressLog('Subscription edited: $name', 'gear');
    _scheduleSave();
  }

  void removeSubscription(String subId) {
    state = state.copyWith(
      subscriptions: state.subscriptions.where((s) => s.id != subId).toList(),
    );
    _addProgressLog('Subscription removed: $subId', 'gear');
    _scheduleSave();
  }

  void updateSkillPlan(String plan) {
    state = state.copyWith(skillAiPlan: plan);
    _addProgressLog('AI skill plan updated', 'info');
    _scheduleSave();
  }

  // ── Project Summary (Post-Submit Reflection) ────────────────

  void saveProjectSummary(ProjectSummary summary) {
    final existing = state.projectSummaries.any((s) => s.id == summary.id);
    final updated = existing
        ? state.projectSummaries.map((s) => s.id == summary.id ? summary : s).toList()
        : [...state.projectSummaries, summary];
    state = state.copyWith(projectSummaries: updated);
    _addProgressLog('Project reflection saved', 'info');
    _scheduleSave();
  }

  // ── Trial / Tier ─────────────────────────────────────────────

  void startTrial() {
    if (state.trialStartedAt != null) return; // Already started
    state = state.copyWith(
      trialStartedAt: DateTime.now().toIso8601String(),
    );
    _addProgressLog('7-day free trial started', 'info');
    _scheduleSave();
  }

  // ── Logout ──────────────────────────────────────────────────

  void logout() {
    _syncDebounce?.cancel();
    final storage = _ref.read(storageServiceProvider);
    storage.remove(AppConstants.storageKey);
    _ref.read(apiServiceProvider).setAuthToken(null);
    state = _buildInitialSession();
  }

  // ── Progress Log ─────────────────────────────────────────────

  void _addProgressLog(String message, String stage) {
    final entry = ProgressLogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${message.hashCode}',
      at: DateTime.now(),
      message: message,
      stage: stage,
    );
    final log = [entry, ...state.progressLog].take(300).toList();
    state = state.copyWith(progressLog: log);
  }

  // ── Persistence ──────────────────────────────────────────────

  void _scheduleSave() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(AppConstants.syncDebounce, _save);
  }

  void _save() {
    final storage = _ref.read(storageServiceProvider);
    storage.setString(AppConstants.storageKey, jsonEncode(state.toJson()));
    _ref.read(syncServiceProvider).scheduleSync(state);
    try {
      _scheduleNotifications();
    } catch (_) {
      // Notifications unavailable (e.g., web without Firebase config)
    }
  }

  void saveNow() {
    _syncDebounce?.cancel();
    _save();
  }

  // ── Notification Scheduling ──────────────────────────────────
  void _scheduleNotifications() {
    try {
    final notifications = _ref.read(notificationServiceProvider);
    // Cancel all previous notifications first to avoid duplicates
    notifications.cancelAllNotifications();

    // 1. Deadline Warning (24 hours before)
    final deadline = tz.TZDateTime.from(DateTime.parse(state.deadline), tz.local);
    notifications.scheduleDeadlineWarning(deadline);

    // 2. Stats Ready (7 days after submission)
    if (state.submittedAt != null) {
      final statsUnlockDate = tz.TZDateTime.from(state.statsUnlockDate, tz.local);
      notifications.scheduleStatsReadyNotification(statsUnlockDate);
    }

    // 3. Workflow Reminders (for each incomplete task)
    if (state.selectedPromptId != null && !state.isSubmitted) {
      for (var task in state.workflow) {
        if (!task.done) {
          // Simplified: schedule for next occurrence of task.day, 9 AM
          // This needs more robust parsing of 'Friday or Saturday' etc.
          // For now, assume single day or just use the first word
          final day = task.day.split(' ')[0];
          notifications.scheduleWorkflowReminder(task.id, task.label, day);
        }
      }
    }
    } catch (e) {
      // Notifications may fail on web — don't block app
      debugPrint('[Notifications] Scheduling failed: $e');
    }
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }
}

// ── Convenience selectors ────────────────────────────────────

final currentRankProvider = Provider((ref) {
  return ref.watch(userSessionProvider).currentRank;
});

final streakProvider = Provider((ref) {
  return ref.watch(userSessionProvider).streak;
});

final achievementsProvider = Provider((ref) {
  return ref.watch(userSessionProvider).achievements;
});

final isAdminProvider = Provider((ref) {
  return ref.watch(userSessionProvider).isAdmin;
});
