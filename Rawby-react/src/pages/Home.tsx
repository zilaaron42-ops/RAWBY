import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { StatTile } from "../components/ui/StatTile";
import { FilmTag } from "../components/ui/FilmTag";
import { Icon } from "../components/ui/Icon";
import { SkeletonCard } from "../components/ui/Skeleton";
import { CategoryBox } from "../components/CategoryBox";
import { useMe } from "../hooks/queries";
import { useProgress } from "../hooks/useProgress";
import { useAuth } from "../store/auth";
import { useSettings } from "../store/settings";
import { WEEKLY_CYCLE } from "../lib/constants";
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

// Which weekdays each cycle phase covers (0 Sun … 6 Sat).
const DAY_SET: Record<string, number[]> = {
  Friday: [5],
  "Sat–Sun": [6, 0],
  "Mon–Tue": [1, 2],
  "Tue–Wed": [2, 3],
  "Wed–Thu": [3, 4],
};
const isToday = (dayLabel: string) => (DAY_SET[dayLabel] ?? []).includes(new Date().getDay());

export default function Home() {
  const { data, isLoading } = useMe();
  const user = useAuth((s) => s.user);
  const prog = useProgress();

  const snap: Snapshot = { ...FALLBACK, ...(data?.snapshot ?? {}) };
  const history = data?.snapshot?.history ?? data?.history ?? [];
  const gearCount = data?.snapshot?.gear?.length ?? 0;
  const region = useSettings((s) => s.region);
  const seasonal = useSettings((s) => s.seasonalPrompts);
  const showCategories = useSettings((s) => s.showCategories);

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

  const realPrompt = data?.snapshot?.promptText;
  const hasPrompt = !!realPrompt;
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
        {hasPrompt ? (
          <div className="relative flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
            <div className="max-w-xl">
              <div className="mb-3 flex flex-wrap items-center gap-2">
                <FilmTag level={snap.promptLevel} />
                {snap.phase && (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-chip px-3 py-1 text-xs font-medium text-text-dim">
                    <Icon name="film" size={13} /> {snap.phase}
                  </span>
                )}
              </div>
              <h2 className="h-display text-2xl font-bold leading-snug text-text-hi md:text-[1.75rem]">
                {realPrompt}
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
                  <span className="text-[10px] uppercase tracking-wider text-text-dim">days left</span>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="relative">
            <h2 className="h-display text-2xl font-bold text-text-hi md:text-[1.75rem]">
              No prompt locked in yet.
            </h2>
            <p className="mt-1 text-sm text-text-dim">
              Generate this week's set or write your own — then it shows up here with your countdown.
            </p>
            <div className="mt-6 flex flex-wrap gap-3">
              <Link to="/prompts">
                <GradientButton>
                  <Icon name="sparkles" size={16} /> Generate a prompt
                </GradientButton>
              </Link>
              <Link to="/assistant">
                <GradientButton variant="ghost">
                  <Icon name="sparkles" size={16} /> Plan with Aurora
                </GradientButton>
              </Link>
            </div>
          </div>
        )}
      </GlassCard>

      {/* Bento stat tiles */}
      <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatTile icon="medal" value={`#${snap.rank || "—"}`} label="Rank" accent="#E8B647" />
        <StatTile icon="star" value={nf.format(snap.totalScore ?? 0)} label="Total score" accent="#6FA373" />
        <StatTile icon="flame" value={snap.streak ?? 0} label="Streak" accent="#E85D75" />
        <StatTile icon="refresh" value={snap.regensLeft ?? 0} label="Regens left" accent="#3B82F6" />
      </div>

      {/* Kit & tuning */}
      <div className="mt-3 flex flex-wrap items-center gap-2 text-xs">
        <Link
          to="/gear"
          className="inline-flex items-center gap-1.5 rounded-full bg-chip px-3 py-1.5 text-text-dim transition-colors hover:text-text-hi"
        >
          <Icon name="aperture" size={13} /> {gearCount} {gearCount === 1 ? "gear item" : "gear items"}
        </Link>
        <Link
          to="/settings"
          className="inline-flex items-center gap-1.5 rounded-full bg-chip px-3 py-1.5 text-text-dim transition-colors hover:text-text-hi"
        >
          <Icon name="aperture" size={13} /> {region}
          {seasonal ? " · seasonal" : ""}
        </Link>
        <Link
          to="/prompts"
          className="inline-flex items-center gap-1.5 rounded-full bg-cinema-500/15 px-3 py-1.5 font-semibold text-cinema-300 transition-colors hover:bg-cinema-500/25"
        >
          <Icon name="sparkles" size={13} /> Generate prompts
        </Link>
      </div>

      {/* Videography box */}
      {showCategories && (
        <div className="mt-8">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="h-display text-lg font-bold text-text-hi">Your videography</h3>
            <Link to="/settings" className="text-xs text-text-dim hover:text-text-hi">
              Hide in Settings
            </Link>
          </div>
          <CategoryBox history={history} />
        </div>
      )}

      {/* Weekly cycle — tap to track your progress (only with an active prompt) */}
      {hasPrompt && (
      <GlassCard className="mt-8">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="h-display text-lg font-bold text-text-hi">Your progress</h3>
          <span className="text-xs text-text-dim">
            {prog.done.length}/{WEEKLY_CYCLE.length} phases · tap to tick
          </span>
        </div>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
          {WEEKLY_CYCLE.map((p, i) => {
            const done = prog.done.includes(p.phase);
            const today = isToday(p.day);
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
                    : today
                      ? "border-cinema-500/70 bg-cinema-500/15 shadow-glow-sm"
                      : "border-hairline bg-chip hover:border-hairline-strong"
                }`}
              >
                <div className="flex items-center justify-between">
                  <span
                    className={`text-[10px] font-semibold uppercase tracking-wider ${
                      today && !done ? "text-cinema-400" : "text-text-dim"
                    }`}
                  >
                    {today ? "Today" : p.day}
                  </span>
                  {done && <Icon name="check" size={13} className="text-green-400" />}
                </div>
                <div className={`mt-1 text-sm font-semibold ${today && !done ? "text-cinema-300" : "text-text-hi"}`}>
                  {p.phase}
                </div>
                <div className="mt-0.5 text-[11px] leading-tight text-text-dim">{p.desc}</div>
              </motion.button>
            );
          })}
        </div>
        {WEEKLY_CYCLE.every((p) => prog.done.includes(p.phase)) && (
          <Link to="/prompts" className="mt-4 block">
            <GradientButton className="w-full">
              <Icon name="check" size={16} /> All phases done — submit your film
            </GradientButton>
          </Link>
        )}
      </GlassCard>
      )}

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
