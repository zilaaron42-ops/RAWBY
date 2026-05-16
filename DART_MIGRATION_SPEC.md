# Creative Loop — Full Application Specification (Dart/Flutter Migration)

> Generated from the JavaScript/Node.js codebase. Every detail you need to rebuild in Dart.

---

## 1. Architecture Overview

### Stack
- **Backend**: Node.js (Express), deployed on Render
- **Frontend**: Vanilla JS SPA-like (multi-page), served as static files
- **Database**: JSON files on disk (`data/users.json`, `data/feedback.json`, `data/updates.json`)
- **Client storage**: `localStorage` (per-user scoped keys)
- **Auth**: Session tokens (UUID) stored in an in-memory `Map` on the server, `sessionStorage` on client
- **AI**: Groq (default, free) or OpenAI — both use the OpenAI-compatible `/chat/completions` endpoint
- **Push**: Web Push via VAPID (service worker)
- **Instagram**: Meta Graph API v19.0 (admin only)

### API Base
```
https://creative-loop.onrender.com
```

### Environment Variables
```
PORT=3000
GROQ_API_KEY=           # Free at console.groq.com
OPENAI_API_KEY=         # Paid, ~$5 minimum credit
IG_ACCESS_TOKEN=        # Meta Graph API long-lived token
IG_USER_ID=             # Instagram Business/Creator user ID
VAPID_PUBLIC_KEY=       # Generate with: npx web-push generate-vapid-keys
VAPID_PRIVATE_KEY=
VAPID_SUBJECT=mailto:noreply@localhost
CRON_PUSH_SECRET=       # Secures the scheduled push endpoint
```

---

## 2. Authentication System

### Login
- **Endpoint**: `POST /api/auth/login`
- **Body**: `{ email: String, pin: String }` (or `username` for legacy)
- **Response**: `{ token: UUID, user: { id, username, displayName, role } }`
- PINs are SHA-256 hashed server-side
- Admin has a special hardcoded backdoor: username `"admin"`, password `"#Z1923/a"`
- Tokens are UUIDs stored in an in-memory `Map<String, Session>` (lost on server restart)

### Registration
- **Endpoint**: `POST /api/auth/register`
- **Body**: `{ displayName, email, pin }`
- Auto-generates a username from displayName (lowercase, alphanumeric)
- PIN must be >= 4 digits
- Email must be unique
- Always creates role `"user"`

### Token Verification
- **Endpoint**: `GET /api/auth/me`
- **Header**: `Authorization: Bearer <token>`
- Returns user info or 401

### Logout
- **Endpoint**: `POST /api/auth/logout`
- Deletes session from the server Map

### Roles
- `"admin"` — full access, Instagram stats, user management, feedback deletion, update posting
- `"user"` — standard access, can only see own feedback, no Instagram API access

### Client Auth (`auth.js`)
- Stores `{ token, user }` in `sessionStorage` under key `"creative_loop_auth"`
- All non-login/profile/privacy pages redirect to `login.html` if no token
- `CL_AUTH.userStorageKey(base)` returns `"<base>_<username>"` for per-user localStorage scoping
- `CL_AUTH.authFetch(url, opts)` auto-adds `Authorization: Bearer` header and JSON serialization
- `CL_AUTH.syncScores(data)` debounces (2s) a POST to `/api/user/sync`
- `CL_AUTH.isAdmin()` checks `user.role === "admin"`

---

## 3. Data Model

### Local State (`localStorage`)
Key: `"creative_loop_state_v3_<username>"`

```dart
class AppState {
  String seasonStart;          // ISO string, e.g. "2026-05-01T00:00:00.000Z"
  String weekStart;            // ISO string, current cycle start
  String deadline;             // ISO string, weekStart + 7 days
  List<Prompt> prompts;        // 3 prompts (or 1 if selected)
  String? selectedPromptId;
  List<WorkflowStep> workflow; // 7 steps
  String? submittedAt;         // ISO string when project submitted
  String? statsRecordedAt;     // ISO string when likes recorded
  int likes;
  int views;
  String instagramUrl;
  List<ProgressLogEntry> progressLog;
  int totalScore;
  int completedWeeks;
  List<HistoryEntry> history;
  List<PendingStat> pendingStats;
  List<BigProject> bigProjects;
  List<GearItem> gearPurchases;
  List<Subscription> subscriptions;
  List<String> currentGearUsed; // gear IDs used in current project
  List<SkillEntry> skillHistory;
  String skillAiPlan;
  String instagramProfile;
  String regenWeek;            // ISO string, tracks which week regen count belongs to
  int regenCount;              // 0-3 regenerations used this week
  bool autoGenPending;         // true = AI prompts should be generated on next load
  List<SavedPrompt> savedPrompts;
  ProjectStartWindow? projectStartWindow;
  Preferences preferences;
  List<IgPost>? igPosts;       // cached Instagram posts (admin only)
  String? igStatsRefreshedAt;
  List<ProjectSummary>? projectSummaries;
}
```

