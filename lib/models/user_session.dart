// ============================================================
// RAWBY — UserSession Model
// The single source of truth for all user state.
// Mirrors the JS state object from app2.js.
// ============================================================
import 'package:hive/hive.dart';
import 'prompt_model.dart';
import 'project_model.dart';
import 'gear_model.dart';
import 'achievement_model.dart';
import '../constants/ranks.dart';
import '../constants/app_constants.dart';


@HiveType(typeId: 0)
class UserPreferences extends HiveObject {
  @HiveField(0)
  String theme; // 'light' or 'dark'

  @HiveField(1)
  String accent; // 'green', 'grey', 'basic'

  @HiveField(2)
  String language; // 'en'

  @HiveField(3)
  String promptLanguage; // 'en'

  @HiveField(4)
  String cycleDay; // 'Friday' (default)

  @HiveField(5)
  String region; // e.g. 'Northern Europe', 'US South'

  @HiveField(6)
  String timezone; // e.g. 'Europe/Budapest'

  @HiveField(7)
  bool seasonalPrompts;

  @HiveField(8)
  String filmmakingGoal;

  @HiveField(9)
  String contentType;

  // Social handles
  @HiveField(10)
  String instagramHandle;

  @HiveField(11)
  String youtubeHandle;

  // Profile sharing toggles
  @HiveField(12)
  bool showScore;

  @HiveField(13)
  bool showStreak;

  @HiveField(14)
  bool showGear;

  @HiveField(15)
  bool showHistory;

  @HiveField(16)
  bool showInstagram;

  @HiveField(17)
  bool showYoutube;

  @HiveField(18)
  String bio;

  @HiveField(19)
  bool showBio;

  @HiveField(20)
  bool showPrompts; // show past prompts in history

  @HiveField(21)
  bool showAchievements;

  @HiveField(22)
  bool showEngagement; // total likes, views, avg

  UserPreferences({
    this.theme = 'dark',
    this.accent = 'cinema',
    this.language = 'en',
    this.promptLanguage = 'en',
    this.cycleDay = 'Friday',
    this.region = '',
    this.timezone = AppConstants.hungaryTz,
    this.seasonalPrompts = false,
    this.filmmakingGoal = '',
    this.contentType = '',
    this.instagramHandle = '',
    this.youtubeHandle = '',
    this.showScore = true,
    this.showStreak = true,
    this.showGear = false,
    this.showHistory = true,
    this.showInstagram = true,
    this.showYoutube = true,
    this.bio = '',
    this.showBio = true,
    this.showPrompts = true,
    this.showAchievements = true,
    this.showEngagement = true,
  });

