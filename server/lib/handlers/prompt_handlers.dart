// ============================================================
// RAWBY — Prompt Handler
// Routes to Groq or OpenAI with the canonical RAWBY system prompt.
// Falls back to a deterministic local payload if keys missing.
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import '../store.dart';
import '../data/song_catalog.dart';

const _jsonHeaders = {'content-type': 'application/json'};

const _systemPrompt = '''
You write weekly short-film prompts for a solo videographer. Clear, direct English. No jargon. Cinematic but human. Output ONLY a valid JSON array with exactly 3 objects — no markdown, no commentary.

═══════════════════════════════════════
VARIETY IS YOUR #1 JOB — read this first
═══════════════════════════════════════
These prompts are generated every week. The single worst failure is sameness — prompts that feel interchangeable with last week's. Treat every generation as a deliberate swing AWAY from the obvious. Surprise the videographer. If an idea feels like the first thing any AI would write, discard it and dig for the second or third idea.

BANNED DEFAULT SCENE (do NOT write this, in any disguise): the "rainy window / quiet kitchen / 6am / lukewarm coffee or espresso / staring at a phone or a letter / melancholy indecision" scene. It has been used to death. Also avoid as a crutch: someone lying in an unmade bed at noon, journaling by candlelight, and "staring wistfully into the middle distance." Mood ≠ a person being sad indoors near a window. Mood can be energy, texture, motion, humour, tension, joy, defiance.

Honour the CREATIVE SEED supplied in the user message as binding constraints, not suggestions. It exists specifically to push each week somewhere new.

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
SONGS — FAMOUS songs only, all 3 must fit the vibe
═══════════════════════════════════════
For each prompt give 3 songs. HARD RULES (earlier picks were far too obscure — fix that):
- POPULAR ONLY. Every song must be famous and mainstream — the kind millions of people know: big chart hits, iconic tracks, household-name artists. If a normal person wouldn't instantly recognize it, DO NOT use it. No indie / bedroom-pop / lo-fi / "tasteful underground" picks. The FAME BAR is artists at the level of Queen, Fleetwood Mac, Michael Jackson, Whitney Houston, ABBA, Elton John, Nirvana, Eminem, Dr. Dre, 2Pac, 50 Cent, Rihanna, Beyoncé, Drake, Kendrick Lamar, Travis Scott, Taylor Swift, The Weeknd, Adele, Coldplay, Daft Punk — that LEVEL of fame is required (this is NOT a list to copy from).
- ALL THREE FIT THE STORY. Read the scene's mood and energy; every one of the 3 songs must suit it. Never "one fits, two random".
- VARY BY ERA/GENRE, but only what fits the vibe: a hype/gym scene → popular rap/hip-hop; a nostalgic golden-hour scene → a famous 70s/80s classic; a heartbreak scene → a well-known ballad; an upbeat scene → a big pop or dance hit. Mix eras across the 3 (a classic, a modern hit, something in between) so they aren't samey.
- REAL + correctly attributed. Never invent a song, never mismatch artist/title. If unsure, pick a MORE famous one.
- DON'T default to the same songs every time. Different prompts and different weeks must get different famous songs.

SONG STRUCTURE (each prompt: exactly 3 song objects, keys unchanged):
1. "best_match" — the famous song that best nails the scene's vibe.
2. "trending" — a big, well-known modern pop / rap / dance hit that fits.
3. "classic_fit" — a famous older classic (60s–90s: rock, soul, disco, pop) that fits.

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

// ════════════════════════════════════════════════════════════
// CREATIVE-SEED ENGINE — the main defence against repetition.
// Every call randomly draws constraints from these pools and bakes
// them into the user prompt, so two generations are never anchored
// to the same location / time / mood / visual device. Without this,
// the model collapses to the same handful of "safe" scenes weekly.
// ════════════════════════════════════════════════════════════

final _rng = Random.secure();

T _pick<T>(List<T> xs) => xs[_rng.nextInt(xs.length)];

List<T> _pickN<T>(List<T> xs, int n) {
  final pool = List<T>.of(xs)..shuffle(_rng);
  return pool.take(n).toList();
}

/// Location families — forces spatial variety beyond "indoors near a window".
const _locationFamilies = [
  'inside a moving vehicle (car, bus, train, passenger seat)',
  'on or beside water (river, lake, sea, pool, canal, harbour)',
  'a threshold or in-between space (doorway, stairwell, lift, hallway, platform, bridge)',
  'a high or open place (rooftop, hilltop, balcony, car park top deck, overpass)',
  'an enclosed or underground space (basement, tunnel, garage, storage unit, attic)',
  'open natural landscape (field, forest, desert, beach, moor, orchard)',
  'a workplace or institution after or before hours (office, gym, classroom, shop, studio)',
  'a place loaded with memory (childhood room, old route, family kitchen, an ex\'s neighbourhood)',
  'somewhere public and busy, used for solitude (laundromat, station, market, food court, library)',
  'a place of making or repair (workshop, kitchen mid-cook, garage build, garden, darkroom)',
  'a transitional life-space (half-packed room, new empty flat, hotel, hospital corridor, waiting area)',
  'a place of play or movement (skate park, court, pool hall, dance floor, arcade, trail)',
];

/// Time windows — break the dawn/blue-hour monoculture.
const _timeWindows = [
  'pre-dawn dark, before the light',
  'hard bright midday, no soft light at all',
  'flat grey overcast afternoon',
  'the harsh fluorescent of a late shift',
  'golden hour, but used against type (energetic, not wistful)',
  'full night, lit only by practical/artificial sources',
  'that specific 3pm Sunday emptiness',
  'first light just breaking, cold and blue',
];

/// Emotional registers — proves mood isn\'t only sadness-by-a-window.
const _emotionalRegisters = [
  'restless anticipation',
  'quiet contentment / ease',
  'controlled, simmering anger',
  'playful mischief or humour',
  'awe and wonder at something ordinary',
  'nervous, jittery excitement',
  'defiance / proving something to yourself',
  'flow and total focus on a craft',
  'tenderness toward a person or object',
  'boredom that cracks open into spontaneity',
  'nostalgia that is warm, not mournful',
  'relief after something hard ended',
  'curiosity pulling you somewhere new',
];

/// Visual devices — a single constraint that shapes the whole piece and
/// forces formal invention instead of default coverage.
const _visualDevices = [
  'tell it almost entirely in reflections (windows, water, mirrors, screens, chrome)',
  'never show a human face the whole piece',
  'shoot through something — glass, fabric, leaves, steam, a doorway',
  'build the whole thing on ONE repeated action',
  'make it feel like a single unbroken take',
  'tell it with hands and objects only',
  'commit to one dominant colour motif',
  'use lots of negative space / empty frame',
  'work in silhouette and shadow',
  'cut macro textures against exactly one wide shot',
  'the subject never stops moving',
  'the camera never moves at all — every shot locked off',
  'match-cut on shape or motion between every shot',
  'let one sound (not music) drive the edit',
];

/// Genre pools to force genuinely different song palettes each week.
const _genrePalette = [
  'classic rock (70s/80s)', 'motown & soul', 'disco & funk', '80s synth-pop',
  '90s hip-hop', '2000s pop', 'modern pop hits', 'mainstream rap/hip-hop',
  'R&B', 'rock anthems', 'dance/electronic hits', 'country pop',
  'latin pop / reggaeton', 'classic ballads', '90s/2000s R&B', 'pop-punk',
];

/// Rotating concrete EXAMPLES. We hand the model exactly ONE, chosen at
/// random, purely as a format reference — so the in-context anchor moves
/// every call instead of always being the rainy-kitchen scene.
const _exampleScenes = [
  'noon on a dead-straight desert highway. Heat shimmer warps the tarmac. You step out of the car, leave the door open, the engine ticking, and just listen to the wind. You touch the hot metal of the roof, then walk a few steps into the scrub and stop. Nothing is wrong. You just needed the size of it.',
  'a laundromat at 11pm, every machine but one empty. Strip lighting hums. You fold a stranger\'s abandoned shirt out of habit, then catch yourself. The dryer thuds. You sit on the folding table, socked feet swinging, and for once your phone stays in your pocket.',
  'a garage mid-build. Sawdust hangs in a shaft of work-light. You measure twice, swear once, and the cut finally lands clean. You blow the dust off, run a thumb along the edge, and grin at no one. The radio is playing something you\'d never admit to liking.',
  'a public pool at opening, water glass-flat. You\'re the first in. The shock of cold, then the line of bubbles as you push off. Lap after lap, the city noise gone underwater. You stop at the wall, breathing hard, hair flat, completely awake.',
  'backstage before a small gig, ten minutes out. Someone\'s gaffer-taping a setlist to the floor. You retune by ear, miss, retune again. Hands not quite steady. You roll your shoulders, blow out a breath, and walk toward the noise.',
  'a kitchen full of family mid-cook, four conversations at once, a pot about to boil over. You reach past three people for the salt, get elbowed, laugh. Steam fogs your glasses. Nobody is filming a moment; the moment is just happening too fast to hold.',
  'a skate park emptying out at dusk. One kid keeps trying the same trick and eating it. You stop pretending to leave and watch. They land it. The whole park — six people — loses it. You\'re yelling too before you decide to.',
  'moving day, the flat finally empty. Your voice echoes differently now. You find one forgotten drawing pin in the carpet, hold it, then leave it on the windowsill on purpose. Keys on the counter. You don\'t look back from the doorway — you just go.',
];

/// Build the per-call CREATIVE SEED block. This is appended to the user
/// prompt as binding constraints; the random seed integer also nudges the
/// model away from token-for-token repetition between runs.
String _creativeSeedBlock() {
  final seed = _rng.nextInt(1 << 32);
  final loc = _pickN(_locationFamilies, 3);
  final times = _pickN(_timeWindows, 3);
  final moods = _pickN(_emotionalRegisters, 3);
  final devices = _pickN(_visualDevices, 3);
  final genres = _pickN(_genrePalette, 3);

  return '''

