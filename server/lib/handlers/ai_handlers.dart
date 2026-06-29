// ============================================================
// RAWBY — AI Chat Handler (Groq / llama-3.3-70b-versatile)
// Real conversation with full message history.
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

const _json = {'content-type': 'application/json'};

const _chatSystemPrompt = '''
You are Aurora, the in-app filmmaking co-pilot for RAWBY (a weekly challenge for SOLO videographers who shoot, edit, grade and post entirely alone). You are a world-class solo filmmaker, editor, colourist and short-form strategist rolled into one. The user came to you because they're stuck — give them an answer good enough that they DON'T have to figure it out themselves.

HOW YOU ANSWER — this is the whole job:
- Be concrete and technical. Never give generic advice. Name actual numbers and moves: shutter 1/50 at 24fps (180° rule), ISO, aperture, ND strength, focal length, white balance, frame rate for slow-mo (60/120fps), specific lenses, mic placement, dialogue vs ambient levels (-12 to -6 dB), edit techniques (J/L cuts, match cuts, speed ramps, whip pans), colour moves (lift/gamma/gain, contrast, saturation, a LUT to start from, what to watch on the scopes).
- Solve for ONE person with no crew: tripod + timer/intervalometer, hide-the-camera tricks, talking to camera, getting yourself in the frame, gorillapod/surface mounts, remote shutter.
- Give a usable plan, not a lecture: a tight shot list, a 3-4 step recipe, or an exact setting — whatever the question needs. Lead with the answer, then the why if it helps.
- Use the Context line at the end of the user's message. Tailor to the gear they actually own (don't suggest kit they don't have without flagging it as optional), their location and the season, and their current prompt + how many days are left (early week = ideas/shot-planning; mid = editing/sound; late = grade/polish/publish, and if they're late, prioritise finishing over perfection). Don't pitch ideas close to films they've already made.
- If the request is too vague to nail, ask ONE sharp clarifying question — then still give your best concrete starting point so they're never empty-handed.
- Always end with the clear next action.

You also know the app: holiday mode (plan a trip ahead → "Plan a trip" saves a date + filming window and the prompt drops in automatically that day), Levels (Sequence 10 / Short Story 30 / Story+Character 50 / Big Project 150 pts), late penalties (x0.9 day 1, x0.75 day 2, x0.5 day 3+), and where things live (Prompts, Gear, Ranks, Settings, Ideas).

STYLE:
- Talk like a sharp DP friend on set — warm, fast, opinionated. No corporate filler, no "as an AI", no hedging, no restating the question.
- Plain text only (the chat renders no markdown): no asterisks, hashes or bold. Short paragraphs and simple numbered steps (1. 2. 3.) are fine.
- Be as long as the answer genuinely needs and no longer. A precise 5-line answer beats a vague 15-line one. Don't pad.
''';

const _skillSystemPrompt = '''
You are Aurora, a filmmaking coach inside the RAWBY app. The user is asking for a personalised skill improvement plan.

Be specific, actionable, and direct. Give a concrete plan for the next 1-2 weeks targeting their focus area. Reference their actual stats when they are provided. Keep the response under 200 words. No markdown formatting.
''';

const _reelReviewPrompt = '''
You are Aurora doing a final review of a SOLO videographer's near-finished video before they post it as an Instagram Reel (vertical 9:16). You are shown several frames sampled in order from the start to the end of the clip — treat frame 1 as the opening/hook and the last as the ending.

Judge only what you can actually see in the frames. Be concrete and honest — this is their last check before it goes public. Cover, in this order, as short numbered points:
1. Hook — does frame 1 stop the scroll in the first second? If not, what to change.
2. Framing & composition — headroom, horizons, thirds, subject placement; anything off.
3. Exposure & colour — too dark/blown, white balance, flat/needs contrast or grade.
4. Safe areas — is key subject/text clear of where Instagram puts UI (top status, bottom caption/buttons, right action rail)?
5. Pacing & ending — from the spread of frames, does it look like it moves, and does the last frame land or just stop?
6. Caption + first-line hook — give 2 specific options.

Finish with a clear verdict: POST IT or FIX FIRST, plus the single highest-impact change. Plain text only, no markdown symbols. Be tight.
''';

Future<String> _callGroqVision({
  required String systemPrompt,
  required List<String> images,
  required String userText,
  int maxTokens = 900,
}) async {
  final key = Platform.environment['GROQ_API_KEY'];
  if (key == null || key.isEmpty) throw StateError('GROQ_API_KEY not set');

  final content = <Map<String, dynamic>>[
    {'type': 'text', 'text': userText},
    ...images.map((img) => {
          'type': 'image_url',
          'image_url': {'url': img},
        }),
  ];

  final res = await http.post(
    Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
      'temperature': 0.6,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': content},
      ],
    }),
  );

  if (res.statusCode >= 400) throw StateError('Groq vision ${res.statusCode}: ${res.body}');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (((data['choices'] as List).first as Map)['message']['content'] as String).trim();
}