### Preferences
```dart
class Preferences {
  String theme;             // "light" | "dark"
  String accent;            // "green" | "grey" | "basic"
  String language;          // "en"
  String promptLanguage;    // "en"
  String? region;           // e.g. "Hungary"
  String? timezone;         // e.g. "Europe/Budapest"
  bool? seasonalPrompts;    // true = prompts are season-aware
  String? cycleDay;         // "Friday" (default), any weekday name
  String? filmmakingGoal;
  String? contentType;
}
```

### Prompt
```dart
class Prompt {
  String id;                    // e.g. "aip_1715000000000_0" or "p10"
  String level;                 // "Sequence" | "Short Story" | "Story + Character" | "Big Project"
  int points;                   // 10, 30, or 50 (big: custom)
  String category;              // snake_case tag, e.g. "fading_routine"
  String inspiration;           // creator handle, e.g. "@nicholasklepper"
  String? inspirationStyle;
  String? inspirationProfileUrl;
  String? inspirationReferenceHint;
  String? inspirationVideoUrl;
  String text;                  // 100-160 word prompt text
  List<String>? shots;          // 3-5 shot descriptions (AI only)
  List<Song>? songs;            // exactly 3 songs (AI only)
  List<String>? licenseFreeKeywords; // 2-3 search terms (AI only)
  String? outcome;              // closing image description
  String? purpose;              // message/takeaway
  String? emotion;              // 1-3 emotion words
  String source;                // "local" | "ai" | "custom" | "saved" | "big"
}
```

### Song
```dart
class Song {
  String title;
  String artist;
  String tier;   // MUST be exactly: "best_match" | "trending" | "classic_fit"
  String why;    // one sentence explanation
}
```

### Workflow Step
```dart
class WorkflowStep {
  String id;             // "script_music", "filming", "editing", "vfx", "sound", "grading", "publish"
  String label;          // e.g. "Script and music selected"
  String? day;           // e.g. "Friday" (weekly only, null for big)
  bool done;
  String? completedAt;   // ISO string
}
```

**7 steps (in order)**:
1. `script_music` — "Script and music selected" — cycle day
2. `filming` — "Filming finished" — next day or day after
3. `editing` — "Rough edit done" — day after
4. `vfx` — "VFX done" — day after or two after
5. `sound` — "Sound design done" — two or three after
6. `grading` — "Color grading done" — three or four after
7. `publish` — "Published" — cycle day (next week)

Days are dynamically calculated from `preferences.cycleDay` (default Friday).

### History Entry
```dart
class HistoryEntry {
  String createdAt;        // ISO
  String weekStart;        // ISO
  String? submittedAt;     // ISO
  String level;
  int points;
  String promptText;
  String? inspiration;
  int likes;
  int views;
  int finalScore;
  String instagramUrl;
  List<WorkflowStep> workflow;
  List<ProgressLogEntry> progressLog;
  List<String> gearUsed;   // gear IDs
  bool isTestRun;          // true if weekStart < seasonStart
}
```

### Score Calculation
```dart
int calculateFinalScore(int likes, int points, int lateDays) {
  int baseScore = likes * points;
  double penaltyMul;
  if (lateDays <= 0) penaltyMul = 1.0;
  else if (lateDays == 1) penaltyMul = 0.9;
  else if (lateDays == 2) penaltyMul = 0.75;
  else penaltyMul = 0.5;
  return (baseScore * penaltyMul).round();
}
```

### Skill Score & Ranks
```dart
int skillScore() {
  int totalLikes = history.fold(0, (s, h) => s + h.likes);
  int totalViews = history.fold(0, (s, h) => s + h.views);
  return (totalLikes * 3 + totalViews * 0.1 + completedWeeks * 50).round();
}

// Ranks:
// 0+       → Starter      (◇)
// 800+     → Apprentice   (◆)
// 2500+    → Emerging     (▲)
// 7000+    → Builder      (■)
// 18000+   → Cinematic    (★)
// 45000+   → Senior Dir.  (⬡)
// 100000+  → Master       (♛)
```

