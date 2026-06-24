// ============================================================
// RAWBY — public landing / intro page. Warm, editorial, cinematic.
// Tells visitors what RAWBY is and routes them to sign up / log in.
// Lives outside the app Shell (its own background + nav).
// ============================================================
import { Suspense, lazy } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { Eyebrow, Reveal } from "../components/ui/Bits";
import { FilmStrip } from "../components/ui/FilmStrip";
import { Scribble } from "../components/ui/Scribble";
import { AuroraBackground } from "../components/ui/AuroraBackground";
import { Icon, type IconName } from "../components/ui/Icon";
import { Logo } from "../components/ui/Logo";
import { FilmGrain } from "../components/ui/FilmGrain";
import { CategoryBox } from "../components/CategoryBox";
import { LEVELS, WEEKLY_CYCLE } from "../lib/constants";

const AuthHero = lazy(() => import("../components/three/AuthHero"));

const STEPS: { n: string; icon: IconName; title: string; body: string }[] = [
  {
    n: "01",
    icon: "sparkles",
    title: "Get your prompt",
    body: "Every Friday RAWBY hands you a fresh story prompt and a song — tuned to where you live and the season.",
  },
  {
    n: "02",
    icon: "film",
    title: "Shoot it solo",
    body: "No crew, no excuses. Tripod, timer, you. Film through the week with a clear day-by-day cycle.",
  },
  {
    n: "03",
    icon: "trophy",
    title: "Post & climb",
    body: "Drop your reel, let the likes roll in, and watch your score and streak climb the leaderboard.",
  },
];