String _buildContextNote(Map<String, dynamic> ctx) {
  final parts = <String>[];
  if (ctx['displayName'] != null && (ctx['displayName'] as String).isNotEmpty) {
    parts.add('name: ${ctx['displayName']}');
  }
  if (ctx['rank'] != null) parts.add('rank: ${ctx['rank']}');
  if (ctx['totalScore'] != null) parts.add('total score: ${ctx['totalScore']} pts');
  if (ctx['streak'] != null) parts.add('streak: ${ctx['streak']} weeks');
  if (ctx['completedWeeks'] != null) parts.add('weeks completed: ${ctx['completedWeeks']}');
  if (ctx['avgLikes'] != null) parts.add('avg likes: ${ctx['avgLikes']}');
  if (ctx['regensLeft'] != null) parts.add('regens left this week: ${ctx['regensLeft']}');
  if (ctx['daysLeft'] != null) parts.add('days until deadline: ${ctx['daysLeft']}');
  if (ctx['promptLevel'] != null) parts.add('current prompt level: ${ctx['promptLevel']}');
  if (ctx['promptText'] != null) {
    final t = (ctx['promptText'] as String).trim();
    if (t.isNotEmpty) {
      final preview = t.length > 400 ? '${t.substring(0, 400)}...' : t;
      parts.add('active prompt: "$preview"');
    }
  }
  if (ctx['note'] != null && (ctx['note'] as String).trim().isNotEmpty) {
    parts.add('quick note: "${(ctx['note'] as String).trim()}"');
  }
  if (ctx['location'] != null && (ctx['location'] as String).trim().isNotEmpty) {
    parts.add('shoots around: ${ctx['location']}');
  }
  if (ctx['style'] != null && (ctx['style'] as String).trim().isNotEmpty) {
    parts.add('style: ${ctx['style']}');
  }

  String joinList(dynamic v, {int max = 6}) {
    if (v is! List) return '';
    final items = v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).take(max).toList();
    return items.join('; ');
  }

  final gear = joinList(ctx['gear']);
  if (gear.isNotEmpty) parts.add('owns gear: $gear');
  final films = joinList(ctx['films']);
  if (films.isNotEmpty) parts.add('recent films: $films');
  final memory = joinList(ctx['memory']);
  if (memory.isNotEmpty) parts.add('remember: $memory');
  final trips = joinList(ctx['trips']);
  if (trips.isNotEmpty) parts.add('upcoming trips: $trips');

  if (parts.isEmpty) return '';
  return '[Context: ${parts.join(' | ')}]';
}

Future<String> _callGroq({
  required String systemPrompt,
  required List<Map<String, dynamic>> messages,
  int maxTokens = 400,
}) async {
  final key = Platform.environment['GROQ_API_KEY'];
  if (key == null || key.isEmpty) throw StateError('GROQ_API_KEY not set');

  final res = await http.post(
    Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'temperature': 0.75,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
    }),
  );

  if (res.statusCode >= 400) {
    throw StateError('Groq ${res.statusCode}: ${res.body}');
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final reply = ((data['choices'] as List).first as Map)['message']['content'] as String;
  return reply.trim();
}

Future<String> _callClaude({
  required String systemPrompt,
  required List<Map<String, dynamic>> messages,
  int maxTokens = 400,
}) async {
  final key = Platform.environment['ANTHROPIC_API_KEY'];
  if (key == null || key.isEmpty) throw StateError('ANTHROPIC_API_KEY not set');

  final res = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'x-api-key': key,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'claude-sonnet-4-6',
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': messages,
    }),
  );

  if (res.statusCode >= 400) {
    throw StateError('Anthropic ${res.statusCode}: ${res.body}');
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final content = (data['content'] as List).first as Map;
  return (content['text'] as String).trim();
}

