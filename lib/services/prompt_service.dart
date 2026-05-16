// ============================================================
// RAWBY — Prompt Service
// Handles AI generation (Groq/OpenAI) via Render backend
// and local fallback generation from SCENARIO_TEMPLATES.
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prompt_model.dart';
import '../constants/prompt_templates.dart';
import 'api_service.dart';

final promptServiceProvider = Provider<PromptService>((ref) {
  return PromptService(ref.read(apiServiceProvider));
});

class PromptService {
  final ApiService _api;

  PromptService(this._api);

  // ── AI Generation ────────────────────────────────────────────

  Future<List<PromptModel>> generateAiPrompts({
    required String provider, // 'groq' or 'openai'
    required String model,
    required bool seasonalPrompts,
    required String region,
    required String filmmakingGoal,
    required String contentType,
  }) async {
    final creators = List.of(PromptTemplates.creatorStyles)..shuffle();
    final inspirations = creators.take(3).map((c) => {
          'handle': c.handle,
          'style': c.style,
          'referenceHint': c.referenceHint,
        }).toList();

    final result = await _api.generatePrompts(
      provider: provider,
      model: model,
      inspirations: inspirations,
      seasonalPrompts: seasonalPrompts,
      region: region,
      filmmakingGoal: filmmakingGoal,
      contentType: contentType,
    );

    final raw = result['prompts'] as List<dynamic>?
        ?? result['data'] as List<dynamic>?
        ?? [];

    final levels = ['Sequence', 'Short Story', 'Story + Character'];
    final points = [10, 30, 50];

    return List.generate(raw.length.clamp(0, 3), (i) {
      final item = raw[i] as Map<String, dynamic>;
      final creator = creators[i];

      // Parse songs
      final rawSongs = item['songs'] as List<dynamic>? ?? [];
      final songs = rawSongs.map((s) {
        final sm = s as Map<String, dynamic>;
        return SongSuggestion(
          title: sm['title'] as String? ?? '',
          artist: sm['artist'] as String? ?? '',
          type: sm['type'] as String? ?? 'best_match',
          whyItWorks: sm['whyItWorks'] as String? ?? sm['why'] as String? ?? '',
        );
      }).toList();

      // Parse shots
      final rawShots = item['shots'] as List<dynamic>? ?? [];
      final shots = rawShots.map((s) => s as String).toList();

      // Parse licenseFreeKeywords
      final rawKw = item['licenseFreeKeywords'] as List<dynamic>? ?? [];
      final keywords = rawKw.map((k) => k as String).toList();

      return PromptModel(
        id: 'aip_${DateTime.now().millisecondsSinceEpoch}_$i',
        level: levels[i],
        points: points[i],
        category: item['category'] as String? ?? '',
        inspiration: creator.handle,
        inspirationStyle: creator.style,
        inspirationProfileUrl: creator.profileUrl,
        inspirationReferenceHint: creator.referenceHint,
        text: item['text'] as String? ?? '',
        shots: shots,
        songs: songs,
        licenseFreeKeywords: keywords,
        outcome: item['outcome'] as String? ?? '',
        purpose: item['purpose'] as String? ?? '',
        emotion: item['emotion'] as String? ?? '',
        source: 'ai',
      );
    });
  }

  // ── Local Fallback Generation ────────────────────────────────

  List<PromptModel> generateLocalPrompts() {
    final creators = List.of(PromptTemplates.creatorStyles)..shuffle();
    final insp = creators.take(3).toList();

    PromptModel build(String level, int points, int idx) {
      final templates = PromptTemplates.byLevel(level);
      final seed = DateTime.now().millisecondsSinceEpoch;
      final tpl = templates[(seed + idx * 37) % templates.length];
      final creator = insp[idx];
      return PromptModel(
        id: 'local_${points}_${seed}_$idx',
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

  // ── Custom Prompt ────────────────────────────────────────────

  PromptModel buildCustomPrompt({
    required String text,
    required String level,
  }) {
    final pointsMap = {'Sequence': 10, 'Short Story': 30, 'Story + Character': 50};
    final pts = pointsMap[level] ?? 10;
    return PromptModel(
      id: 'custom_${pts}_${DateTime.now().millisecondsSinceEpoch}',
      level: level,
      points: pts,
      category: 'Custom',
      inspiration: 'You',
      text: text,
      source: 'custom',
    );
  }
}