function TopBar() {
  return (
    <header className="sticky top-0 z-nav">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 md:px-8">
        <Logo size="md" />
        <div className="flex items-center gap-2">
          <Link
            to="/login"
            className="rounded-full px-4 py-2 text-sm font-medium text-text-dim transition-colors hover:text-text-hi"
          >
            Log in
          </Link>
          <Link to="/register">
            <GradientButton className="!px-5 !py-2.5">Sign up free</GradientButton>
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Landing() {
  return (
    <div className="relative min-h-screen overflow-x-hidden">
      <AuroraBackground />
      <FilmGrain opacity={0.06} />

      <div className="relative z-base">
        <TopBar />

        {/* ── Hero ─────────────────────────────────────────── */}
        <section className="mx-auto max-w-6xl px-4 pb-10 pt-10 md:px-8 md:pt-16">
          <div className="grid items-center gap-10 lg:grid-cols-[1.05fr_0.95fr]">
            <motion.div
              initial={{ opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
            >
              <div className="mb-5 flex items-center gap-3">
                <Eyebrow icon="film">The weekly film challenge</Eyebrow>
                <span className="hand text-lg leading-none text-cinema-300">for solo filmmakers</span>
              </div>

              <h1 className="h-display text-[clamp(2.6rem,6.5vw,4.75rem)] font-semibold leading-[0.98] tracking-[-0.02em] text-text-hi [text-wrap:balance]">
                Make one film.{" "}
                <span className="relative inline-block">
                  <span className="italic text-shine">every week.</span>
                  <Scribble className="absolute -bottom-3 left-0 w-full" />
                </span>
              </h1>

              <p className="measure mt-7 text-lg leading-relaxed text-text-dim">
                RAWBY is a weekly ritual for videographers who shoot alone. A fresh prompt, a song,
                a deadline — every Friday. You bring the camera and the nerve.
              </p>

              <div className="mt-8 flex flex-wrap items-center gap-3">
                <Link to="/register">
                  <GradientButton className="!px-7 !py-3.5 text-base">
                    Start filming — it's free <Icon name="arrowRight" size={18} />
                  </GradientButton>
                </Link>
                <Link to="/login">
                  <GradientButton variant="ghost" className="!px-6 !py-3.5 text-base">
                    I have an account
                  </GradientButton>
                </Link>
              </div>

              <div className="mt-7 flex items-center gap-6 text-sm text-text-dim">
                <span className="flex items-center gap-2">
                  <span className="h-display text-2xl font-bold text-text-hi">4</span> levels
                </span>
                <span className="h-4 w-px bg-hairline-strong" />
                <span className="flex items-center gap-2">
                  <span className="h-display text-2xl font-bold text-text-hi">7</span> day cycle
                </span>
                <span className="h-4 w-px bg-hairline-strong" />
                <span className="flex items-center gap-2">
                  <span className="h-display text-2xl font-bold text-text-hi">1</span> filmmaker — you
                </span>
              </div>
            </motion.div>

            {/* 3D cycling object */}
            <div className="relative hidden h-[420px] lg:block">
              <div
                className="pointer-events-none absolute left-1/2 top-1/2 h-80 w-80 -translate-x-1/2 -translate-y-1/2 rounded-full blur-3xl"
                style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.2), transparent 70%)" }}
              />
              <Suspense fallback={null}>
                <AuthHero />
              </Suspense>
            </div>
          </div>
        </section>

        {/* ── Production-cycle ticker ───────────────────────── */}
        <div className="mx-auto max-w-6xl px-4 md:px-8">
          <FilmStrip items={WEEKLY_CYCLE.map((p) => p.phase)} />
        </div>

        {/* ── How it works ─────────────────────────────────── */}
        <section className="mx-auto max-w-6xl px-4 py-20 md:px-8 md:py-28">
          <Reveal className="mb-10 flex items-end justify-between gap-4">
            <div>
              <div className="mb-3"><Eyebrow>How it works</Eyebrow></div>
              <h2 className="h-display text-display-lg font-semibold text-text-hi [text-wrap:balance] md:text-display-xl">
                Three steps. One <span className="italic text-cinema-300">you-sized</span> crew.
              </h2>
            </div>
          </Reveal>
          <div className="grid gap-4 md:grid-cols-3">
            {STEPS.map((s, i) => (
              <Reveal key={s.n} delay={i * 0.08}>
                <GlassCard className="h-full p-6">
                  <div className="mb-5 flex items-center justify-between">
                    <span className="h-display text-display-md font-semibold text-cinema-500/40">{s.n}</span>
                    <span className="flex h-11 w-11 items-center justify-center rounded-full bg-cinema-500/12 text-cinema-300">
                      <Icon name={s.icon} size={20} />
                    </span>
                  </div>
                  <h3 className="h-display text-display-sm font-semibold text-text-hi">{s.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-text-dim">{s.body}</p>
                </GlassCard>
              </Reveal>
            ))}
          </div>
        </section>

        {/* ── Levels ───────────────────────────────────────── */}
        <section className="mx-auto max-w-6xl px-4 pb-20 md:px-8 md:pb-28">
          <Reveal className="mb-10">
            <div className="mb-3"><Eyebrow icon="clapper">Pick your weight class</Eyebrow></div>
            <h2 className="h-display text-display-lg font-semibold text-text-hi md:text-display-xl">
              Four levels, your call.
            </h2>
            <p className="measure mt-3 text-text-dim">
              From a ten-second sequence to a multi-week Big Project — film whichever level fits the
              week you're having. Points scale with ambition.
            </p>
          </Reveal>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {LEVELS.map((l, i) => (
              <Reveal key={l.name} delay={i * 0.06}>
                <GlassCard interactive className="h-full p-5">
                  <div className="mb-4 h-1.5 w-12 rounded-full" style={{ background: l.glow }} />
                  <div className="text-sm font-semibold text-text-hi">{l.name}</div>
                  <div className="h-display mt-1 text-display-md font-bold" style={{ color: l.glow }}>
                    {l.points}
                  </div>
                  <div className="text-xs uppercase tracking-wider text-text-dim">points</div>
                </GlassCard>
              </Reveal>
            ))}
          </div>
        </section>

        {/* ── Aurora ───────────────────────────────────────── */}
        <section className="mx-auto max-w-6xl px-4 pb-20 md:px-8 md:pb-28">
          <Reveal>
            <GlassCard spotlight className="grid gap-8 overflow-hidden p-8 md:grid-cols-2 md:p-12">
              <div className="flex flex-col justify-center">
                <div className="mb-4"><Eyebrow icon="sparkles">Meet Aurora</Eyebrow></div>
                <h2 className="h-display text-display-lg font-semibold text-text-hi [text-wrap:balance]">
                  A cinematic co-pilot in your corner.
                </h2>
                <p className="mt-4 text-text-dim">
                  Stuck on a shot, a cut, or a grade? Aurora knows your gear, your past films, and
                  where you shoot. Plan a trip, work out a prompt, or just ask how to nail that
                  golden-hour look.
                </p>
              </div>
              <div className="flex flex-col justify-center gap-3">
                <div className="ml-auto max-w-[80%] rounded-2xl rounded-br-sm bg-gradient-to-br from-cinema-400 to-cinema-600 px-4 py-2.5 text-sm text-[#1A1100]">
                  How do I fake a dolly with no rig?
                </div>
                <div className="mr-auto max-w-[85%] rounded-2xl rounded-bl-sm border border-hairline bg-chip px-4 py-2.5 text-sm text-text-hi">
                  Put the phone on a skateboard, or a cutting board on a smooth table. Slow, even
                  push — keep your subject locked at one-third frame. Want a focal length for it?
                </div>
              </div>
            </GlassCard>
          </Reveal>
        </section>

        {/* ── Videography map ──────────────────────────────── */}
        <section className="mx-auto max-w-6xl px-4 pb-20 md:px-8 md:pb-28">
          <Reveal className="mb-8 text-center">
            <div className="mb-3 flex justify-center"><Eyebrow icon="aperture">Find your lane</Eyebrow></div>
            <h2 className="h-display mx-auto max-w-2xl text-display-lg font-semibold text-text-hi [text-wrap:balance] md:text-display-xl">
              Every film lands somewhere on your map.
            </h2>
          </Reveal>
          <Reveal>
            <CategoryBox history={[]} />
          </Reveal>
        </section>

        {/* ── Final CTA ────────────────────────────────────── */}
        <section className="mx-auto max-w-5xl px-4 pb-24 md:px-8">
          <Reveal>
            <GlassCard spotlight className="relative overflow-hidden p-10 text-center md:p-16">
              <div
                className="animate-aurora-drift pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full blur-3xl"
                style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.22), transparent 70%)" }}
              />
              <div className="relative">
                <p className="hand text-2xl text-cinema-300">this Friday…</p>
                <h2 className="h-display mt-1 text-[clamp(2.2rem,5vw,3.5rem)] font-semibold leading-[1.02] text-text-hi [text-wrap:balance]">
                  Ready to roll camera?
                </h2>
                <p className="measure mx-auto mt-4 text-text-dim">
                  Join the solo filmmakers turning a blank weekend into a finished film — every week.
                </p>
                <div className="mt-8 flex flex-wrap justify-center gap-3">
                  <Link to="/register">
                    <GradientButton className="!px-8 !py-4 text-base">
                      Create your free account <Icon name="arrowRight" size={18} />
                    </GradientButton>
                  </Link>
                </div>
              </div>
            </GlassCard>
          </Reveal>
        </section>

        {/* ── Footer ───────────────────────────────────────── */}
        <footer className="rule mx-auto max-w-6xl px-4 py-8 md:px-8">
          <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
            <Logo size="sm" />
            <p className="text-xs text-text-dim">
              RAWBY · the weekly film challenge for solo videographers · © 2026
            </p>
            <div className="flex gap-4 text-xs text-text-dim">
              <Link to="/login" className="transition-colors hover:text-text-hi">Log in</Link>
              <Link to="/register" className="transition-colors hover:text-text-hi">Sign up</Link>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
}