/// Route a chat through the owner's Claude subscription via the Agent SDK
/// bridge (see /claude-bridge). Flattens the conversation into one transcript
/// prompt since the SDK takes a single prompt string.
Future<String> _callClaudeBridge({
  required String bridgeUrl,
  required String systemPrompt,
  required List<Map<String, dynamic>> messages,
}) async {
  final buf = StringBuffer();
  for (final m in messages) {
    final role = (m['role'] == 'user') ? 'User' : 'Aurora';
    buf.writeln('$role: ${m['content']}');
    buf.writeln();
  }
  buf.write('Aurora:');

  final secret = Platform.environment['BRIDGE_SECRET'] ?? '';
  final base = bridgeUrl.replaceAll(RegExp(r'/+$'), '');
  final res = await http
      .post(
        Uri.parse('$base/chat'),
        headers: {
          'Content-Type': 'application/json',
          if (secret.isNotEmpty) 'X-Bridge-Secret': secret,
        },
        body: jsonEncode({'system': systemPrompt, 'prompt': buf.toString()}),
      )
      .timeout(const Duration(seconds: 120));

  if (res.statusCode >= 400) {
    throw StateError('bridge ${res.statusCode}: ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final reply = (data['reply'] as String?)?.trim() ?? '';
  if (reply.isEmpty) throw StateError('bridge returned empty reply');
  return reply;
}

Future<Response> handleAiChat(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final rawMessages = body['messages'] as List<dynamic>? ?? [];
    final ctx = body['context'] as Map<String, dynamic>? ?? {};
    final provider = (body['provider'] as String? ?? 'groq').toLowerCase();

    if (rawMessages.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'messages required'}), headers: _json);
    }

    final messages = rawMessages
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    // Inject context note into the first user message
    final contextNote = _buildContextNote(ctx);
    if (contextNote.isNotEmpty) {
      for (int i = 0; i < messages.length; i++) {
        if (messages[i]['role'] == 'user') {
          messages[i] = {
            'role': 'user',
            'content': '${messages[i]['content']}\n\n$contextNote',
          };
          break;
        }
      }
    }

    final bridgeUrl = Platform.environment['CLAUDE_BRIDGE_URL'];
    String reply;
    if (provider == 'claude' && bridgeUrl != null && bridgeUrl.isNotEmpty) {
      // Route through the owner's Claude subscription (Agent SDK bridge).
      // If it fails for any reason, fall back to Groq so Aurora never breaks.
      try {
        reply = await _callClaudeBridge(
          bridgeUrl: bridgeUrl,
          systemPrompt: _chatSystemPrompt,
          messages: messages,
        );
      } catch (e) {
        stderr.writeln('[ai-chat] bridge failed, falling back to groq: $e');
        reply = await _callGroq(systemPrompt: _chatSystemPrompt, messages: messages, maxTokens: 900);
      }
    } else if (provider == 'claude') {
      reply = await _callClaude(systemPrompt: _chatSystemPrompt, messages: messages, maxTokens: 900);
    } else {
      reply = await _callGroq(systemPrompt: _chatSystemPrompt, messages: messages, maxTokens: 900);
    }

    return Response.ok(jsonEncode({'reply': reply}), headers: _json);
  } catch (e, st) {
    stderr.writeln('[ai-chat] $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: _json,
    );
  }
}

Future<Response> handleAnalyzeReel(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final frames = (body['frames'] as List?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? [];
    final caption = (body['caption'] as String? ?? '').trim();
    if (frames.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'frames required'}), headers: _json);
    }
    final userText =
        'Here are ${frames.length} frames sampled in order from the start to the end of my near-final vertical video.'
        '${caption.isNotEmpty ? ' My planned caption: "$caption".' : ''}'
        ' Give me your pre-post review.';
    final reply = await _callGroqVision(
      systemPrompt: _reelReviewPrompt,
      images: frames.take(6).toList(),
      userText: userText,
    );
    return Response.ok(jsonEncode({'feedback': reply}), headers: _json);
  } catch (e, st) {
    stderr.writeln('[analyze-reel] $e\n$st');
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: _json);
  }
}

Future<Response> handleSkillFeedback(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final focusArea = body['focusArea'] as String? ?? 'general filmmaking';
    final notes = body['notes'] as String? ?? '';
    final stats = body['stats'] as Map<String, dynamic>? ?? {};
    final provider = (body['provider'] as String? ?? 'groq').toLowerCase();

    final userMessage = [
      'Focus area: $focusArea',
      if (notes.isNotEmpty) 'Additional notes: $notes',
      if (stats.isNotEmpty) 'Stats: total score ${stats['totalScore'] ?? 0} pts, '
          'avg likes ${stats['avgLikes'] ?? 0}, streak ${stats['streak'] ?? 0} weeks, '
          '${stats['projectsCompleted'] ?? 0} projects completed.',
    ].join('\n');

    final reply = provider == 'claude'
        ? await _callClaude(
            systemPrompt: _skillSystemPrompt,
            messages: [{'role': 'user', 'content': userMessage}],
            maxTokens: 500,
          )
        : await _callGroq(
            systemPrompt: _skillSystemPrompt,
            messages: [{'role': 'user', 'content': userMessage}],
            maxTokens: 500,
          );

    return Response.ok(jsonEncode({'feedback': reply}), headers: _json);
  } catch (e, st) {
    stderr.writeln('[skill-feedback] $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: _json,
    );
  }
}