  UserPreferences copyWith({
    String? theme,
    String? accent,
    String? language,
    String? promptLanguage,
    String? cycleDay,
    String? region,
    String? timezone,
    bool? seasonalPrompts,
    String? filmmakingGoal,
    String? contentType,
    String? instagramHandle,
    String? youtubeHandle,
    bool? showScore,
    bool? showStreak,
    bool? showGear,
    bool? showHistory,
    bool? showInstagram,
    bool? showYoutube,
    String? bio,
    bool? showBio,
    bool? showPrompts,
    bool? showAchievements,
    bool? showEngagement,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      language: language ?? this.language,
      promptLanguage: promptLanguage ?? this.promptLanguage,
      cycleDay: cycleDay ?? this.cycleDay,
      region: region ?? this.region,
      timezone: timezone ?? this.timezone,
      seasonalPrompts: seasonalPrompts ?? this.seasonalPrompts,
      filmmakingGoal: filmmakingGoal ?? this.filmmakingGoal,
      contentType: contentType ?? this.contentType,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      youtubeHandle: youtubeHandle ?? this.youtubeHandle,
      showScore: showScore ?? this.showScore,
      showStreak: showStreak ?? this.showStreak,
      showGear: showGear ?? this.showGear,
      showHistory: showHistory ?? this.showHistory,
      showInstagram: showInstagram ?? this.showInstagram,
      showYoutube: showYoutube ?? this.showYoutube,
      bio: bio ?? this.bio,
      showBio: showBio ?? this.showBio,
      showPrompts: showPrompts ?? this.showPrompts,
      showAchievements: showAchievements ?? this.showAchievements,
      showEngagement: showEngagement ?? this.showEngagement,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        theme: json['theme'] as String? ?? 'dark',
        accent: _validateAccent(json['accent'] as String?),
        language: json['language'] as String? ?? 'en',
        promptLanguage: json['promptLanguage'] as String? ?? 'en',
        cycleDay: json['cycleDay'] as String? ?? 'Friday',
        region: json['region'] as String? ?? '',
        timezone: json['timezone'] as String? ?? AppConstants.hungaryTz,
        seasonalPrompts: json['seasonalPrompts'] as bool? ?? false,
        filmmakingGoal: json['filmmakingGoal'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        instagramHandle: json['instagramHandle'] as String? ?? '',
        youtubeHandle: json['youtubeHandle'] as String? ?? '',
        showScore: json['showScore'] as bool? ?? true,
        showStreak: json['showStreak'] as bool? ?? true,
        showGear: json['showGear'] as bool? ?? false,
        showHistory: json['showHistory'] as bool? ?? true,
        showInstagram: json['showInstagram'] as bool? ?? true,
        showYoutube: json['showYoutube'] as bool? ?? true,
        bio: json['bio'] as String? ?? '',
        showBio: json['showBio'] as bool? ?? true,
        showPrompts: json['showPrompts'] as bool? ?? true,
        showAchievements: json['showAchievements'] as bool? ?? true,
        showEngagement: json['showEngagement'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'accent': accent,
        'language': language,
        'promptLanguage': promptLanguage,
        'cycleDay': cycleDay,
        'region': region,
        'timezone': timezone,
        'seasonalPrompts': seasonalPrompts,
        'filmmakingGoal': filmmakingGoal,
        'contentType': contentType,
        'instagramHandle': instagramHandle,
        'youtubeHandle': youtubeHandle,
        'showScore': showScore,
        'showStreak': showStreak,
        'showGear': showGear,
        'showHistory': showHistory,
        'showInstagram': showInstagram,
        'showYoutube': showYoutube,
        'bio': bio,
        'showBio': showBio,
        'showPrompts': showPrompts,
        'showAchievements': showAchievements,
        'showEngagement': showEngagement,
      };

  static String _validateAccent(String? accent) {
    const valid = {'green', 'grey', 'basic', 'cinema'};
    return valid.contains(accent) ? accent! : 'cinema';
  }
}

@HiveType(typeId: 11)
class AiSettings extends HiveObject {
  @HiveField(0)
  String provider; // 'groq' or 'openai'

  @HiveField(1)
  String model;

  @HiveField(2)
  bool autoGenerate;

  AiSettings({
    this.provider = 'groq',
    this.model = 'llama-3.3-70b-versatile',
    this.autoGenerate = true,
  });

  AiSettings copyWith({
    String? provider,
    String? model,
    bool? autoGenerate,
  }) {
    return AiSettings(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      autoGenerate: autoGenerate ?? this.autoGenerate,
    );
  }

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
        provider: json['provider'] as String? ?? 'groq',
        model: json['model'] as String? ?? 'llama-3.3-70b-versatile',
        autoGenerate: json['autoGenerate'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        'autoGenerate': autoGenerate,
      };
}

@HiveType(typeId: 12)
class SkillEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String projectId;

  SkillEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    this.projectId = '',
  });

  factory SkillEntry.fromJson(Map<String, dynamic> json) => SkillEntry(
        id: json['id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        projectId: json['projectId'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'projectId': projectId,
      };
}

@HiveType(typeId: 13)
class ProgressLogEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime at;

  @HiveField(2)
  final String message;

  @HiveField(3)
  final String stage; // 'info', 'prompt', 'submit', 'stats'

  ProgressLogEntry({
    required this.id,
    required this.at,
    required this.message,
    this.stage = 'info',
  });

  factory ProgressLogEntry.fromJson(Map<String, dynamic> json) =>
      ProgressLogEntry(
        id: json['id'] as String? ?? '',
        at: json['at'] != null
            ? DateTime.parse(json['at'] as String)
            : DateTime.now(),
        message: json['message'] as String? ?? '',
        stage: json['stage'] as String? ?? 'info',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'message': message,
        'stage': stage,
      };
}

@HiveType(typeId: 15)
class ProjectSummary extends HiveObject {
  @HiveField(0)
  final String id; // matches weekStart of the project

  @HiveField(1)
  final String howCreated; // "How did you create this project?"

  @HiveField(2)
  final String whatChanged; // "What did you change or try differently?"

  @HiveField(3)
  final int rating; // 1-10

  @HiveField(4)
  final String comparison; // 'better', 'same', 'worse'

  @HiveField(5)
  final String feeling; // "How did you feel?"

  @HiveField(6)
  final String createdAt; // ISO

