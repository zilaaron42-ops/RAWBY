import { useState } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { StatTile } from "../components/ui/StatTile";
import { CountUp } from "../components/ui/CountUp";
import { FilmTag } from "../components/ui/FilmTag";
import { TiltCard } from "../components/ui/TiltCard";
import { Eyebrow, Reveal } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { SkeletonCard } from "../components/ui/Skeleton";
import { CategoryBox } from "../components/CategoryBox";
import { BorderBeam } from "../components/ui/BorderBeam";
import { FilmDoodle } from "../components/ui/FilmDoodle";
import { PlanTripModal } from "../components/PlanTripModal";
import { useMe } from "../hooks/queries";
import { useProgress } from "../hooks/useProgress";
import { useTrips, useTripAutoActivate, daysUntil } from "../hooks/useTrips";
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
  const { trips, remove: removeTrip } = useTrips();
  useTripAutoActivate(); // any trip due today becomes the active prompt
  const [planOpen, setPlanOpen] = useState(false);

  const snap: Snapshot = { ...FALLBACK, ...(data?.snapshot ?? {}) };
  const history = data?.snapshot?.history ?? data?.history ?? [];
  const gearCount = data?.snapshot?.gear?.length ?? 0;
  const region = useSettings((s) => s.region);
  const seasonal = useSettings((s) => s.seasonalPrompts);
  const showCategories = useSettings((s) => s.showCategories);
  const upcomingTrips = trips.filter((t) => t.status === "planned");
  const activeTrip = trips.find((t) => t.status === "active");

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
  // Hero shows a single short line — the full prompt lives on the Prompts page.
  const shortPrompt = (() => {
    if (!realPrompt) return "";
    const first = realPrompt.split(/(?<=[.!?])\s/)[0].trim();
    return first.length > 120 ? `${first.slice(0, 117).trimEnd()}…` : first;
  })();

  // Holiday mode: the countdown runs off a custom filming window (start →
  // deadline) instead of the weekly 7-day cycle. Set when you lock a prompt
  // with holiday mode on, or when a planned trip auto-activates.
  const DAY = 86_400_000;
  const holiday = !!(snap.filmingStartedAt && snap.filmingDeadline);
  const startMs = holiday ? new Date(snap.filmingStartedAt!).getTime() : 0;
  const deadlineMs = holiday ? new Date(snap.filmingDeadline!).getTime() : 0;
  const daysLeft = holiday ? Math.max(0, Math.ceil((deadlineMs - Date.now()) / DAY)) : snap.daysLeft ?? 0;
  const totalWindow = holiday ? Math.max(1, Math.round((deadlineMs - startMs) / DAY)) : 7;
  const progress = Math.min(1, Math.max(0, (totalWindow - daysLeft) / totalWindow));
  // Which phase is "today" in holiday mode — mapped by elapsed day, not weekday.
  const elapsed = holiday ? Math.min(totalWindow, Math.max(0, Math.round((Date.now() - startMs) / DAY))) : 0;
  const holidayPhaseIdx = holiday
    ? Math.min(WEEKLY_CYCLE.length - 1, Math.floor((elapsed / totalWindow) * WEEKLY_CYCLE.length))
    : -1;

  return (
    <PageTransition>
      {/* Greeting */}
      <motion.div
        className="mb-7"
        initial={{ opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
      >
        <div className="mb-3">
          <Eyebrow icon="film">{snap.weekNumber ? `Week ${snap.weekNumber}` : "This week"}</Eyebrow>
        </div>
        <h1 className="h-display text-display-xl font-semibold leading-[1.02] [text-wrap:balance] md:text-display-2xl">
          <span className="text-text-hi">Welcome back, </span>
          <span className="text-shine">{user?.displayName?.split(" ")[0] ?? "filmmaker"}.</span>
        </h1>
      </motion.div>

      {/* Next-step hero */}
      <TiltCard className="[perspective:1200px]">
      <GlassCard spotlight className="relative overflow-hidden p-6 md:p-8">
        <div
          className="animate-aurora-drift pointer-events-none absolute -right-16 -top-16 h-56 w-56 rounded-full blur-3xl"
          style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.22), transparent 70%)" }}
        />
        <div
          className="animate-aurora-drift pointer-events-none absolute -bottom-20 -left-10 h-52 w-52 rounded-full blur-3xl"
          style={{ background: "radial-gradient(circle, rgb(var(--c-500) / 0.14), transparent 70%)", animationDelay: "-5s" }}
        />
        {hasPrompt ? (
          <div className="relative flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
            <div className="max-w-xl">
              <div className="mb-3 flex flex-wrap items-center gap-2">
                <FilmTag level={snap.promptLevel} />
                {holiday ? (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-cinema-500/15 px-3 py-1 text-xs font-semibold text-cinema-300">
                    <Icon name="sun" size={13} /> {activeTrip ? `Holiday · ${activeTrip.title}` : "Holiday mode"}
                  </span>
                ) : (
                  snap.phase && (
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-chip px-3 py-1 text-xs font-medium text-text-dim">
                      <Icon name="film" size={13} /> {snap.phase}
                    </span>
                  )
                )}
              </div>
              <h2 className="h-display text-display-sm font-semibold leading-tight text-text-hi [text-wrap:balance] md:text-display-md">
                {shortPrompt}
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
                    {daysLeft}
                  </span>
                  <span className="text-[10px] uppercase tracking-wider text-text-dim">days left</span>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <>
            <BorderBeam duration={11} lightWidth={260} />
            <div className="relative grid items-center gap-6 md:grid-cols-[1.12fr_0.88fr]">
              <div>
                <div className="mb-3">
                  <Eyebrow icon="clapper">This week is a blank reel</Eyebrow>
                </div>
                <h2 className="h-display text-display-md font-semibold leading-tight text-text-hi [text-wrap:balance]">
                  Your next film starts with a prompt.
                </h2>
                <p className="measure mt-2.5 text-sm leading-relaxed text-text-dim">
                  Generate this week's set — tuned to {region} and the season — or plan a trip and
                  Aurora lines one up for the day you leave.
                </p>
                <div className="mt-6 flex flex-wrap gap-3">
                  <Link to="/prompts">
                    <GradientButton>
                      <Icon name="sparkles" size={16} /> Generate a prompt
                    </GradientButton>
                  </Link>
                  <GradientButton variant="ghost" onClick={() => setPlanOpen(true)}>
                    <Icon name="sun" size={16} /> Plan a trip
                  </GradientButton>
                </div>
              </div>

              {/* Viewfinder motif — a quiet "ready to roll" frame */}
              <div className="relative hidden aspect-[4/3] md:block">
                <div className="absolute inset-0 rounded-2xl border border-dashed border-hairline-strong" />
                {/* corner ticks */}
                {["left-3 top-3 border-l-2 border-t-2", "right-3 top-3 border-r-2 border-t-2", "left-3 bottom-3 border-l-2 border-b-2", "right-3 bottom-3 border-r-2 border-b-2"].map((c) => (
                  <span key={c} className={`absolute h-5 w-5 rounded-[3px] border-cinema-500/70 ${c}`} />
                ))}
                <div className="absolute inset-0 flex flex-col items-center justify-center gap-2">
                  <motion.span
                    className="flex h-14 w-14 items-center justify-center rounded-2xl bg-cinema-500/12 text-cinema-400 ring-1 ring-cinema-500/25"
                    animate={{ y: [0, -6, 0] }}
                    transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                  >
                    <Icon name="clapper" size={26} />
                  </motion.span>
                  <span className="text-[0.62rem] font-semibold uppercase tracking-[0.22em] text-text-dim">
                    Ready to roll
                  </span>
                  <span className="flex items-center gap-1.5 text-[0.62rem] font-medium text-cinema-400/80">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-danger" /> REC
                  </span>
                </div>
              </div>
            </div>
          </>
        )}
      </GlassCard>
      </TiltCard>

      {/* Bento stat tiles */}
      <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatTile
          icon="medal"
          value={snap.rank ? <CountUp value={snap.rank} prefix="#" /> : "—"}
          label="Rank"
          accent="#E8B647"
        />
        <StatTile
          icon="star"
          value={<CountUp value={snap.totalScore ?? 0} format={(n) => nf.format(n)} />}
          label="Total score"
          accent="#6FA373"
        />
        <StatTile icon="flame" value={<CountUp value={snap.streak ?? 0} />} label="Streak" accent="#E85D75" />
        <StatTile icon="refresh" value={<CountUp value={snap.regensLeft ?? 0} />} label="Regens left" accent="#3B82F6" />
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

      {/* Holiday mode — trips planned ahead with Aurora */}
      <Reveal className="mt-12">
      <GlassCard>
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Icon name="sun" size={18} className="text-cinema-400" />
            <h3 className="h-display text-display-sm font-semibold text-text-hi">Holiday mode</h3>
          </div>
          <button
            onClick={() => setPlanOpen(true)}
            className="inline-flex items-center gap-1.5 rounded-full bg-cinema-500/15 px-3 py-1.5 text-xs font-semibold text-cinema-300 transition-colors hover:bg-cinema-500/25"
          >
            <Icon name="plus" size={13} /> Plan a trip
          </button>
        </div>
        {upcomingTrips.length === 0 ? (
          <p className="py-2 text-sm text-text-dim">
            Going somewhere? Tell Aurora about a trip — she'll line up the prompt and a custom
            filming window for the day you leave. No Friday lock-in needed.
          </p>
        ) : (
          <ul className="space-y-2">
            {upcomingTrips.map((t) => {
              const d = daysUntil(t.startDate);
              return (
                <li
                  key={t.id}
                  className="flex items-center justify-between rounded-xl border border-hairline bg-chip px-4 py-3"
                >
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold text-text-hi">{t.title}</div>
                    <div className="text-xs text-text-dim">
                      {t.startDate} · {t.days} day{t.days === 1 ? "" : "s"}
                      {t.promptText ? " · prompt ready" : " · no prompt yet"}
                    </div>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <span className="rounded-full bg-cinema-500/15 px-2.5 py-1 text-xs font-semibold text-cinema-300">
                      {d <= 0 ? "today" : `in ${d}d`}
                    </span>
                    <button
                      onClick={() => removeTrip.mutate(t.id)}
                      aria-label={`Remove ${t.title}`}
                      className="text-text-dim transition-colors hover:text-danger"
                    >
                      <Icon name="plus" size={16} className="rotate-45" />
                    </button>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </GlassCard>
      </Reveal>

      {/* Videography box */}
      {showCategories && (
        <Reveal className="mt-14">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <div className="mb-2"><Eyebrow icon="aperture">Your map</Eyebrow></div>
              <h3 className="h-display text-display-md font-semibold text-text-hi">Your videography</h3>
            </div>
            <Link to="/settings" className="text-xs text-text-dim hover:text-text-hi">
              Hide in Settings
            </Link>
          </div>
          <CategoryBox history={history} />
        </Reveal>
      )}

      {/* Production stepper — connected nodes, a filling line + progress bar. */}
      <GlassCard className="mt-8">
        <div className="mb-4 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h3 className="h-display text-xl font-semibold text-text-hi">This week's steps</h3>
            <p className="text-xs text-text-dim">Tap a step to tick it off.</p>
          </div>
          <span className="rounded-full border border-hairline bg-chip px-3 py-1 text-xs font-semibold tabular-nums text-text-dim">
            {prog.done.length}/{WEEKLY_CYCLE.length} done
          </span>
        </div>

        {/* overall progress */}
        <div className="mb-7 h-1.5 w-full overflow-hidden rounded-full bg-chip">
          <motion.div
            className="h-full rounded-full bg-gradient-to-r from-cinema-400 to-cinema-600"
            initial={false}
            animate={{ width: `${(prog.done.length / WEEKLY_CYCLE.length) * 100}%` }}
            transition={{ type: "spring", stiffness: 120, damping: 20 }}
          />
        </div>

        <div className="no-scrollbar overflow-x-auto pb-1">
          <div className="flex min-w-[640px] items-start">
            {WEEKLY_CYCLE.map((p, i) => {
              const done = prog.done.includes(p.phase);
              const prevDone = i > 0 && prog.done.includes(WEEKLY_CYCLE[i - 1].phase);
              const today = holiday ? i === holidayPhaseIdx : isToday(p.day);
              const dayLabel = holiday ? `Day ${Math.floor((i * totalWindow) / WEEKLY_CYCLE.length) + 1}` : p.day;
              const last = i === WEEKLY_CYCLE.length - 1;
              return (
                <div key={p.phase + i} className="flex flex-1 flex-col items-center">
                  <div className="flex w-full items-center">
                    <span className={`h-0.5 flex-1 rounded-full transition-colors ${i === 0 ? "opacity-0" : prevDone ? "bg-cinema-500" : "bg-hairline-strong"}`} />
                    <button
                      type="button"
                      onClick={() => prog.toggle.mutate(p.phase)}
                      aria-pressed={done}
                      title={p.phase}
                      className={`relative flex h-9 w-9 shrink-0 items-center justify-center rounded-full border-2 transition-all duration-200 ${
                        done
                          ? "border-cinema-500 bg-cinema-500 text-[#16161a]"
                          : today
                            ? "border-cinema-500 text-cinema-400"
                            : "border-hairline-strong text-text-dim hover:border-cinema-500/60 hover:text-text-hi"
                      }`}
                    >
                      {today && !done && <span className="absolute inset-0 animate-ping rounded-full border border-cinema-500/50" />}
                      {done ? <Icon name="check" size={16} /> : <span className="text-xs font-bold tabular-nums">{i + 1}</span>}
                    </button>
                    <span className={`h-0.5 flex-1 rounded-full transition-colors ${last ? "opacity-0" : done ? "bg-cinema-500" : "bg-hairline-strong"}`} />
                  </div>
                  <button
                    type="button"
                    onClick={() => prog.toggle.mutate(p.phase)}
                    className="mt-2.5 flex flex-col items-center gap-0.5 px-1 text-center"
                  >
                    <span className={`text-[9px] font-semibold uppercase tracking-wide ${today && !done ? "text-cinema-400" : "text-text-dim"}`}>
                      {today ? "Today" : dayLabel}
                    </span>
                    <span className="text-[11px] font-semibold leading-tight text-text-hi">{p.phase}</span>
                  </button>
                </div>
              );
            })}
          </div>
        </div>

        {WEEKLY_CYCLE.every((p) => prog.done.includes(p.phase)) && (
          <Link to="/prompts" className="mt-6 block">
            <GradientButton className="w-full">
              <Icon name="check" size={16} /> All steps done — submit your film
            </GradientButton>
          </Link>
        )}
      </GlassCard>

      {/* History + Aurora */}
      <Reveal className="mt-14 grid gap-4 lg:grid-cols-3">
        <GlassCard className="lg:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="h-display text-display-sm font-semibold text-text-hi">Recent films</h3>
            <Link to="/profile" className="text-xs font-semibold text-cinema-400 hover:underline">
              View all
            </Link>
          </div>
          {history.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-10 text-center">
              <FilmDoodle name="reel" size={76} className="text-text-dim/30" />
              <p className="text-sm text-text-dim">No films yet — your first submission shows up here.</p>
            </div>
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
      </Reveal>

      <PlanTripModal open={planOpen} onClose={() => setPlanOpen(false)} />
    </PageTransition>
  );
}