### Streak Calculation
```dart
int computeStreak(List<HistoryEntry> history) {
  final filtered = history.where((h) => !h.isTestRun).toList();
  if (filtered.isEmpty) return 0;
  filtered.sort((a, b) => DateTime.parse(b.weekStart).compareTo(DateTime.parse(a.weekStart)));
  int streak = 1;
  for (int i = 1; i < filtered.length; i++) {
    final prev = DateTime.parse(filtered[i - 1].weekStart);
    final curr = DateTime.parse(filtered[i].weekStart);
    final diffDays = prev.difference(curr).inDays;
    if (diffDays >= 5 && diffDays <= 10) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
```

### Achievement Badges
17 badges total:

| ID | Icon | Label | Condition |
|---|---|---|---|
| `first_submit` | 🎬 | First Submit | history.length >= 1 |
| `five_projects` | 🎯 | Five Down | history.length >= 5 |
| `ten_projects` | 🔥 | Double Digits | history.length >= 10 |
| `twentyfive` | 💎 | Quarter Century | history.length >= 25 |
| `fifty` | 👑 | Half Hundred | history.length >= 50 |
| `streak_3` | 🔥 | 3-Week Streak | streak >= 3 |
| `streak_5` | ⚡ | 5-Week Streak | streak >= 5 |
| `streak_10` | 🌟 | 10-Week Streak | streak >= 10 |
| `viral_100` | ❤️ | 100 Likes | maxLikes >= 100 |
| `viral_500` | 💗 | 500 Likes | maxLikes >= 500 |
| `viral_1k` | 🚀 | 1K Likes | maxLikes >= 1000 |
| `first_gear` | 📷 | Geared Up | gearCount >= 1 |
| `five_gear` | 🎒 | Kit Builder | gearCount >= 5 |
| `first_skill` | 📝 | Self Aware | skillEntries >= 1 |
| `ten_skill` | 🧠 | Growth Mindset | skillEntries >= 10 |
| `big_done` | 🎞️ | Big Thinker | has a finished big project |
| `idea_bank` | 💡 | Idea Bank | savedPrompts >= 5 |

Badges live on the **Leaderboard page** in a collapsible section (hidden by default).

---

## 4. Weekly Cycle System

### How a cycle works
1. Cycle starts on `preferences.cycleDay` (default: Friday)
2. Deadline = cycleStart + 7 days
3. On new week detection (when `weekStart !== currentCycleStart`):
   - If previous project was submitted but not stats-recorded, push to `pendingStats`
   - Reset: weekStart, deadline, prompts (local fallback), selectedPromptId, workflow, submittedAt, regenCount
   - Set `autoGenPending = true` → AI prompts generate on next page load
4. User picks 1 of 3 prompts → locks in, starts 1-hour confirmation window
5. User works through 7 workflow steps (checkboxes)
6. User submits → locked, stats form opens 7 days later
7. User records likes → finalScore calculated, added to history

### Cycle Start Calculation
```dart
DateTime getCurrentCycleStart(Preferences prefs, [DateTime? date]) {
  date ??= DateTime.now();
  final tz = prefs.timezone ?? "Europe/Budapest";
  // Get current date in user's timezone
  // Find the most recent occurrence of cycleDay
  final anchorIndex = cycleDayToIndex[prefs.cycleDay ?? "Friday"] ?? 5;
  final currentDayIndex = date.weekday % 7; // Sunday=0
  final diff = (currentDayIndex - anchorIndex + 7) % 7;
  return date.subtract(Duration(days: diff));
}
```

### Project Start Window
When a prompt is chosen, a 1-hour window opens. If not confirmed within 1 hour, the selection resets.
```dart
class ProjectStartWindow {
  String type;         // "weekly" | "big"
  String label;
  String startedAt;    // ISO
  String expiresAt;    // ISO (startedAt + 1 hour)
  bool confirmed;
}
```

---

## 5. Prompt System (CRITICAL SECTION)

### 3 Prompt Levels
| Level | Points | Rules |
|---|---|---|
| **Sequence** | 10 | Pure visual. No talking. Music + image only. Videographer is ALONE. All shots: tripod, locked-off, timer, or camera on surface. |
| **Short Story** | 30 | Solo on screen. Films themselves. Same camera rules as Sequence. One spoken line max. |
| **Story + Character** | 50 | Videographer + 1-2 friends. Handheld allowed. Light dialogue. |

### Local Fallback Prompts
If AI is unavailable, 6 templates per level are randomly picked. Each template has a `cat` (category) and `text`.

Example categories: `moving_towns`, `morning_routine`, `rain_walk`, `studio_pack`, `dawn_park`, `window_light`, `missed_call`, `quit_job`, `creative_block`, `parent_visit`, `two_creators`, `old_friend`

### Inspiration System
7 real Instagram creators are stored in `CREATOR_STYLES`:
```dart
class CreatorStyle {
  String handle;           // e.g. "@nicholasklepper"
  String profileUrl;       // full Instagram URL
  String style;            // description of their visual style
  String referenceHint;    // what to look for in their feed
}
```

