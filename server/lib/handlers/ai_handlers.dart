import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';

final _json = {'content-type': 'application/json'};
final _rng = Random();

// ── Smart rule-based chat responses ─────────────────────────

const _greetings = [
  "Hey! I'm your RAWBY AI coach. Ask me anything about your filmmaking progress.",
  "Hi there! Ready to talk about your creative journey?",
  "Hey filmmaker! What's on your mind?",
];

const _scoreAdvice = [
  "Your score comes from likes × prompt points × timing. More likes = more points, but submitting on time matters — late penalties cut your score by up to 70%.",
  "The best way to grow your score is consistency. Complete every week on time and your streak multiplier stays healthy.",
  "Don't overlook the prompt difficulty. Narrative prompts are worth 150 pts vs 50 for Sequences — harder challenge, bigger reward.",
];

const _filmingTips = [
  "Golden hour light is your best friend. 30 minutes after sunrise and before sunset — the quality is unmatched with zero effort.",
  "For Sequences, plan your shots before filming. Know the beginning, middle, and end before you press record.",
  "Movement creates emotion. A slow push-in builds tension; a pull-back reveals scale. Use these intentionally.",
  "Audio is 50% of the experience. Even a phone mic in a quiet room beats a camera mic in a noisy one.",
  "Constraints breed creativity. One lens, one location, one subject — limitations force you to find solutions.",
];

const _motivationPhrases = [
  "Every great filmmaker started where you are. The difference is they kept shooting.",
  "Consistency beats perfection. Done is better than perfect — ship the reel.",
  "Your audience is waiting. They don't need perfect, they need your perspective.",
  "The camera is just a tool. The story is already inside you.",
];

const _rankAdvice = [
  "Focus on completing projects consistently — streaks are the fastest path to the next rank.",
  "Higher ranks unlock recognition on the leaderboard. Keep grinding!",
  "Your rank reflects your commitment. Each completed week is a step up.",
];

String _pick(List<String> list) => list[_rng.nextInt(list.length)];

String _generateResponse(String message, Map<String, dynamic> context) {
  final msg = message.toLowerCase();
  final score = context['totalScore'] as int? ?? 0;
  final streak = context['streak'] as int? ?? 0;
  final avgLikes = context['avgLikes'] as int? ?? 0;
  final rank = context['rank'] as String? ?? 'Starter';

  // Greeting
  if (msg.contains('hello') || msg.contains('hi') || msg.contains('hey')) {
    return _pick(_greetings);
  }

  // Score / points
  if (msg.contains('score') || msg.contains('point') || msg.contains('rank')) {
    final extra = score > 0
        ? " You're at $score pts as a $rank — ${score > 200 ? 'solid progress!' : 'keep building!'}"
        : '';
    return '${_pick(_scoreAdvice)}$extra';
  }

  // Likes / engagement
  if (msg.contains('like') || msg.contains('engagement') || msg.contains('view')) {
    final likeNote = avgLikes > 0
        ? "Your average is $avgLikes likes per reel. "
        : '';
    return '${likeNote}Engagement grows with consistency and hooks. Open with movement or a question in the first second — that alone can double watch time.';
  }

  // Filming tips
  if (msg.contains('film') || msg.contains('shoot') || msg.contains('camera') ||
      msg.contains('shot') || msg.contains('tip') || msg.contains('technique')) {
    return _pick(_filmingTips);
  }

  // Motivation / stuck
  if (msg.contains('stuck') || msg.contains('motivat') || msg.contains('help') ||
      msg.contains('idea') || msg.contains('inspir')) {
    final streakNote = streak > 1 ? " You're on a $streak-week streak — don't break it now!" : '';
    return '${_pick(_motivationPhrases)}$streakNote';
  }

  // Streak
  if (msg.contains('streak')) {
    final s = streak > 0
        ? "You're on a $streak-week streak — impressive! Keep it going by submitting before each Friday deadline."
        : "Start your streak by submitting this week's project. Streaks are the core of RAWBY — they show real commitment.";
    return s;
  }

  // Progress / improvement
  if (msg.contains('improv') || msg.contains('better') || msg.contains('progress') || msg.contains('grow')) {
    return _pick(_rankAdvice);
  }

  // Default
  return "That's a great question. My best advice: focus on the fundamentals — good light, intentional framing, and submit on time. Compound consistency is the real growth hack in filmmaking.";
}