═══════════════════════════════════════
THIS WEEK'S CREATIVE SEED (uniqueness id: $seed) — BINDING
═══════════════════════════════════════
These are mandatory divergence constraints for THIS generation only. Obey them; do not drift back to defaults.

- LOCATIONS: assign each of the 3 prompts a DIFFERENT family from this set — ${loc.join(' · ')}. None of the 3 may be "indoors at a window".
- TIME OF DAY: spread the 3 prompts across these registers — ${times.join(' · ')}. Do not put all three in the same light.
- EMOTIONAL CORES: the 3 prompts must carry distinct emotional registers drawn from — ${moods.join(' · ')}. At most one may be melancholy/reflective; the rest must NOT be.
- VISUAL DEVICE: give at least one prompt a strong formal constraint — pick from: ${devices.join(' · ')}. State it inside that prompt's shots.
- SONGS: all 3 songs per prompt must be FAMOUS, widely-known hits that genuinely fit that scene's vibe. For variety THIS generation, lean toward these popular flavors where they fit the mood: ${genres.join(', ')}. Never pick obscure songs, and don't fall back on the same defaults you'd usually reach for.

Use the uniqueness id ($seed) as a reason to make fresh, specific, unexpected choices — not the safe first idea.
''';
}

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
    Uri.parse('https://api.spotify.com/v1/search?q=$encoded&type=track&limit=12&market=US'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (res.statusCode != 200) return [];
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final items = ((data['tracks'] as Map)['items'] as List<dynamic>? ?? []);
  final out = <String>[];
  for (final t in items) {
    final track = t as Map<String, dynamic>;
    // Famous only: Spotify popularity 0-100. Keep mainstream tracks.
    final pop = (track['popularity'] as num?)?.toInt() ?? 0;
    if (pop < 55) continue;
    final artists = (track['artists'] as List).map((a) => a['name']).join(', ');
    out.add('"${track['name']}" by $artists');
  }
  return out;
}

String _userPrompt({
  required List<Map<String, dynamic>> inspirations,
  required String region,
  required bool seasonalPrompts,
  List<String> spotifySongs = const [],
  List<String> communityPrompts = const [],
  List<String> avoidPrompts = const [],
}) {
  final inspirationGuide = inspirations
      .map((i) =>
          '${i['handle']} (${i['profileUrl'] ?? ''}): ${i['style']}. Reference hint: ${i['referenceHint']}')
      .join('\n');

  final locationHint = _buildLocationHint(region: region, seasonal: seasonalPrompts);
  final seedBlock = _creativeSeedBlock();
  final exampleScene = _pick(_exampleScenes);

  final avoidBlock = avoidPrompts.isEmpty ? '' : '''