3 random creators are picked per generation. Each prompt gets 1 creator as inspiration.

### AI Prompt Generation
- **Default**: auto-generates on new week (`autoGenPending = true`, `autoGenerate = true`)
- **Manual**: user can regenerate up to **3 times per week** via the generator modal
- **Providers**: Groq (free, default) or OpenAI (paid)
- **Default model**: `llama-3.3-70b-versatile`

#### API Call
**Endpoint**: `POST /api/generate-prompts`
**Body**:
```json
{
  "provider": "groq",
  "model": "llama-3.3-70b-versatile",
  "inspirations": [/* 3 CreatorStyle objects */],
  "seasonalPrompts": false,
  "region": "Hungary",
  "filmmakingGoal": "",
  "contentType": ""
}
```

#### LLM Call Structure
Both Groq and OpenAI use the same OpenAI-compatible endpoint:
```
POST {base}/chat/completions
Headers: Authorization: Bearer {API_KEY}, Content-Type: application/json
Body: { model, temperature: 0.85, messages: [{ role: "system", content }, { role: "user", content }] }
```

Provider configs:
- **Groq**: base = `https://api.groq.com/openai/v1`, keyVar = `GROQ_API_KEY`
- **OpenAI**: base = `https://api.openai.com/v1`, keyVar = `OPENAI_API_KEY`

### EXACT SYSTEM PROMPT (copy verbatim):

```
You write hyper-specific weekly story prompts for a SOLO videographer who films themselves. Write in English. Keep writing clear and direct: short sentences, common vocabulary, no jargon, no flowery language. Output ONLY a JSON array with exactly 3 objects. Each object has these keys:
- text: the prompt itself (the scene the videographer will shoot). 100 to 160 words. Describe the exact location, time of day, what the videographer does in the scene, what objects are present, what changes or happens, and the mood. Be cinematic and specific — name surfaces, textures, weather, the position of light, small actions. Do NOT include camera or shooting instructions in text; those go in the shots array.
- shots: an array of 3 to 5 strings. Each string is one specific camera angle or shot. Start each shot with WHEN in the scene to use it (e.g. "Opening — ", "When they pick up the phone — ", "Final shot — "). Then include lens focal length, camera movement, lighting direction, and framing. CRITICAL: For Sequence and Short Story levels, the videographer is ALONE — there is nobody behind the camera. ALL shots must be achievable solo: tripod, locked-off, timer, or camera placed on a surface. Do NOT suggest handheld tracking, dolly, or pan-follows for these levels (nobody is there to operate the camera while the subject is in frame). Handheld shots are ONLY allowed when shooting objects/details with nobody in frame, or for the Story + Character level where a friend can hold the camera. Each shot: 15-25 words.
- outcome: one sentence naming the closing image or what the viewer sees at the end. Concrete and visual.
- purpose: one sentence stating the message, takeaway, or reason behind the story.
- emotion: 1 to 3 short emotion words separated by commas (e.g. "quiet relief, doubt").
- inspiration: the creator's handle you chose for this prompt.
- category: a short snake_case tag that YOU invent. Pick a fresh, specific theme for each prompt (e.g. "fading_routine", "night_bus_home", "kitchen_doubt"). Never reuse the same category between prompts.
- level: one of "Sequence", "Short Story", "Story + Character".
- points: 10, 30, or 50 matching the level.
- songs: an array of exactly 3 objects, each with "title" (song name), "artist" (performer), "tier" (MUST be exactly one of: "best_match", "trending", "classic_fit"), and "why" (one sentence on why it fits). The 3 songs MUST follow this EXACT structure:
  1. First song: tier MUST be "best_match" — the song that genuinely fits the story mood and energy best, any era, any popularity level.
  2. Second song: tier MUST be "trending" — a song that is currently trending and popular on Instagram Reels or TikTok (2024-2026), that also fits the theme reasonably well. Pick songs people actually use in short-form video right now.
  3. Third song: tier MUST be "classic_fit" — a song that is still popular and widely recognized (not necessarily brand new), and fits the mood well. Think timeless hits or recent classics people still listen to.
IMPORTANT: The tier field MUST be exactly "best_match", "trending", or "classic_fit" — do not use any other values.
- licenseFreeKeywords: an array of 2-3 search keywords/phrases the user can type into a royalty-free music library (like Epidemic Sound, Artlist, or YouTube Audio Library) to find similar-sounding tracks. Be specific about mood and genre, e.g. "ambient piano melancholy" or "lo-fi warm acoustic morning".
No markdown, no commentary, no trailing prose. Just the JSON array.
```