Future<Response> handleAiChat(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final message = body['message'] as String? ?? '';
    final context = body['context'] as Map<String, dynamic>? ?? {};

    if (message.trim().isEmpty) {
      return Response(400, body: jsonEncode({'error': 'message required'}), headers: _json);
    }

    final reply = _generateResponse(message, context);

    return Response.ok(
      jsonEncode({'reply': reply, 'source': 'rawby-ai'}),
      headers: _json,
    );
  } catch (e) {
    return Response(500, body: jsonEncode({'error': 'Internal error'}), headers: _json);
  }
}

Future<Response> handleSkillFeedback(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final focusArea = body['focusArea'] as String? ?? 'general';
    final notes = body['notes'] as String? ?? '';
    final stats = body['stats'] as Map<String, dynamic>? ?? {};

    final totalScore = stats['totalScore'] as int? ?? 0;
    final avgLikes = stats['avgLikes'] as int? ?? 0;

    final feedback = _buildSkillFeedback(focusArea, notes, totalScore, avgLikes);

    return Response.ok(
      jsonEncode({'feedback': feedback, 'source': 'rawby-ai'}),
      headers: _json,
    );
  } catch (e) {
    return Response(500, body: jsonEncode({'error': 'Internal error'}), headers: _json);
  }
}

String _buildSkillFeedback(String focusArea, String notes, int totalScore, int avgLikes) {
  final area = focusArea.toLowerCase();

  if (area.contains('cinemat') || area.contains('shot') || area.contains('camera')) {
    return "For cinematography, master the three pillars first: exposure (ISO/aperture/shutter), composition (rule of thirds, leading lines), and movement (smooth pans, motivated handheld). ${notes.isNotEmpty ? 'Based on your notes: focus on one element per shoot to build muscle memory.' : 'Pick one to focus on this week.'}";
  }

  if (area.contains('edit') || area.contains('post')) {
    return "Strong editing starts before you open your editor: shoot with cuts in mind. In post, cut on action, match sound bridges, and let silence breathe. ${avgLikes > 50 ? 'With your $avgLikes avg likes, your edits are resonating — keep the pacing tight.' : 'Focus on pacing — most first edits are 30% too long.'}";
  }

  if (area.contains('story') || area.contains('narrat') || area.contains('script')) {
    return "Great stories have a clear want (character goal), an obstacle, and a change. Even a 30-second reel needs this arc. ${notes.isNotEmpty ? 'Your note "$notes" suggests you\'re already thinking structurally — that\'s the right instinct.' : 'Try outlining in three sentences: who wants what, what stops them, what happens.'}";
  }

  if (area.contains('light')) {
    return "Lighting is the single fastest way to upgrade your footage. Start with natural light: face a window for interviews, use golden hour for exteriors. If shooting indoors, a single \$50 LED panel can transform your image.";
  }

  if (area.contains('audio') || area.contains('sound')) {
    return "Audio makes or breaks a video. Rule: never use built-in camera mic outdoors. A lavalier for \$20 or a shotgun mic for \$80 will make your content sound professional. ${totalScore > 100 ? 'At your level, audio is the next frontier.' : 'Fix audio before anything else — viewers tolerate shaky footage but not bad audio.'}";
  }

  return "To improve in $focusArea: study one reference filmmaker per week, analyze what makes their work effective, then deliberately replicate one technique. Conscious practice beats random shooting every time. ${notes.isNotEmpty ? 'Your specific focus: $notes — keep that goal in mind on your next shoot.' : ''}";
}