═══════════════════════════════════════
ALREADY USED — DO NOT REPEAT
═══════════════════════════════════════
These scenarios were generated in recent weeks. Do NOT reuse their locations, core situations, objects, or song picks. Go somewhere clearly different:
${avoidPrompts.take(12).map((p) => '• $p').join('\n')}
''';

  final spotifyBlock = spotifySongs.isEmpty ? '' : '''

═══════════════════════════════════════
FAMOUS SONG POOL — pick from these
═══════════════════════════════════════
Real, FAMOUS, widely-known songs (many tagged with their mood). For EACH prompt, choose its 3 songs from THIS pool, matching the scene's vibe. Only if nothing here fits a scene may you use another equally-famous, real song. NEVER pick anything obscure.
${spotifySongs.join('\n')}
''';

  final communityBlock = communityPrompts.isEmpty ? '' : '''

COMMUNITY INSPIRATION — prompts written by real RAWBY users. Let these inspire your creativity and style. Do NOT copy them — let them spark ideas:
${communityPrompts.map((p) => '• $p').join('\n')}
''';

  return '''
Create 3 weekly prompts. Each prompt MUST be a CONCRETE scenario, not abstract. Bad: "a conversation about life". This is ONLY a format reference for how concrete and sensory to get — do NOT copy its location, mood, or objects: "$exampleScene"$seedBlock$avoidBlock$spotifyBlock$communityBlock