### EXACT USER PROMPT (copy verbatim, dynamic parts marked with `${}`):

```
Create 3 weekly prompts. Each prompt MUST be a CONCRETE scenario, not abstract. Bad: "a conversation about life". Good: "you sit in your kitchen at 6 AM, rain streaking the window, staring at a job offer email on your phone. The espresso machine hisses. A half-packed suitcase is open on the floor. You trace the rim of the mug with your thumb. You pick up the phone, put it down, then open the kitchen window and let the cold air in. Outside the street is empty. You stand there breathing and decide nothing."

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
${inspirationGuide}

Set inspiration to the chosen handle only.${locationHint}
```

**`inspirationGuide`** is built as:
```
@handle (profileUrl): style description. Reference hint: hint text
```
for each of the 3 randomly selected creators.

**`locationHint`** is conditionally appended if `region` or `seasonalPrompts` is set. It includes:
- Geographic plausibility constraints for the region
- Current season detection (based on month + hemisphere)
- Rules: 1/3 prompts lean into current season, 2/3 can be neutral, none may contradict season

### Server-Side Song Validation
After LLM response, the server validates:
1. Each prompt has exactly 3 songs
2. Each song has tier in `["best_match", "trending", "classic_fit"]`
3. If invalid, auto-fixes with placeholder songs or corrects tier names by index

### AI Response Parsing (`parseAiPrompts`)
- Tries `JSON.parse(content)` first
- Falls back to regex extraction: `/\[\s*\{[\s\S]*\}\s*\]/`
- Maps each of the 3 objects to a `Prompt` with auto-generated IDs: `"aip_<timestamp>_<index>"`
- Merges inspiration data from the selected creators

### Regeneration Limit
- **3 regenerations per week** (`REGEN_LIMIT = 3`)
- Counter resets when `weekStart` changes
- `regensLeft()` = max(0, 3 - regenCount)

### Custom Prompts
User can write their own prompt with:
- Level (Sequence/Short Story/Story + Character)
- Category (text input)
- Creator handle (text input)
- Full prompt text (textarea)
- Outcome, Purpose, Feeling (all optional)
- Source = `"custom"`, ID = `"custom_<timestamp>"`

### Saved Prompts (Idea Library)
- Any prompt can be bookmarked (★ toggle)
- Saved prompts stored in `state.savedPrompts[]`
- Can be used in future weeks before choosing main prompt
- ID: `"sp_<timestamp>_<random>"`

---

## 6. Pages / Tabs

### 6.1 Login Page (`login.html`)
- Email + PIN form
- Registration form (display name, email, PIN)
- Stores auth in sessionStorage
- Not gated by auth

### 6.2 Dashboard / Home (`index.html`)
- **Overview cards**: Total Score, Completed Weeks, Skill Score, Avg Likes, Most Liked Post
- **Streak badge** (🔥) in user bar
- **Rank label** (e.g. "Starter") with "X score to next rank"
- **Week info**: cycle start date, deadline, countdown timer
- **Project status**: No prompt / In progress / Submitted
- **Workflow progress bar**: X/7 steps
- **Reminder banner**: pending stats, or "submitted, stats open on DATE"
- **Pending stats list**: projects waiting for likes recording
- **Big project panel** (if active)
- **Leaderboard** (fetched from server)
- **Live clock** showing current date/time in user's timezone
- **Live countdown** to deadline

### 6.3 Project Page (`project.html`)
- **Hero**: total score, week start, deadline
- **Lock banner**: shows confirmation window or submission status
- **Prompt section** ("Choose a prompt"):
  - 3 prompt cards (or 1 if selected)
  - Each card shows: level pill, points, category tag, save ★ button
  - Prompt text (100-160 words)
  - Expandable: Shots (ordered list), Songs (3 with tier badges), License-free keywords
  - Outcome, Purpose, Feeling metadata
  - Creator link
  - "Choose this" button
- **Action buttons**: Generate (AI modal), Write your own (custom modal), Saved prompts (library modal)
- **Workflow section** (after prompt selected):
  - 7 checkboxes with day labels
  - Progress bar
- **Gear used picker**: checkboxes for all owned gear, grouped by category
- **Stats section** (after submission):
  - Phase 1 (before unlock): "Add your Instagram reel URL"
  - Phase 2 (after 7 days): "Record your likes" — manual entry or auto-fetch (admin)
- **Big project section** (if active): replaces weekly workflow, shows big project info

### 6.4 History Page (`history.html`)
- List of all completed projects (newest first)
- Each entry shows: level, points, final score, prompt text, inspiration, likes, IG link
- Expandable workflow timeline per entry
- **Progress timeline**: all progress log entries across all projects

