// ============================================================
// RAWBY — Prompt Handler
// Routes to Groq or OpenAI with the canonical RAWBY system prompt.
// Falls back to a deterministic local payload if keys missing.
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import '../store.dart';

const _jsonHeaders = {'content-type': 'application/json'};

const _systemPrompt = '''
You write weekly short-film prompts for a solo videographer. Clear, direct English. No jargon. Cinematic but human. Output ONLY a valid JSON array with exactly 3 objects — no markdown, no commentary.

═══════════════════════════════════════
THEME UNIVERSE — pick freely and boldly
═══════════════════════════════════════
Nature & outdoors: forest morning, fog on a river, empty field at golden hour, rain on a window, first snow, tide going out, single tree in wind, muddy trail after rain, birds leaving a wire, lake at dusk, mountain mist, wild grass in late sun
City & urban life: empty street at 6am, bus ride alone, rooftop at night, underpass graffiti, market stall closing, subway commute, corner café window, parking lot rain, bridge at midnight, construction noise at dawn, pigeons on a ledge
At home: kitchen before anyone wakes, laundry folding, mirror moment, bed unmade at noon, late-night fridge light, window watching a neighbour, reading a letter, plants on a sill, closet clearing, old photos, shower fog on glass
Emotional stories: a goodbye you weren't ready for, realising you've grown, missing someone without knowing why, the moment after a big decision, loving something you're about to lose, the first day of something new, the last day of something old
Friends & people: two friends sitting in silence, a stranger's act of kindness, someone laughing alone, a phone call that changes everything, waiting for someone who might not come, a crowd and feeling invisible
Sports & movement: early morning run before the city wakes, solo skate session, bike ride with no destination, cold-water swim, gym at closing time, stretching after a long day, climbing something small just to see
Art & creativity: drawing something imperfect, playing music to an empty room, writing and deleting, the mess before the painting is finished, dancing when no one watches, photographing something ordinary
Love & relationships: the moment before you say it, holding something that belonged to someone else, looking at an old photo of two people, the first and last time somewhere together
Regret & time: revisiting somewhere you used to go, finding something you forgot you had, a habit you've tried to quit, the person you were a year ago, what you didn't say
Quiet & simple: a candle burning down, water dripping slowly, leaves falling one at a time, light moving across a wall, an empty chair, a door left open, a cup going cold

═══════════════════════════════════════
LESS IS MORE — this is a law, not a tip
═══════════════════════════════════════
At least one prompt per week MUST be minimal. Simple idea. One location. Quiet. No plot. Pure mood. Example: someone sits on their kitchen floor eating cereal at 2am. That's the whole story. No explanation needed. The best Reels often have the simplest concept executed with feeling. Not every prompt needs an emotional arc. Some just need presence.

═══════════════════════════════════════
SONGS — diversity is mandatory
═══════════════════════════════════════
The 3 prompts must have songs from DIFFERENT genres. Mix from: indie folk, bedroom pop, classical piano, lo-fi hip-hop, ambient electronic, jazz, soul/R&B, alternative rock, singer-songwriter, cinematic score, synth-pop, neo-soul, acoustic, dream pop, trap, art pop, punk, country/Americana, bossa nova.

BANNED OVERUSED SONGS (never suggest these): "Glimpse of Us" Joji, "Bad Guy" Billie Eilish, "Heat Waves" Glass Animals, "Drivers License" Olivia Rodrigo, "Blinding Lights" The Weeknd, "Watermelon Sugar" Harry Styles, "As It Was" Harry Styles, "lovely" Billie Eilish & Khalid, "River" Bishop Briggs, "The Night We Met" Lord Huron, "Clair de Lune" Debussy (as a cliché), "Fade" Alan Walker, anything by Marshmello or The Chainsmokers.

Think beyond the obvious. Some examples of songs that work well but are underused in Reels: "Lua" Bright Eyes, "Motion Picture Soundtrack" Radiohead, "Holocene" Bon Iver, "Comptine d'un autre été" Yann Tiersen, "Funeral" Phoebe Bridgers, "First Day of My Life" Bright Eyes, "Pink + White" Frank Ocean, "Sunday Morning" Maroon 5, "Coffee" beabadoobee, "Golden" Harry Styles (golden hour footage), "Lavender Haze" Taylor Swift (slow burn), "Buttercup" Hippo Campus, "Ribs" Lorde, "Youth" Daughter, "Oblivion" Grimes, "Motion Sickness" Phoebe Bridgers, "Video Games" Lana Del Rey, "Skinny Love" Bon Iver, "Bloom" The Paper Kites, "Let Her Go" Passenger, "Flightless Bird" Iron & Wine, "Falling" Trevor Daniel, "Heartbeats" José González, "Run" Hozier, "Cherry Wine" Hozier, "Like Real People Do" Hozier, "The Joke" Brandi Carlile, "Heaven" Bryan Adams, "Atlas Hands" Benjamin Francis Leftwich, "Slow Burn" Kacey Musgraves, "Rainbow" Kacey Musgraves, "Mess Is Mine" Vance Joy, "Riptide" Vance Joy, "Tenerife Sea" Ed Sheeran, "Supermarket Flowers" Ed Sheeran, "Retrograde" James Blake, "Digital Witness" St. Vincent, "Liability" Lorde, "Perfect Places" Lorde.

SONG STRUCTURE (for each prompt — must be exactly these tiers):
1. "best_match" — the song that GENUINELY fits the mood. Think freely. Any era. Not necessarily popular.
2. "trending" — a song currently used heavily on Instagram Reels or TikTok (2024-2026). Must also fit the theme.
3. "classic_fit" — timeless or widely known. Still resonates. Fits the scene.

═══════════════════════════════════════
JSON SCHEMA (each of the 3 objects)
═══════════════════════════════════════
- text: 100-160 words. Exact location, time of day, what happens, what objects are present, emotional arc, sensory details (light, texture, sound, temperature). NO camera instructions in text.
- shots: array of 3-5 strings. Each starts with WHEN (e.g. "Opening — "). Then: focal length, movement, light direction, framing. For Sequence and Short Story: ALL shots must be achievable SOLO — tripod, timer, surface. No handheld tracking with person in frame. For Story + Character: handheld allowed since a friend is present.
- outcome: one sentence. The closing image.
- purpose: one sentence. What the viewer feels or takes away.
- emotion: 1-3 words.
- inspiration: handle from the provided list.
- category: fresh snake_case tag you invent. Specific. Never reuse across the 3 prompts.
- level: "Sequence" / "Short Story" / "Story + Character"
- points: 10 / 30 / 50
- songs: array of exactly 3 objects with keys: title, artist, tier, why
- licenseFreeKeywords: array of 2-3 specific royalty-free search phrases (mood + genre, e.g. "melancholy acoustic guitar dusk", "lo-fi rainy window morning")
''';