The text field MUST be 100 to 160 words. Describe the scene in cinematic detail: location, time, light, objects, small specific actions, the emotional arc. Do NOT put camera instructions in text — those go in the shots array.

The shots array MUST contain 3 to 5 specific shot descriptions. Each shot MUST start with WHEN in the story to use it (e.g. "Opening —", "When they look away —", "Final shot —"). Then include focal length, movement, lighting, and framing. This is a shot list the videographer follows in order.

SONG SUGGESTIONS: For each prompt include a "songs" array with exactly 3 objects (keys: title, artist, tier, why). ALL 3 must be FAMOUS, real, widely-known songs — prefer the FAMOUS SONG POOL above — and ALL 3 must fit that scene's mood and energy (never one fit + two random). Vary era/genre across the 3 where it suits the vibe.
- Song 1 (tier: "best_match"): the famous song that best nails the scene's mood.
- Song 2 (tier: "trending"): a big, well-known modern pop / rap / dance hit that fits.
- Song 3 (tier: "classic_fit"): a famous older classic (60s-90s rock, soul, disco, pop) that fits.
CRITICAL: Use EXACTLY these tier values: "best_match", "trending", "classic_fit". Real songs only — never invent a song or mismatch artist/title; if unsure, pick a more famous one.
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

    // Build a pool of FAMOUS songs to ground the picks. Spotify first (real,
    // popularity-filtered) over rotating popular genres; plus a rotating sample
    // of the curated backup catalog (sole source if Spotify is unavailable).
    final rng = Random();
    final List<String> spotifySongs = [];
    try {
      final token = await _getSpotifyToken();
      if (token != null) {
        final picks = List<String>.from(_genrePalette)..shuffle(rng);
        for (final g in picks.take(2)) {
          spotifySongs.addAll(await _fetchSpotifySongs(token, g));
        }
      }
    } catch (_) {}
    // Backup catalog sample — always added for breadth (and reliability when
    // Spotify is off). Rotated each call so picks vary across generations.
    final catalog = List<String>.from(kSongCatalog)..shuffle(rng);
    for (final line in catalog.take(28)) {
      final parts = line.split('|');
      if (parts.length >= 3) {
        spotifySongs.add('"${parts[0]}" by ${parts[1]} — ${parts[2]}');
      }
    }
    spotifySongs.shuffle(rng);

    // Fetch community prompts for inspiration
    final List<String> communityPrompts = [];
    try {
      final recent = await Store.instance.getRecentCommunityPrompts(limit: 6);
      communityPrompts.addAll(recent.map((p) => p['text'] as String? ?? '').where((t) => t.isNotEmpty));
    } catch (_) {}

    // Fetch our OWN recently generated prompts to actively avoid repeating them.
    final List<String> avoidPrompts = [];
    try {
      final recent = await Store.instance.getRecentGeneratedPrompts(limit: 12);
      avoidPrompts.addAll(recent.map((p) => p['fingerprint'] as String? ?? '').where((t) => t.isNotEmpty));
    } catch (_) {}

    final userPromptText = _userPrompt(
      inspirations: inspirations,
      region: region,
      seasonalPrompts: seasonalPrompts,
      spotifySongs: spotifySongs,
      communityPrompts: communityPrompts,
      avoidPrompts: avoidPrompts,
    );

    final rawText = provider == 'openai'
        ? await _callOpenAi(model: model, userPrompt: userPromptText)
        : provider == 'claude'
            ? await _callClaudePrompts(model: model, userPrompt: userPromptText)
            : await _callGroq(model: model, userPrompt: userPromptText);

    final prompts = _parsePrompts(rawText);

    // Persist compact fingerprints so next week's generation can dodge them.
    try {
      for (final p in prompts) {
        await Store.instance.saveGeneratedPrompt({'fingerprint': _fingerprint(p)});
      }
    } catch (_) {}

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
      // Higher temperature + nucleus sampling for range; presence/frequency
      // penalties push the model off its repeated phrasings and scenes.
      'temperature': 0.95,
      'top_p': 0.95,
      'presence_penalty': 0.6,
      'frequency_penalty': 0.3,
      'max_tokens': 3500,
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
      'temperature': 0.95,
      'top_p': 0.95,
      'presence_penalty': 0.6,
      'frequency_penalty': 0.3,
      'max_tokens': 3500,
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
      'max_tokens': 3500,
      'temperature': 1.0,
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

/// Compact one-line signature of a generated prompt — enough for the next
/// run to recognise and avoid the same location/situation/song, without
/// bloating the context with full prompt bodies.
String _fingerprint(Map<String, dynamic> p) {
  final text = (p['text'] as String? ?? '').trim();
  final words = text.split(RegExp(r'\s+')).take(24).join(' ');
  final emotion = (p['emotion'] as String? ?? '').trim();
  final category = (p['category'] as String? ?? '').trim();
  final songs = (p['songs'] as List<dynamic>? ?? []);
  final bestSong = songs.isEmpty
      ? ''
      : (() {
          final s = Map<String, dynamic>.from(songs.first as Map);
          final t = (s['title'] ?? '').toString();
          final a = (s['artist'] ?? '').toString();
          return t.isEmpty ? '' : '"$t"${a.isEmpty ? '' : ' — $a'}';
        })();
  final parts = <String>[
    if (emotion.isNotEmpty) emotion,
    if (category.isNotEmpty) category,
    if (words.isNotEmpty) words,
    if (bestSong.isNotEmpty) 'song: $bestSong',
  ];
  return parts.join(' · ');
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