### 6.5 Gear Page (`gear.html`)
- **Stats**: total score, points spent on gear, owned count, borrowed count
- **Gear list** (sortable by: recent, category, brand, ownership):
  - 3 categories: Filming gear, Editing gear, Digital asset
  - Each item: name, category, brand, ownership type, cost, notes, usage count, idle days
  - Actions: change ownership, change lifecycle (active/rested/retired), +1 outside use, remove
  - Idle warning: suggests resting gear idle >= 30 days
- **Add gear form**: name, category, brand, ownership (purchased/owned/borrowed), cost, owner, notes
  - Purchasing gear deducts points from totalScore
- **Subscriptions section**: name, amount (HUF), period (monthly/yearly), notes
  - Monthly/yearly totals displayed

### 6.6 Skill Page (`skill.html`)
- **Skill score** and **rank label**
- **Total likes** across all projects
- **Past likes list**: all projects sorted by likes (highest first)
- **Skill journal**: focus area + notes entries
- **AI plan**: generated weekly practice plan
- **Focus areas**: editing, cinematography, sound_design, color_grading, storytelling, directing

### 6.7 Leaderboard Page (`leaderboard.html`)
- Fetched from `/api/leaderboard`
- Shows: rank #, rank icon, display name (linked to profile), rank pill, total score
- Current user highlighted
- **Achievements section** (collapsible, hidden by default):
  - 17 badge chips with progress indicators
  - Earned: accent background, full icon
  - Unearned: muted, ⬜ icon, progress fraction (e.g. "3/5")

### 6.8 Settings Page (`settings.html`)
- **Two tabs**: Personal / Core
- **AI settings**: provider (Groq/OpenAI), model selector, auto-generate toggle
- **Preferences**: region, timezone, seasonal prompts toggle, cycle day, filmmaking goal, content type
- **Notifications**: enable/disable, test button, install PWA button
- **Instagram** (admin): test connection, load posts grid
- **Diagnostics**: Groq key status, OpenAI key status, Instagram status, server uptime
- **Admin user list**: all users with Instagram handles
- **Feedback section**: submit (user) / view+delete (admin)
- **Updates section**: post updates with optional push notification (admin), view list (all)
- **Data management**: export JSON backup, import backup, clear history, clear test data, reset all, delete account
- **Change PIN**: current PIN + new PIN form

### 6.9 Profile Page (`profile.html`)
- Public (no auth required), accessed via `?u=<username>`
- Shows: display name, bio, scores/rank, project history, gear
- Visibility controlled by user's `profileVisibility` settings

### 6.10 Admin Page (`admin.html`)
- User management: create, edit (name/PIN/role), delete
- View all user scores

---

## 7. API Endpoints

### Auth
| Method | Path | Auth | Body | Notes |
|---|---|---|---|---|
| POST | `/api/auth/login` | No | `{email, pin}` | Returns `{token, user}` |
| POST | `/api/auth/register` | No | `{displayName, email, pin}` | Creates user, returns `{ok, user}` |
| POST | `/api/auth/logout` | Yes | — | Deletes session |
| GET | `/api/auth/me` | Yes | — | Returns user info |

### User Data
| Method | Path | Auth | Body | Notes |
|---|---|---|---|---|
| POST | `/api/user/sync` | Yes | `{totalScore, completedWeeks, rankLabel, history, gear, pushSnapshot}` | Debounced from client |
| PUT | `/api/user/profile` | Yes | `{profileVisibility, instagram, displayName, bio}` | |
| PUT | `/api/user/pin` | Yes | `{currentPin, newPin}` | |
| GET | `/api/user/preferences` | Yes | — | Returns server-stored prefs |
| PUT | `/api/user/preferences` | Yes | `{region, timezone, cycleDay, seasonalPrompts, accent}` | |
| DELETE | `/api/user/account` | Yes | — | Non-admin only |

### Public
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/profile/:username` | No | Public profile with visibility |
| GET | `/api/leaderboard` | No | Sorted by totalScore desc |

### AI
| Method | Path | Auth | Body | Notes |
|---|---|---|---|---|
| POST | `/api/generate-prompts` | No | `{provider, model, inspirations, seasonalPrompts, region, filmmakingGoal, contentType}` | Returns `{content: [3 prompts]}` |
| POST | `/api/skill-feedback` | No | `{provider, model, focusArea, notes, history, stats}` | Returns `{content: string}` |

### Instagram (admin only)
| Method | Path | Auth | Body/Params | Notes |
|---|---|---|---|---|
| POST | `/api/instagram-stats` | Yes+Admin | `{url}` | Lookup likes/views for a post |
| GET | `/api/instagram-recent` | Yes+Admin | `?limit=N&insights=true/false` | All posts with stats |

### Admin
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/admin/users` | Yes+Admin | List all users |
| POST | `/api/admin/users` | Yes+Admin | Create user |
| PUT | `/api/admin/users/:id` | Yes+Admin | Edit user |
| DELETE | `/api/admin/users/:id` | Yes+Admin | Delete user (non-admin) |