  ProjectSummary({
    required this.id,
    this.howCreated = '',
    this.whatChanged = '',
    this.rating = 5,
    this.comparison = 'same',
    this.feeling = '',
    required this.createdAt,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
        id: json['id'] as String? ?? '',
        howCreated: json['howCreated'] as String? ?? '',
        whatChanged: json['whatChanged'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        comparison: json['comparison'] as String? ?? 'same',
        feeling: json['feeling'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'howCreated': howCreated,
        'whatChanged': whatChanged,
        'rating': rating,
        'comparison': comparison,
        'feeling': feeling,
        'createdAt': createdAt,
      };
}

// ── Main UserSession ─────────────────────────────────────────

@HiveType(typeId: 14)
class UserSession extends HiveObject {
  // ── Auth / Profile ──────────────────────────────────────────
  @HiveField(0)
  String userId;

  @HiveField(1)
  String username;

  @HiveField(2)
  String displayName;

  @HiveField(3)
  String email;

  @HiveField(4)
  String role; // 'user' or 'admin'

  @HiveField(5)
  String instagramProfile;

  // ── Season / Cycle ──────────────────────────────────────────
  @HiveField(6)
  String seasonStart; // ISO string

  @HiveField(7)
  String weekStart; // ISO string

  @HiveField(8)
  String deadline; // ISO string

  // ── Current Week ────────────────────────────────────────────
  @HiveField(9)
  List<PromptModel> prompts;

  @HiveField(10)
  String? selectedPromptId;

  @HiveField(11)
  List<WorkflowTask> workflow;

  @HiveField(12)
  String? submittedAt; // ISO string

  @HiveField(13)
  String? statsRecordedAt; // ISO string

  @HiveField(14)
  int likes;

  @HiveField(15)
  int views;

  @HiveField(16)
  String instagramUrl;

  @HiveField(17)
  List<ProgressLogEntry> progressLog;

  // ── Scoring ─────────────────────────────────────────────────
  @HiveField(18)
  int totalScore;

  @HiveField(19)
  int completedWeeks;

  // ── History & Stats ─────────────────────────────────────────
  @HiveField(20)
  List<HistoryEntry> history;

  @HiveField(21)
  List<PendingStats> pendingStats;

  // ── Big Projects ────────────────────────────────────────────
  @HiveField(22)
  List<BigProject> bigProjects;

  // ── Gear ────────────────────────────────────────────────────
  @HiveField(23)
  List<GearItem> gearPurchases;

  @HiveField(24)
  List<Subscription> subscriptions;

  @HiveField(25)
  List<String> currentGearUsed; // gear IDs used in current project

  // ── Skills ──────────────────────────────────────────────────
  @HiveField(26)
  List<SkillEntry> skillEntries;

  @HiveField(27)
  String skillAiPlan;

  // ── Prompts / Regen ─────────────────────────────────────────
  @HiveField(28)
  String regenWeek; // ISO string of week when regens were counted

  @HiveField(29)
  int regenCount;

  @HiveField(30)
  bool autoGenPending;

  @HiveField(31)
  List<PromptModel> savedPrompts; // Idea Bank

  // ── Project Window ──────────────────────────────────────────
  @HiveField(32)
  ProjectStartWindow? projectStartWindow;

  // ── Preferences ─────────────────────────────────────────────
  @HiveField(33)
  UserPreferences preferences;

  // ── AI Settings ─────────────────────────────────────────────
  @HiveField(34)
  AiSettings aiSettings;

  // ── Sync ────────────────────────────────────────────────────
  @HiveField(35)
  DateTime? lastSyncedAt;

  // ── Instagram Posts Cache (admin) ───────────────────────────
  @HiveField(36)
  List<Map<String, dynamic>> igPosts;

  @HiveField(37)
  String? igStatsRefreshedAt;

  @HiveField(38)
  bool bigProjectSubmitted;

  @HiveField(39)
  String? promptConfirmedAt; // ISO string — null = not yet confirmed

  @HiveField(40)
  List<String> projectGearUsed; // gear IDs logged after submit

  @HiveField(41)
  List<ProjectSummary> projectSummaries; // post-submit reflections

  @HiveField(42)
  String tier; // 'free' or 'paid'

  @HiveField(43)
  String? trialStartedAt; // ISO — when the 7-day trial began

  @HiveField(44)
  String? subscriptionExpiresAt; // ISO — when paid sub expires

  UserSession({
    this.userId = '',
    this.username = '',
    this.displayName = '',
    this.email = '',
    this.role = 'user',
    this.instagramProfile = '',
    required this.seasonStart,
    required this.weekStart,
    required this.deadline,
    this.prompts = const [],
    this.selectedPromptId,
    this.workflow = const [],
    this.submittedAt,
    this.statsRecordedAt,
    this.likes = 0,
    this.views = 0,
    this.instagramUrl = '',
    this.progressLog = const [],
    this.totalScore = 0,
    this.completedWeeks = 0,
    this.history = const [],
    this.pendingStats = const [],
    this.bigProjects = const [],
    this.gearPurchases = const [],
    this.subscriptions = const [],
    this.currentGearUsed = const [],
    this.skillEntries = const [],
    this.skillAiPlan = '',
    required this.regenWeek,
    this.regenCount = 0,
    this.autoGenPending = true,
    this.savedPrompts = const [],
    this.projectStartWindow,
    required this.preferences,
    required this.aiSettings,
    this.lastSyncedAt,
    this.igPosts = const [],
    this.igStatsRefreshedAt,
    this.bigProjectSubmitted = false,
    this.promptConfirmedAt,
    this.projectGearUsed = const [],
    this.projectSummaries = const [],
    this.tier = 'free',
    this.trialStartedAt,
    this.subscriptionExpiresAt,
  });

  // ── Computed Properties ──────────────────────────────────────

  static const superAdminUsername = 'zaron.films';

  bool get isAdmin => role == 'admin' || username == superAdminUsername;

  bool get isSuperAdmin => username == superAdminUsername;

  String get displayRole {
    if (username == superAdminUsername) return 'Creator';
    if (isAdmin) return 'Admin';
    if (tier == 'paid') return 'Pro';
    return 'Member';
  }

  bool get isPro => tier == 'paid' || isAdmin;

  bool get isSubmitted => submittedAt != null || bigProjectSubmitted;

  bool get isPromptConfirmed => promptConfirmedAt != null;

  bool get isInConfirmationWindow {
    if (projectStartWindow == null || isPromptConfirmed) return false;
    return DateTime.now().isBefore(projectStartWindow!.expiresAt);
  }

  bool get isConfirmationExpired {
    if (projectStartWindow == null || isPromptConfirmed) return false;
    return DateTime.now().isAfter(projectStartWindow!.expiresAt);
  }

  bool get isLocked => isSubmitted || (projectStartWindow != null && isPromptConfirmed);

  BigProject? get activeBigProject {
    try {
      return bigProjects.firstWhere((b) => b.status == 'active');
    } catch (_) {
      return null;
    }
  }

  int get regensLeft =>
      (AppConstants.regenLimit - regenCount).clamp(0, AppConstants.regenLimit);

  RankDefinition get currentRank => Ranks.getRank(totalScore);

  RankDefinition? get nextRank => Ranks.getNextRank(totalScore);

  int get totalLikes => history.fold(0, (sum, h) => sum + h.likes);

  int get totalViews => history.fold(0, (sum, h) => sum + h.views);

  int get maxLikes =>
      history.isEmpty ? 0 : history.map((h) => h.likes).reduce((a, b) => a > b ? a : b);

  int get avgLikes {
    if (history.isEmpty) return 0;
    return (totalLikes / history.length).round();
  }

  int get skillScore {
    return (totalLikes * 3 + totalViews * 0.1 + completedWeeks * 50).round();
  }

  List<HistoryEntry> get scoringHistory =>
      history.where((h) => !h.isTestRun).toList();

  int get streak {
    final scored = scoringHistory
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    if (scored.isEmpty) return 0;
    int s = 1;
    for (int i = 1; i < scored.length; i++) {
      final prev = DateTime.parse(scored[i - 1].weekStart);
      final curr = DateTime.parse(scored[i].weekStart);
      final diff = prev.difference(curr).inDays;
      if (diff >= 5 && diff <= 10) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  bool get statsUnlocked {
    if (submittedAt == null) return false;
    final unlockDate =
        DateTime.parse(deadline).add(const Duration(days: 7));
    return DateTime.now().isAfter(unlockDate);
  }

  bool get statsReady => statsUnlocked && statsRecordedAt == null;

  DateTime get statsUnlockDate =>
      DateTime.parse(deadline).add(const Duration(days: 7));

  double get annualSubscriptionSpend =>
      subscriptions.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.annualCostHuf);

  List<Achievement> get achievements => AchievementDefinitions.buildAll(
        projectCount: scoringHistory.length,
        streak: streak,
        maxLikes: maxLikes,
        gearCount: gearPurchases.length,
        skillEntries: skillEntries.length,
        hasBigProject: bigProjects.any(
            (b) => b.status == 'finished' || b.status == 'submitted'),
        savedPromptsCount: savedPrompts.length,
      );

  bool get isOnTrial {
    if (trialStartedAt == null) return false;
    final start = DateTime.parse(trialStartedAt!);
    return DateTime.now().isBefore(start.add(const Duration(days: 7)));
  }

  bool get isPaid => tier == 'paid' || isAdmin || isOnTrial;

  bool get isFree => !isPaid;

  // ── Serialization ────────────────────────────────────────────

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] != null
        ? UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>)
        : UserPreferences();
    final ai = json['aiSettings'] != null
        ? AiSettings.fromJson(json['aiSettings'] as Map<String, dynamic>)
        : AiSettings();

    return UserSession(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      instagramProfile: json['instagramProfile'] as String? ?? '',
      seasonStart: json['seasonStart'] as String? ?? DateTime.utc(2026, 5, 1).toIso8601String(),
      weekStart: json['weekStart'] as String? ?? DateTime.now().toIso8601String(),
      deadline: json['deadline'] as String? ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      prompts: (json['prompts'] as List<dynamic>?)
              ?.map((e) => PromptModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      selectedPromptId: json['selectedPromptId'] as String?,
      workflow: (json['workflow'] as List<dynamic>?)
              ?.map((e) => WorkflowTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      submittedAt: json['submittedAt'] as String?,
      statsRecordedAt: json['statsRecordedAt'] as String?,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      instagramUrl: json['instagramUrl'] as String? ?? '',
      progressLog: (json['progressLog'] as List<dynamic>?)
              ?.map((e) => ProgressLogEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      completedWeeks: (json['completedWeeks'] as num?)?.toInt() ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingStats: (json['pendingStats'] as List<dynamic>?)
              ?.map((e) => PendingStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bigProjects: (json['bigProjects'] as List<dynamic>?)
              ?.map((e) => BigProject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gearPurchases: (json['gearPurchases'] as List<dynamic>?)
              ?.map((e) => GearItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subscriptions: (json['subscriptions'] as List<dynamic>?)
              ?.map((e) => Subscription.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentGearUsed: (json['currentGearUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      skillEntries: (json['skillEntries'] as List<dynamic>?)
              ?.map((e) => SkillEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      skillAiPlan: json['skillAiPlan'] as String? ?? '',
      regenWeek: json['regenWeek'] as String? ?? DateTime.now().toIso8601String(),
      regenCount: (json['regenCount'] as num?)?.toInt() ?? 0,
      autoGenPending: json['autoGenPending'] as bool? ?? true,
      savedPrompts: (json['savedPrompts'] as List<dynamic>?)
              ?.map((e) => PromptModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: prefs,
      aiSettings: ai,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      igPosts: (json['igPosts'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      igStatsRefreshedAt: json['igStatsRefreshedAt'] as String?,
      bigProjectSubmitted: json['bigProjectSubmitted'] as bool? ?? false,
      promptConfirmedAt: json['promptConfirmedAt'] as String?,
      projectGearUsed: (json['projectGearUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      projectSummaries: (json['projectSummaries'] as List<dynamic>?)
              ?.map((e) => ProjectSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tier: json['tier'] as String? ?? 'free',
      trialStartedAt: json['trialStartedAt'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'email': email,
        'role': role,
        'instagramProfile': instagramProfile,
        'seasonStart': seasonStart,
        'weekStart': weekStart,
        'deadline': deadline,
        'prompts': prompts.map((p) => p.toJson()).toList(),
        'selectedPromptId': selectedPromptId,
        'workflow': workflow.map((t) => t.toJson()).toList(),
        'submittedAt': submittedAt,
        'statsRecordedAt': statsRecordedAt,
        'likes': likes,
        'views': views,
        'instagramUrl': instagramUrl,
        'progressLog': progressLog.map((e) => e.toJson()).toList(),
        'totalScore': totalScore,
        'completedWeeks': completedWeeks,
        'history': history.map((h) => h.toJson()).toList(),
        'pendingStats': pendingStats.map((p) => p.toJson()).toList(),
        'bigProjects': bigProjects.map((b) => b.toJson()).toList(),
        'gearPurchases': gearPurchases.map((g) => g.toJson()).toList(),
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'currentGearUsed': currentGearUsed,
        'skillEntries': skillEntries.map((s) => s.toJson()).toList(),
        'skillAiPlan': skillAiPlan,
        'regenWeek': regenWeek,
        'regenCount': regenCount,
        'autoGenPending': autoGenPending,
        'savedPrompts': savedPrompts.map((p) => p.toJson()).toList(),
        'projectStartWindow': projectStartWindow?.toJson(),
        'preferences': preferences.toJson(),
        'aiSettings': aiSettings.toJson(),
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'igPosts': igPosts,
        'igStatsRefreshedAt': igStatsRefreshedAt,
        'bigProjectSubmitted': bigProjectSubmitted,
        'promptConfirmedAt': promptConfirmedAt,
        'projectGearUsed': projectGearUsed,
        'projectSummaries': projectSummaries.map((s) => s.toJson()).toList(),
        'tier': tier,
        'trialStartedAt': trialStartedAt,
        'subscriptionExpiresAt': subscriptionExpiresAt,
      };

  UserSession copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? email,
    String? role,
    String? instagramProfile,
    String? seasonStart,
    String? weekStart,
    String? deadline,
    List<PromptModel>? prompts,
    String? selectedPromptId,
    List<WorkflowTask>? workflow,
    String? submittedAt,
    String? statsRecordedAt,
    int? likes,
    int? views,
    String? instagramUrl,
    List<ProgressLogEntry>? progressLog,
    int? totalScore,
    int? completedWeeks,
    List<HistoryEntry>? history,
    List<PendingStats>? pendingStats,
    List<BigProject>? bigProjects,
    List<GearItem>? gearPurchases,
    List<Subscription>? subscriptions,
    List<String>? currentGearUsed,
    List<SkillEntry>? skillEntries,
    String? skillAiPlan,
    String? regenWeek,
    int? regenCount,
    bool? autoGenPending,
    List<PromptModel>? savedPrompts,
    ProjectStartWindow? projectStartWindow,
    UserPreferences? preferences,
    AiSettings? aiSettings,
    DateTime? lastSyncedAt,
    List<Map<String, dynamic>>? igPosts,
    String? igStatsRefreshedAt,
    bool? bigProjectSubmitted,
    String? promptConfirmedAt,
    List<String>? projectGearUsed,
    List<ProjectSummary>? projectSummaries,
    String? tier,
    String? trialStartedAt,
    String? subscriptionExpiresAt,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      instagramProfile: instagramProfile ?? this.instagramProfile,
      seasonStart: seasonStart ?? this.seasonStart,
      weekStart: weekStart ?? this.weekStart,
      deadline: deadline ?? this.deadline,
      prompts: prompts ?? this.prompts,
      selectedPromptId: selectedPromptId ?? this.selectedPromptId,
      workflow: workflow ?? this.workflow,
      submittedAt: submittedAt ?? this.submittedAt,
      statsRecordedAt: statsRecordedAt ?? this.statsRecordedAt,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      progressLog: progressLog ?? this.progressLog,
      totalScore: totalScore ?? this.totalScore,
      completedWeeks: completedWeeks ?? this.completedWeeks,
      history: history ?? this.history,
      pendingStats: pendingStats ?? this.pendingStats,
      bigProjects: bigProjects ?? this.bigProjects,
      gearPurchases: gearPurchases ?? this.gearPurchases,
      subscriptions: subscriptions ?? this.subscriptions,
      currentGearUsed: currentGearUsed ?? this.currentGearUsed,
      skillEntries: skillEntries ?? this.skillEntries,
      skillAiPlan: skillAiPlan ?? this.skillAiPlan,
      regenWeek: regenWeek ?? this.regenWeek,
      regenCount: regenCount ?? this.regenCount,
      autoGenPending: autoGenPending ?? this.autoGenPending,
      savedPrompts: savedPrompts ?? this.savedPrompts,
      projectStartWindow: projectStartWindow ?? this.projectStartWindow,
      preferences: preferences ?? this.preferences,
      aiSettings: aiSettings ?? this.aiSettings,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      igPosts: igPosts ?? this.igPosts,
      igStatsRefreshedAt: igStatsRefreshedAt ?? this.igStatsRefreshedAt,
      bigProjectSubmitted: bigProjectSubmitted ?? this.bigProjectSubmitted,
      promptConfirmedAt: promptConfirmedAt ?? this.promptConfirmedAt,
      projectGearUsed: projectGearUsed ?? this.projectGearUsed,
      projectSummaries: projectSummaries ?? this.projectSummaries,
      tier: tier ?? this.tier,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
    );
  }
}
