import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { StatTile } from "../components/ui/StatTile";
import { FilmTag } from "../components/ui/FilmTag";
import { Icon } from "../components/ui/Icon";
import { SkeletonCard } from "../components/ui/Skeleton";
import { useMe } from "../hooks/queries";
import { useProgress } from "../hooks/useProgress";
import { useAuth } from "../store/auth";
import { WEEKLY_CYCLE } from "../lib/constants";
import { stagger } from "../lib/motion";
import type { Snapshot } from "../types";

const FALLBACK: Snapshot = {
  rank: 0,
  totalScore: 0,
  streak: 0,
  regensLeft: 3,
  daysLeft: 5,
  promptLevel: "Short Story",
  promptText: "Tell a story of someone leaving a place they love — in 60 seconds.",
  phase: "Filming",
};

const nf = new Intl.NumberFormat("en-US");

export default function Home() {
  const { data, isLoading } = useMe();
  const user = useAuth((s) => s.user);
  const prog = useProgress();

  const snap: Snapshot = { ...FALLBACK, ...(data?.snapshot ?? {}) };
  const history = data?.snapshot?.history ?? data?.history ?? [];

  if (isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <SkeletonCard />
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <SkeletonCard key={i} />
            ))}
          </div>
        </div>
      </PageTransition>
    );
  }

  const activePhaseIdx = Math.max(
    0,
    WEEKLY_CYCLE.findIndex((p) => p.phase === snap.phase)
  );
  const progress = Math.min(1, Math.max(0, (7 - (snap.daysLeft ?? 0)) / 7));

  return (
    <PageTransition>
      {/* Greeting */}
      <div className="mb-6">
        <div className="text-[0.7rem] font-semibold uppercase tracking-[0.22em] text-cinema-500">
          {snap.weekNumber ? `Week ${snap.weekNumber}` : "This week"}
        </div>
        <h1 className="h-display text-[2rem] font-bold leading-tight text-text-hi md:text-[2.5rem]">
          Welcome back, {user?.displayName?.split(" ")[0] ?? "filmmaker"}.
        </h1>
      </div>

      {/* Next-step hero */}
      <GlassCard className="relative overflow-hidden p-6 md:p-8">
        <div
          className="pointer-events-none absolute -right-16 -top-16 h-56 w-56 rounded-full blur-3xl"
          style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.22), transparent 70%)" }}
        />
        <div className="relative flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div className="max-w-xl">
            <div className="mb-3 flex flex-wrap items-center gap-2">
              <FilmTag level={snap.promptLevel} />
              <span className="inline-flex items-center gap-1.5 rounded-full bg-chip px-3 py-1 text-xs font-medium text-text-dim">
                <Icon name="film" size={13} /> {snap.phase}
              </span>
            </div>
            <h2 className="h-display text-2xl font-bold leading-snug text-text-hi md:text-[1.75rem]">
              {snap.promptText}
            </h2>
            <div className="mt-6 flex flex-wrap gap-3">
              <Link to="/prompts">
                <GradientButton>
                  Open this week’s prompt
                  <Icon name="arrowRight" size={16} />
                </GradientButton>
              </Link>
              <Link to="/assistant">
                <GradientButton variant="ghost">
                  <Icon name="sparkles" size={16} /> Ask Aurora
                </GradientButton>
              </Link>
            </div>
          </div>

          {/* Countdown ring */}
          <div className="flex shrink-0 items-center justify-center">
            <div className="relative flex h-32 w-32 items-center justify-center">
              <svg viewBox="0 0 120 120" className="h-32 w-32 -rotate-90">
                <circle cx="60" cy="60" r="52" fill="none" stroke="rgb(var(--text-dim) / 0.18)" strokeWidth="8" />
                <motion.circle
                  cx="60" cy="60" r="52" fill="none" stroke="rgb(var(--c-500))" strokeWidth="8"
                  strokeLinecap="round" strokeDasharray={2 * Math.PI * 52}
                  initial={{ strokeDashoffset: 2 * Math.PI * 52 }}
                  animate={{ strokeDashoffset: 2 * Math.PI * 52 * (1 - progress) }}
                  transition={{ duration: 1.1, ease: [0.22, 1, 0.36, 1] }}
                />
              </svg>
              <div className="absolute flex flex-col items-center">
                <span className="h-display text-3xl font-bold text-text-hi tabular-nums">
                  {snap.daysLeft}
                </span>
                <span className="text-[10px] uppercase tracking-wider text-text-dim">
                  days left
                </span>
              </div>
            </div>
          </div>
        </div>
      </GlassCard>

      {/* Bento stat tiles */}
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4"
      >
        <StatTile icon="medal" value={`#${snap.rank || "—"}`} label="Rank" accent="#E8B647" />
        <StatTile icon="star" value={nf.format(snap.totalScore ?? 0)} label="Total score" accent="#6FA373" />
        <StatTile icon="flame" value={snap.streak ?? 0} label="Streak" accent="#E85D75" />
        <StatTile icon="refresh" value={snap.regensLeft ?? 0} label="Regens left" accent="#3B82F6" />
      </motion.div>

      {/* Weekly cycle — tap to track your progress */}
      <GlassCard className="mt-6">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="h-display text-lg font-bold text-text-hi">Your progress</h3>
          <span className="text-xs text-text-dim">
            {prog.done.length}/{WEEKLY_CYCLE.length} phases · tap to tick
          </span>
        </div>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
          {WEEKLY_CYCLE.map((p, i) => {
            const done = prog.done.includes(p.phase);
            const active = i === activePhaseIdx;
            return (
              <motion.button
                key={p.phase + i}
                type="button"
                onClick={() => prog.toggle.mutate(p.phase)}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.04, ease: [0.22, 1, 0.36, 1] }}
                className={`rounded-xl border p-3 text-left transition-colors ${
                  done
                    ? "border-green-500/40 bg-green-500/[0.08]"
                    : active
                      ? "border-cinema-500/60 bg-cinema-500/10"
                      : "border-hairline bg-chip hover:border-hairline-strong"
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-semibold uppercase tracking-wider text-text-dim">
                    {p.day}
                  </span>
                  {done && <Icon name="check" size={13} className="text-green-400" />}
                </div>
                <div className={`mt-1 text-sm font-semibold ${active && !done ? "text-cinema-400" : "text-text-hi"}`}>
                  {p.phase}
                </div>
                <div className="mt-0.5 text-[11px] leading-tight text-text-dim">{p.desc}</div>
              </motion.button>
            );
          })}
        </div>
      </GlassCard>

      {/* History + Aurora */}
      <div className="mt-6 grid gap-4 lg:grid-cols-3">
        <GlassCard className="lg:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="h-display text-lg font-bold text-text-hi">Recent films</h3>
            <Link to="/profile" className="text-xs font-semibold text-cinema-400 hover:underline">
              View all
            </Link>
          </div>
          {history.length === 0 ? (
            <p className="py-8 text-center text-sm text-text-dim">
              No films yet — your first submission shows up here.
            </p>
          ) : (
            <ul className="divide-y divide-divide">
              {history.slice(0, 5).map((h, i) => (
                <li key={h.id ?? i} className="flex items-center justify-between py-3">
                  <div>
                    <div className="text-sm font-semibold text-text-hi">{h.title}</div>
                    <div className="text-xs text-text-dim">
                      {h.level} · {h.date ?? `Week ${h.week ?? "—"}`}
                    </div>
                  </div>
                  <span className="h-display text-lg font-bold text-cinema-400 tabular-nums">
                    {h.score ?? 0}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </GlassCard>

        <GlassCard interactive className="flex flex-col justify-between">
          <div>
            <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-[#E85D75]/15 text-[#E85D75]">
              <Icon name="sparkles" size={22} />
            </div>
            <h3 className="h-display text-lg font-bold text-text-hi">Aurora</h3>
            <p className="mt-1 text-sm text-text-dim">
              Your cinematic co-pilot. Stuck on a shot, a cut, or a grade? Ask.
            </p>
          </div>
          <Link to="/assistant" className="mt-4">
            <GradientButton variant="story" className="w-full">
              Chat with Aurora
            </GradientButton>
          </Link>
        </GlassCard>
      </div>
    </PageTransition>
  );
}