### Feedback & Updates
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/feedback` | Yes | Admin sees all, users see own |
| POST | `/api/feedback` | Yes | `{message, type}` |
| DELETE | `/api/feedback/:id` | Yes+Admin | |
| GET | `/api/updates` | Yes | All updates |
| POST | `/api/updates` | Yes+Admin | `{title, body, taggedUsers, sendPush}` |
| DELETE | `/api/updates/:id` | Yes+Admin | |

### Push & Diagnostics
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/push/vapid-public` | No | Returns VAPID public key |
| PUT | `/api/user/push-subscription` | Yes | `{subscription}` |
| DELETE | `/api/user/push-subscription` | Yes | |
| GET | `/api/cron/push-tick` | `?k=secret` | Runs scheduled push logic |
| GET | `/api/diagnostics` | No | Key status, uptime |

---

## 8. Push Notification System

### Server-Side Scheduled Push (`runScheduledPushTick`)
Runs every 5 minutes locally, or via cron at `/api/cron/push-tick`.

Notifications sent (per user, deduped by key):
1. **Leaderboard overtake**: someone passed you (rank worsened)
2. **Pending stats**: likes to record (due date reached)
3. **Stats unlock**: 1 week after submission, time to record likes
4. **New prompts**: new week, no prompt selected yet
5. **Daily workflow nudge**: next incomplete step
6. **Score summary**: new history entry
7. **Sunday recap**: weekly summary with streak, rank, score
8. **24h deadline warning**: project not submitted, 24h left
9. **6h deadline warning**: project not submitted, 6h left

### Client-Side Notifications
Additional browser notifications on page load:
- Pending stats ready
- Stats unlocked
- New prompts available
- Next workflow step (daily)
- Last score update
- Sunday recap

---

## 9. Big Projects

A long-form project that replaces the weekly cycle:
- Duration: 14-24 days (configurable)
- Base points: configurable (default 150)
- Has script/notes field
- Uses same 7-step workflow (without day labels)
- Can be finished (queues for stats) or marked DNF (-150 points)
- Weekly prompts remain optional alongside

```dart
class BigProject {
  String id;
  String title;
  String? script;
  String startDate;     // ISO
  String deadline;      // ISO
  int durationDays;
  int basePoints;
  String status;        // "in_progress" | "finished" | "submitted" | "dnf"
  String? finishedAt;   // ISO
}
```

---

## 10. Gear System

```dart
class GearItem {
  String id;
  String name;
  String category;       // "filming" | "editing" | "digital"
  String brand;
  String type;           // "physical" | "digital" (legacy compat)
  String ownership;      // "new_purchase" | "already_owned" | "shared_access"
  int costHuf;
  int pointsCost;        // deducted from totalScore if new_purchase
  String owner;          // who you borrowed from (shared_access only)
  String notes;
  String createdAt;      // ISO
  String usageState;     // "active" | "rested" | "retired"
  int outsideUses;       // uses outside projects
  String? lastOutsideUseAt; // ISO
}
```

- **Purchasing** deducts `costHuf` from `totalScore`
- **Changing ownership** refunds/charges accordingly
- **Removing** refunds if was purchased
- **Usage tracking**: project uses (from history.gearUsed) + outside uses
- **Idle detection**: days since last use, warn at 30+ days

---

## 11. Subscription Tracking

```dart
class SubscriptionItem {
  String id;
  String name;
  int amount;          // in HUF
  String period;       // "monthly" | "yearly"
  String notes;
  String createdAt;    // ISO
}
```

Displayed with monthly/yearly totals.

---

## 12. Skill Feedback AI

**Endpoint**: `POST /api/skill-feedback`

**System prompt**:
```
You are a video editing coach. Reply in plain English at B2 level. Short sentences. No fluff. No markdown.
```

**User prompt**:
```
Plan one week of editing practice for a solo videographer.
Focus: ${focusArea}.
Notes: ${notes || "none"}.
Recent stats: ${JSON.stringify(stats)}.
Recent journal: ${JSON.stringify(history)}.

Structure:
1) One sentence assessment.
2) Four specific exercises (each one or two sentences).
3) Three measurable checkpoints to hit by Friday.
4) One mistake to avoid this week.
Stay under 220 words.
```

