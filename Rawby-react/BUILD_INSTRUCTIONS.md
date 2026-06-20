# RAWBY — React Web Frontend · Build Instructions

> Build a **React web frontend** for RAWBY that talks to the **existing Dart server**.
> Phone app stays Flutter (native APK). React = browser / desktop web only.
> **Do not touch** the Flutter app or the Dart server — only consume the server's REST API.

---

## 0. What RAWBY is

Weekly filmmaking-challenge app for solo videographers. Weekly cycle:

| Day | Phase |
|-----|-------|
| Friday | Song selection + prompt locked |
| Sat–Sun | Filming |
| Mon–Tue | Rough edit |
| Tue–Wed | VFX + text overlays |
| Tue–Wed | SFX + sound design |
| Wed–Thu | Colour grade |
| Friday | Polish + publish |

Scoring: Sequence = 10 pts, Short Story = 30 pts, Story + Character = 50 pts, Big Project = 150 pts.
Late penalty multipliers: ×1.0 on time, ×0.9 day 1, ×0.75 day 2, ×0.5 day 3+.

---

## 1. Stack

- **Vite + React 18 + TypeScript**
- **Tailwind CSS** (design tokens below)
- **Framer Motion** (already installed globally — page transitions, card reveals)
- **TanStack Query** (server state, caching, retry — server is a cold-start Render dyno)
- **Zustand** (local UI/session state)
- **react-router-dom** v6 (routes mirror Flutter `go_router`)
- **axios** (HTTP client with auth interceptor)

```bash
npm create vite@latest . -- --template react-ts
npm i axios @tanstack/react-query zustand react-router-dom framer-motion
npm i -D tailwindcss postcss autoprefixer && npx tailwindcss init -p
```

---

## 2. Backend — DO NOT REBUILD

Base URL: `https://rawby-1.onrender.com`

> ⚠️ **Render free dyno sleeps after ~15 min idle. Cold start = 30–60s.**
> Set axios `timeout: 60000` and retry transient errors 3× with backoff (1.5s × attempt).
> Copy the retry logic from Flutter `lib/services/api_service.dart` lines 49–77.

### Auth
JWT bearer. `POST /api/login` and `/api/register` return `{ token, user }`.
Store token, send `Authorization: Bearer <token>` on every protected call.
On `401` → clear token → redirect to login.

### Endpoints (all `/api/*`)

| Method | Path | Auth | Body / Notes |
|--------|------|------|--------------|
| GET | `/api/health` | no | `{status, service, timestamp}` |
| POST | `/api/login` | no | `{username, password}` → `{token, user}` |
| POST | `/api/register` | no | `{username, displayName, email, password}` |
| GET | `/api/verify-email` | no | query `?token=` |
| GET | `/api/me` | yes | → `{user, snapshot, ...}` full session |
| POST | `/api/generate-prompts` | yes | `{provider, model, inspirations[], seasonalPrompts, region, filmingGoal, contentType}` |
| GET | `/api/leaderboard` | yes | → ranked users |
| GET | `/api/profile/<username>` | yes | public profile |
| POST | `/api/sync` | yes | push full local snapshot |
| POST | `/api/sync-scores` | yes | push score deltas |
| GET | `/api/instagram-recent` | yes | query `?limit=&insights=` |
| POST | `/api/fetch-reel-likes` | yes | `{url}` |
| POST | `/api/chat` | yes | **AI** — see §3 |
| POST | `/api/skill-feedback` | yes | **AI** — `{provider, model, focusArea, notes, history[], stats}` → `{feedback}` |
| GET | `/api/updates` | yes | global announcements |
| POST | `/api/community-prompt` | yes | `{text, category}` |
| POST | `/api/suggestions` | yes | `{text}` |
| GET | `/api/suggestions` | yes | → `{suggestions[]}` |

Admin routes (`/api/admin/*`, `/api/feedback`, `/api/users`) — gate behind an admin flag on the user object; skip in v1 unless needed.

### AI chat — `POST /api/chat`
```jsonc
// request
{
  "messages": [{ "role": "user", "content": "..." }],   // full history
  "context":  { "displayName", "rank", "totalScore", "streak",
                "regensLeft", "daysLeft", "promptLevel", "promptText" },
  "provider": "groq"   // "groq" (free, llama-3.3-70b) | "claude" (claude-sonnet-4-6)
}
// response
{ "reply": "..." }
```
Assistant persona = **Aurora** (cinematic filmmaking co-pilot). Replies are plain text, no markdown, < 150 words. Render as plain conversational text — don't markdown-parse.