Future<String?> _getSpotifyToken() async {
  final id = Platform.environment['SPOTIFY_CLIENT_ID'] ?? '';
  final secret = Platform.environment['SPOTIFY_CLIENT_SECRET'] ?? '';
  if (id.isEmpty || secret.isEmpty) return null;
  final creds = base64Encode(utf8.encode('$id:$secret'));
  final res = await http.post(
    Uri.parse('https://accounts.spotify.com/api/token'),
    headers: {
      'Authorization': 'Basic $creds',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  );
  if (res.statusCode != 200) return null;
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return data['access_token'] as String?;
}

Future<List<String>> _fetchSpotifySongs(String token, String query) async {
  final encoded = Uri.encodeComponent(query);
  final res = await http.get(
    Uri.parse('https://api.spotify.com/v1/search?q=$encoded&type=track&limit=5&market=US'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (res.statusCode != 200) return [];
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final items = ((data['tracks'] as Map)['items'] as List<dynamic>? ?? []);
  return items.map((t) {
    final track = t as Map<String, dynamic>;
    final artists = (track['artists'] as List).map((a) => a['name']).join(', ');
    return '"${track['name']}" by $artists';
  }).toList();
}

String _userPrompt({
  required List<Map<String, dynamic>> inspirations,
  required String region,
  required bool seasonalPrompts,
  List<String> spotifySongs = const [],
  List<String> communityPrompts = const [],
}) {
  final inspirationGuide = inspirations
      .map((i) =>
          '${i['handle']} (${i['profileUrl'] ?? ''}): ${i['style']}. Reference hint: ${i['referenceHint']}')
      .join('\n');

  final locationHint = _buildLocationHint(region: region, seasonal: seasonalPrompts);

  final spotifyBlock = spotifySongs.isEmpty ? '' : '''

REAL SPOTIFY SONGS — currently on the platform, use some of these where they fit:
${spotifySongs.join('\n')}
These are real, current tracks. Prefer them over generic guesses when they match the mood.
''';

  final communityBlock = communityPrompts.isEmpty ? '' : '''

COMMUNITY INSPIRATION — prompts written by real RAWBY users. Let these inspire your creativity and style. Do NOT copy them — let them spark ideas:
${communityPrompts.map((p) => '• $p').join('\n')}
''';

  return '''
Create 3 weekly prompts. Each prompt MUST be a CONCRETE scenario, not abstract. Bad: "a conversation about life". Good: "you sit in your kitchen at 6 AM, rain streaking the window, staring at a job offer email on your phone. The espresso machine hisses. A half-packed suitcase is open on the floor. You trace the rim of the mug with your thumb. You pick up the phone, put it down, then open the kitchen window and let the cold air in. Outside the street is empty. You stand there breathing and decide nothing."$spotifyBlock$communityBlock

The text field MUST be 100 to 160 words. Describe the scene in cinematic detail: location, time, light, objects, small specific actions, the emotional arc. Do NOT put camera instructions in text — those go in the shots array.

The shots array MUST contain 3 to 5 specific shot descriptions. Each shot MUST start with WHEN in the story to use it (e.g. "Opening —", "When they look away —", "Final shot —"). Then include focal length, movement, lighting, and framing. This is a shot list the videographer follows in order.

SONG SUGGESTIONS: For each prompt, include a "songs" array with exactly 3 objects. Each song has: title, artist, tier, why.
- Song 1 (tier: "best_match"): the song that fits the story mood and energy best. Any era, any popularity.
- Song 2 (tier: "trending"): a song currently trending and popular on Instagram Reels / TikTok (2024-2026). Must also fit the theme.
- Song 3 (tier: "classic_fit"): a song that's still popular and widely known, and fits the mood well. Think timeless or recent classics.
CRITICAL: Use EXACTLY these tier values: "best_match", "trending", "classic_fit". Do not use any other tier names.
Also include "licenseFreeKeywords" — 2-3 search phrases for royalty-free music libraries.

LEVEL RULES (strict):
- Prompt 1: level "Sequence", points 10. PURE VISUAL SEQUENCE. No talking, no dialogue. Music + sound + image only. The videographer is COMPLETELY ALONE. Every shot is either: (a) the camera on a tripod/surface filming the videographer, or (b) the videographer holding the camera filming objects, textures, landscapes (no person in frame). Do NOT suggest tracking shots, dolly moves, or handheld follow shots when the person is in frame — there is nobody to operate the camera.
- Prompt 2: level "Short Story", points 30. Solo videographer is the ONLY person on screen. They film themselves using tripod, timer, or camera placed on surfaces. Same camera rules as Sequence: no handheld shots with the person in frame. One spoken line maximum, or none.
- Prompt 3: level "Story + Character", points 50. The solo videographer plus 1 or 2 friends on screen. Since another person is present, handheld tracking shots, pan-follows, and shoulder rigs ARE allowed here. Light dialogue allowed but minimal.

CATEGORY RULES: YOU choose a fresh snake_case theme for each. Never reuse between prompts.
OUTCOME: the closing image or final frame. Concrete. One sentence.
PURPOSE: the message or feeling the viewer walks away with. Plain language. One sentence.
EMOTION: 1-3 short words. Match the mood.

VARIETY RULES (strict — enforce these across the 3 prompts):
1. LOCATION DIVERSITY: The 3 prompts MUST have different location types. Do NOT send 3 indoor/apartment scenes. Do NOT send 3 city street scenes. Mix freely from: indoor (home, kitchen, bedroom, bathroom, hotel, cafe), outdoor nature (park, forest, beach, mountain, river, field, garden), urban exterior (street, alley, bridge, parking lot, bus station, market), hybrid (balcony, window, threshold, stairwell, hallway, courtyard). AT LEAST ONE prompt should feature outdoor nature or natural landscape.
2. SCENARIO DIVERSITY: The 3 stories must have different emotional cores and activities. If one is about decision-making/uncertainty, the next should be action/exploration, the next should be observation/acceptance. Avoid repetitive emotions across all 3 (e.g. don't send 3 prompts about doubt/regret, or 3 about joy/celebration).
3. TIME OF DAY VARIETY: Spread the prompts across different times: one at dawn/early morning, one at midday/afternoon, one at dusk/evening/night. Not all in the blue hour.
4. SHOOTING STYLE VARIETY: For Sequences, vary between: pure visual observation, fast montage, single repeated action, or material/texture study. For Short Stories, vary between: internal emotional moment, external action moment, intimate scale vs. wide environment. For Story + Character stories, vary interaction types (conversation vs. shared activity vs. parallel action).
5. PROPS AND OBJECT DENSITY: One prompt should be sparse/minimal (few objects, empty space), one should be prop-rich/detailed environment, one should be medium. Avoid all 3 being cluttered or all 3 being empty.

Inspiration (pick one per prompt; match their visual style):
$inspirationGuide

Set inspiration to the chosen handle only.$locationHint
''';
}

String _buildLocationHint({required String region, required bool seasonal}) {
  if (region.isEmpty && !seasonal) return '';

  final buf = StringBuffer('\n\nREGIONAL CONTEXT:');
  if (region.isNotEmpty) {
    buf.write(
        '\n- Setting: $region. Locations, plants, weather, architecture and street life must be plausible for this region.');
  }
  if (seasonal) {
    final now = DateTime.now().toUtc();
    final season = _seasonFor(now.month, region);
    buf.write(
        '\n- Current season: $season. ONE of the 3 prompts must lean into this season. The other two may be neutral but none may contradict the season.');
  }
  return buf.toString();
}

String _seasonFor(int month, String region) {
  final southern = region.toLowerCase().contains('australia') ||
      region.toLowerCase().contains('south america') ||
      region.toLowerCase().contains('southern africa');
  final map = southern
      ? {
          12: 'summer', 1: 'summer', 2: 'summer',
          3: 'autumn', 4: 'autumn', 5: 'autumn',
          6: 'winter', 7: 'winter', 8: 'winter',
          9: 'spring', 10: 'spring', 11: 'spring',
        }
      : {
          12: 'winter', 1: 'winter', 2: 'winter',
          3: 'spring', 4: 'spring', 5: 'spring',
          6: 'summer', 7: 'summer', 8: 'summer',
          9: 'autumn', 10: 'autumn', 11: 'autumn',
        };
  return map[month] ?? 'spring';
}

Future<Response> handleGeneratePrompts(Request request) async {
  try {
    final body = await request.readAsString();
    final data = body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(body) as Map<String, dynamic>;

    final provider = (data['provider'] as String? ?? 'groq').toLowerCase();
    final model = data['model'] as String? ??
        (provider == 'openai' ? 'gpt-4o' : 'llama-3.3-70b-versatile');
    final inspirations = (data['inspirations'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final region = data['region'] as String? ?? '';
    final seasonalPrompts = data['seasonalPrompts'] as bool? ?? false;

    // Fetch Spotify songs for variety
    final List<String> spotifySongs = [];
    try {
      final token = await _getSpotifyToken();
      if (token != null) {
        final queries = ['indie cinematic mood', 'trending reels 2025', 'emotional acoustic'];
        for (final q in queries) {
          spotifySongs.addAll(await _fetchSpotifySongs(token, q));
        }
      }
    } catch (_) {}

    // Fetch community prompts for inspiration
    final List<String> communityPrompts = [];
    try {
      final recent = await Store.instance.getRecentCommunityPrompts(limit: 6);
      communityPrompts.addAll(recent.map((p) => p['text'] as String? ?? '').where((t) => t.isNotEmpty));
    } catch (_) {}

    final userPromptText = _userPrompt(
      inspirations: inspirations,
      region: region,
      seasonalPrompts: seasonalPrompts,
      spotifySongs: spotifySongs,
      communityPrompts: communityPrompts,
    );

    final rawText = provider == 'openai'
        ? await _callOpenAi(model: model, userPrompt: userPromptText)
        : provider == 'claude'
            ? await _callClaudePrompts(model: model, userPrompt: userPromptText)
            : await _callGroq(model: model, userPrompt: userPromptText);

    final prompts = _parsePrompts(rawText);
    return Response.ok(jsonEncode({'prompts': prompts}), headers: _jsonHeaders);
  } catch (e, st) {
    stderr.writeln('[generate-prompts] $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Future<String> _callGroq({required String model, required String userPrompt}) async {
  final key = Platform.environment['GROQ_API_KEY'];
  if (key == null || key.isEmpty) {
    throw StateError('GROQ_API_KEY not set');
  }
  final res = await http.post(
    Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'temperature': 0.85,
      'max_tokens': 8000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
    }),
  );
  if (res.statusCode >= 400) {
    throw HttpException('Groq ${res.statusCode}: ${res.body}');
  }
  return _extractContent(res.body, 'Groq');
}

Future<String> _callOpenAi({required String model, required String userPrompt}) async {
  final key = Platform.environment['OPENAI_API_KEY'];
  if (key == null || key.isEmpty) {
    throw StateError('OPENAI_API_KEY not set');
  }
  final res = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'temperature': 0.85,
      'max_tokens': 8000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
    }),
  );
  if (res.statusCode >= 400) {
    throw HttpException('OpenAI ${res.statusCode}: ${res.body}');
  }
  return _extractContent(res.body, 'OpenAI');
}

Future<String> _callClaudePrompts({required String model, required String userPrompt}) async {
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
      'model': model,
      'max_tokens': 8000,
      'system': _systemPrompt,
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
    }),
  );
  if (res.statusCode >= 400) {
    throw HttpException('Anthropic ${res.statusCode}: ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final content = (data['content'] as List).first as Map;
  return (content['text'] as String).trim();
}

String _extractContent(String responseBody, String label) {
  final body = jsonDecode(responseBody) as Map<String, dynamic>;
  final choices = body['choices'] as List<dynamic>?;
  if (choices == null || choices.isEmpty) {
    throw StateError('Empty $label response');
  }
  final first = choices.first as Map<String, dynamic>;
  final message = first['message'] as Map<String, dynamic>?;
  final content = message?['content'] as String?;
  if (content == null || content.isEmpty) {
    throw StateError('Empty $label content');
  }
  return content;
}

List<Map<String, dynamic>> _parsePrompts(String raw) {
  final cleaned = _stripFences(raw).trim();
  final decoded = jsonDecode(cleaned);

  List<dynamic> arr;
  if (decoded is List) {
    arr = decoded;
  } else if (decoded is Map<String, dynamic>) {
    arr = (decoded['prompts'] ??
            decoded['data'] ??
            decoded['items'] ??
            decoded.values.firstWhere((v) => v is List, orElse: () => []))
        as List<dynamic>;
  } else {
    throw StateError('Unexpected JSON shape');
  }

  return arr.take(3).map((e) {
    final m = Map<String, dynamic>.from(e as Map);
    final songs = (m['songs'] as List<dynamic>? ?? []).map((s) {
      final sm = Map<String, dynamic>.from(s as Map);
      final tier = sm['tier'] as String? ?? sm['type'] as String? ?? 'best_match';
      return {
        'title': sm['title'] ?? '',
        'artist': sm['artist'] ?? '',
        'type': tier,
        'whyItWorks': sm['why'] ?? sm['whyItWorks'] ?? '',
      };
    }).toList();
    return {
      'text': m['text'] ?? '',
      'shots': m['shots'] ?? [],
      'outcome': m['outcome'] ?? '',
      'purpose': m['purpose'] ?? '',
      'emotion': m['emotion'] ?? '',
      'inspiration': m['inspiration'] ?? '',
      'category': m['category'] ?? '',
      'level': m['level'] ?? 'Sequence',
      'points': m['points'] ?? 10,
      'songs': songs,
      'licenseFreeKeywords': m['licenseFreeKeywords'] ?? [],
    };
  }).toList();
}

String _stripFences(String s) {
  var out = s.trim();
  if (out.startsWith('```')) {
    final firstNewline = out.indexOf('\n');
    if (firstNewline != -1) out = out.substring(firstNewline + 1);
    if (out.endsWith('```')) out = out.substring(0, out.length - 3);
  }
  return out;
}
