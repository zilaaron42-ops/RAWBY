# RAWBY — React Web Frontend

Cinematic, 3D-interactive web client for **RAWBY**, the weekly filmmaking
challenge for solo videographers. Talks to the existing Dart server — it does
**not** rebuild the backend, and React never holds AI keys.

## Stack
- **Vite + React 18 + TypeScript**
- **Tailwind CSS** (cinema-amber dark theme, design tokens from the Flutter app)
- **Framer Motion** — page transitions, card reveals, micro-interactions
- **react-three-fiber + three** — spinning 3D film-reel background, dust motes, cursor parallax
- **TanStack Query** — server state + caching (cold-start-friendly)
- **Zustand** — auth/session + AI-provider toggle (persisted)
- **axios** — auth interceptor + cold-start retry (3× backoff), ported from `lib/services/api_service.dart`
- **react-router-dom v6** — routes mirror the Flutter `go_router`

## 3D / cinematic touches
- `AuraScene` — fixed full-bleed `<Canvas>`: two spinning film reels, additive-blended
  dust particles, mouse-parallax rig, radial amber/green glow + vignette. Honors
  `prefers-reduced-motion` (drops to a static gradient).
- `FilmGrain` — animated grain overlay (`mix-blend-overlay`).
- Login/Register split layout with a large 3D reel hero.
- Spring page transitions `cubic(0.34, 1.32, 0.64, 1.0)`, 40 ms staggered card reveals.

## Run
```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # -> dist/  (static SPA)
npm run preview
```

## Env
```
VITE_API_BASE_URL=https://rawby-1.onrender.com
```
The server reads `GROQ_API_KEY` / `ANTHROPIC_API_KEY` from its own env. Aurora's
provider toggle only changes the `provider` field on `POST /api/chat`.

## Routes
`/login` `/register` `/` (dashboard) `/prompts` `/leaderboard` `/gear`
`/idea-bank` `/assistant` (Aurora) `/profile` `/settings`

Side-nav on desktop (≥768px), bottom-nav on mobile.

## Deploy
Static SPA. `render.yaml` (Render static site) included; SPA rewrite via
`public/_redirects` (Netlify) and the Render route rewrite. Works on Vercel too —
set `VITE_API_BASE_URL` at build time.

## Backend reference (read-only, in the Flutter repo)
- API surface: `lib/services/api_service.dart`
- Cold-start retry: `lib/services/api_service.dart:49`
- Palette: `lib/theme/app_colors.dart`
- Routes: `server/lib/router.dart`
- AI handler: `server/lib/handlers/ai_handlers.dart`