Temperature: 0.6

---

## 13. Navigation

5 main tabs (bottom on mobile, side on desktop):
1. **Home** (house icon) → `index.html`
2. **Project** (film icon) → `project.html`
3. **Gear** (package icon) → `gear.html`
4. **Leaderboard** (trophy icon) → `leaderboard.html`
5. **Skills** (bar chart icon) → `skill.html`

Header global controls: Refresh, History, Theme toggle (sun/moon), Settings (cog)

---

## 14. Theme System

- Themes: `"light"` / `"dark"` — set via `data-theme` on `<html>` and `<body>`
- Accent: `"green"` — set via `data-accent` (grey and basic removed)
- CSS variables drive all colors (`--bg`, `--text`, `--accent`, `--card-soft`, etc.)
- Font: SF Pro (Apple system font stack)
- Border radius: 16px
- Transitions: smooth, 200-300ms
- Backdrop blur on nav and toast

---

## 15. Available AI Models

### Groq (free)
| ID | Label |
|---|---|
| `llama-3.3-70b-versatile` | Llama 3.3 70B (recommended) |
| `llama-3.1-8b-instant` | Llama 3.1 8B (fastest) |
| `deepseek-r1-distill-llama-70b` | DeepSeek R1 Distill 70B (reasoning) |
| `qwen-2.5-32b` | Qwen 2.5 32B |
| `gemma2-9b-it` | Gemma 2 9B |
| `mixtral-8x7b-32768` | Mixtral 8x7B (long context) |

### OpenAI (paid)
| ID | Label |
|---|---|
| `gpt-4o` | GPT-4o (recommended, best quality) |
| `gpt-4o-mini` | GPT-4o mini (faster, much cheaper) |
| `gpt-4-turbo` | GPT-4 Turbo |
| `o1-mini` | o1 mini (reasoning, slower) |
| `gpt-3.5-turbo` | GPT-3.5 Turbo (cheapest, basic) |

---

## 16. Creator Styles (Inspiration Pool)

| Handle | Style Summary |
|---|---|
| `@nicholasklepper` | Miami cinematic reels, filmic color grading, halation, warm contrasty tones |
| `@jordans.archivess` | Hand-drawn animation + live footage, diary-style archival storytelling |
| `@omgadrian` | Cinematic music video direction, Filipino heritage, punchy color grading |
| `@batt.maillie` | British fashion cinematic mini-sitcoms, character-driven, multiple roles |
| `@andrews_life` | Life lessons through cinematic visuals, personal documentary-style |
| `@kylenutt` | Warm nostalgic films comparing old vs. present, vintage color grade |
| `@ferry.kch` | Moody European street tones, desaturated earth palette, contemplative |

---

## 17. Service Worker

- Version: `v70`
- Cache name: `creative-loop-static-v70`
- Caches all HTML pages, JS, CSS, manifest, icons
- Strategy: cache-first for static, network-first for API
- Handles push notification display
- Handles `SHOW_NOTIFICATION` message from client

---

## 18. Project Summary (Post-Submit Reflection)

After submitting, an optional modal asks:
- How did you create this project? (textarea)
- What did you change or try differently? (textarea)
- Rating 1-10 (slider)
- Compared to previous work? (better/same/worse dropdown)
- How did you feel? (textarea)

Stored in `state.projectSummaries[]`.

---

## 19. Data Sync Flow

Every `saveState()`:
1. Saves full state to localStorage
2. Debounces (2s) a POST to `/api/user/sync` with:
   - `totalScore`, `completedWeeks`, `rankLabel`
   - Last 50 history entries (trimmed)
   - Gear list
   - `pushSnapshot` containing: weekStart, deadline, submittedAt, selectedPromptId, workflow status, pendingStats due dates, cycleDay, timezone, streak, scores

This sync enables:
- Server-side leaderboard
- Server-side push notifications (scheduled)
- Public profile data

---

## 20. Season Detection Logic

```dart
String getCurrentSeason(String region) {
  final month = DateTime.now().month; // 1-12
  final southernCountries = ["australia", "new zealand", "argentina", "brazil", "south africa"];
  final isSouthern = southernCountries.any((c) => region.toLowerCase().contains(c));

  if (month >= 3 && month <= 5) return isSouthern ? "autumn" : "spring";
  if (month >= 6 && month <= 8) return isSouthern ? "winter" : "summer";
  if (month >= 9 && month <= 11) return isSouthern ? "spring" : "autumn";
  return isSouthern ? "summer" : "winter";
}
```

---

*End of specification. This document covers every feature, data model, API endpoint, AI prompt, and business rule in the Creative Loop application as of v70.*