**Provider toggle:** expose a setting (default `groq` = free). Both providers hit the same endpoint; only the `provider` field changes. Server reads `GROQ_API_KEY` / `ANTHROPIC_API_KEY` from its own env — **React never holds AI keys.**

---

## 3. Routes (mirror Flutter)

```
/login  /register  /          (home/dashboard)
/prompts  /leaderboard  /gear  /idea-bank
/assistant (Aurora chat)  /profile  /settings
```
Use a shell layout: side-nav on desktop (≥768px), bottom-nav on mobile width.

---

## 4. Design tokens (Tailwind `theme.extend.colors`)

Cinematic, dark-first. Flagship accent = **cinema amber**. Match the Flutter look.

```js
colors: {
  cinema:  { 300:'#F6DC9C', 400:'#F0C868', 500:'#E8B647', 600:'#C9942C', 700:'#8F6918' },
  green:   { 300:'#8FBD93', 400:'#6FA373', 500:'#5A8A5E', 600:'#3D6B41', 700:'#2A4D2D' },
  ink: { bg:'#0A0B0D', surface:'#161719', card:'#1E2023', border:'#2A2C30' },
  text:    { hi:'#F1F1F0', dim:'#9CA3AF' },
  danger:'#EF4444', warning:'#F59E0B', caution:'#FBBF24', success:'#22C55E', info:'#3B82F6',
}
```

**Fonts:** Display = **Playfair Display** (headings, hero). Body = **Inter**. Load via `@fontsource` or Google Fonts.

**Level gradients:**
- Sequence → `#6FA373 → #3D6B41`
- Short Story → `#E8B647 → #C97E2C`
- Story + Character → `#E85D75 → #B12B5C`

### Signature components (port from Flutter)
- **GlassCard** — `backdrop-blur`, translucent fill (`white/4` dark), 1px `white/12` border, radius 18px, soft shadow `0 12px 24px black/35`.
- **AuraBackground** — fixed full-bleed; 2 radial blobs (primary top-left, secondary bottom-right) + heavy blur behind content.
- **GradientButton** — level/accent linear gradient, glow shadow = `accent/35`.
- **FilmTag** — gradient pill chip.
- **StatTile** — icon box + value + label, bento grid (home = 4-col grid of 8 stat tiles).

### Cinematic motion (Framer Motion)
- Page transition: fade + 4% slide-up, spring `cubic(0.34, 1.32, 0.64, 1.0)`.
- Card reveal: stagger children, `fadeIn + slideY(8% → 0)`, 40ms stagger.
- Hero: subtle scale-in.
- Optional cinematic flourish: film-grain overlay + faint letterbox bars on hero — keep subtle.

---

## 5. Env

```
# .env  — React holds NO secrets, only the API base
VITE_API_BASE_URL=https://rawby-1.onrender.com
```
AI keys live on the **server** only (`GROQ_API_KEY`, `ANTHROPIC_API_KEY`). Never put them in React.

---

## 6. Build order

1. Scaffold Vite + Tailwind + tokens + fonts.
2. axios client + auth interceptor + cold-start retry (copy from Flutter).
3. Zustand auth store + TanStack Query provider.
4. Login / Register → store token.
5. Shell layout (side-nav / bottom-nav) + Framer page transitions.
6. Home dashboard: NextStep hero + bento StatTiles + Aurora CTA + history.
7. Prompts, Leaderboard, Gear, Idea Bank, Profile, Settings.
8. Aurora chat (`/api/chat`) with groq/claude provider toggle.
9. Polish: AuraBackground, glass, gradients, motion, film-grain.
10. `npm run build` → deploy static (Render static site / Vercel / Netlify).

## 7. Deploy
Static SPA. Add `render.yaml` static-site or use Vercel. Set `VITE_API_BASE_URL` env at build. No server needed — backend already live.

---

### Reference files in the Flutter app (read, don't modify)
- API surface: `lib/services/api_service.dart`
- Cold-start retry: `lib/services/api_service.dart:49`
- Palette: `lib/theme/app_colors.dart`
- Theme/fonts/motion: `lib/theme/app_theme.dart`
- Glass / tiles / buttons: `lib/widgets/common/glass_card.dart`
- Home layout: `lib/screens/home_screen.dart`
- AI server handler: `server/lib/handlers/ai_handlers.dart`
- All routes: `server/lib/router.dart`
