import { useState } from "react";
import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { FilmTag } from "../components/ui/FilmTag";
import { Icon } from "../components/ui/Icon";
import { PageHeader, Spinner } from "../components/ui/Bits";
import { SubmitFilmModal } from "../components/SubmitFilmModal";
import { useMe } from "../hooks/queries";
import { useGeneratePrompts } from "../hooks/usePrompts";
import { useSettings } from "../store/settings";
import { stagger, item } from "../lib/motion";
import { LEVELS, LATE_MULTIPLIERS } from "../lib/constants";
import type { GeneratedPrompt } from "../types";

function PromptCard({ p, onFilm }: { p: GeneratedPrompt; onFilm: (level: string) => void }) {
  const [open, setOpen] = useState(false);
  return (
    <motion.div variants={item}>
      <GlassCard className="h-full">
        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <FilmTag level={p.level} />
          {p.emotion && (
            <span className="text-[11px] uppercase tracking-wider text-text-dim">{p.emotion}</span>
          )}
        </div>
        <p className="text-sm leading-relaxed text-text-hi">{p.text}</p>

        {(p.shots?.length || p.songs?.length) && (
          <button
            onClick={() => setOpen((o) => !o)}
            className="mt-3 inline-flex items-center gap-1 text-xs font-semibold text-cinema-400 hover:underline"
          >
            {open ? "Hide" : "Shot & song ideas"}
            <Icon name="arrowRight" size={13} className={open ? "-rotate-90" : "rotate-90"} />
          </button>
        )}

        {open && (
          <div className="mt-3 space-y-3">
            {p.shots?.length ? (
              <div>
                <div className="mb-1 text-[10px] font-semibold uppercase tracking-wider text-text-dim">Shots</div>
                <ul className="space-y-1.5">
                  {p.shots.map((s, i) => (
                    <li key={i} className="flex gap-2 text-xs leading-relaxed text-text-dim">
                      <span className="mt-1 h-1 w-1 shrink-0 rounded-full bg-cinema-500" />
                      {s}
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
            {p.songs?.length ? (
              <div>
                <div className="mb-1 text-[10px] font-semibold uppercase tracking-wider text-text-dim">Songs</div>
                <ul className="space-y-1">
                  {p.songs.map((s, i) => (
                    <li key={i} className="flex items-center gap-2 text-xs text-text-dim">
                      <Icon name="volume" size={12} className="shrink-0 text-cinema-500" />
                      <span className="text-text-hi">{s.title}</span> · {s.artist}
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
          </div>
        )}

        <GradientButton onClick={() => onFilm(p.level)} className="mt-4 w-full">
          <Icon name="film" size={15} /> Film this
        </GradientButton>
      </GlassCard>
    </motion.div>
  );
}

export default function Prompts() {
  const { data } = useMe();
  const snap = data?.snapshot;
  const region = useSettings((s) => s.region);
  const seasonalPrompts = useSettings((s) => s.seasonalPrompts);
  const gen = useGeneratePrompts();
  const prompts = gen.data ?? [];

  const [submitOpen, setSubmitOpen] = useState(false);
  const [submitLevel, setSubmitLevel] = useState("Short Story");

  function film(level: string) {
    setSubmitLevel(level);
    setSubmitOpen(true);
  }

  return (
    <PageTransition>
      <SubmitFilmModal open={submitOpen} onClose={() => setSubmitOpen(false)} defaultLevel={submitLevel} />

      <PageHeader
        eyebrow="This week"
        title="Prompts"
        sub="Generate your weekly set, then film whichever level you want."
        right={
          <div className="flex flex-wrap items-center gap-2 text-xs text-text-dim">
            <span className="inline-flex items-center gap-1 rounded-full bg-chip px-3 py-1">
              <Icon name="aperture" size={13} /> {region}
            </span>
            {seasonalPrompts && (
              <span className="inline-flex items-center gap-1 rounded-full bg-chip px-3 py-1">
                <Icon name="sun" size={13} /> Seasonal
              </span>
            )}
          </div>
        }
      />

      {/* Generate / Big Project actions */}
      <GlassCard className="relative mb-6 overflow-hidden p-6">
        <div
          className="pointer-events-none absolute -left-12 -top-12 h-48 w-48 rounded-full blur-3xl"
          style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.22), transparent 70%)" }}
        />
        <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="h-display text-xl font-bold text-text-hi">This week's prompts</h2>
            <p className="text-sm text-text-dim">
              Three levels, tuned to {region === "Global" ? "anywhere" : region}
              {seasonalPrompts ? " and the season" : ""}. No need to pick — film any.
            </p>
          </div>
          <div className="flex flex-wrap gap-3">
            <GradientButton onClick={() => gen.mutate()} loading={gen.isPending}>
              <Icon name="sparkles" size={16} /> {prompts.length ? "Regenerate" : "Generate"}
            </GradientButton>
            <GradientButton variant="story" onClick={() => film("Big Project")}>
              <Icon name="film" size={16} /> Start Big Project
            </GradientButton>
          </div>
        </div>
      </GlassCard>

      {/* Generated prompts (no forced choice) */}
      {gen.isPending ? (
        <Spinner label="Writing your weekly prompts…" />
      ) : prompts.length ? (
        <motion.div
          variants={stagger}
          initial="hidden"
          animate="show"
          className="grid gap-4 lg:grid-cols-3"
        >
          {prompts.map((p, i) => (
            <PromptCard key={i} p={p} onFilm={film} />
          ))}
        </motion.div>
      ) : (
        <GlassCard className="text-center">
          <p className="text-sm text-text-dim">
            {snap?.promptText
              ? snap.promptText
              : "Hit Generate to get this week's three prompts — set your country & season in Settings for tuned results."}
          </p>
        </GlassCard>
      )}

      {/* Levels & scoring */}
      <h3 className="h-display mb-3 mt-8 text-lg font-bold text-text-hi">Levels & scoring</h3>
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4"
      >
        {LEVELS.map((l) => (
          <motion.div key={l.name} variants={item}>
            <GlassCard interactive className="h-full">
              <div className="mb-3 h-1.5 w-12 rounded-full" style={{ background: l.glow }} />
              <div className="text-sm font-semibold text-text-hi">{l.name}</div>
              <div className="h-display mt-1 text-3xl font-bold" style={{ color: l.glow }}>
                {l.points}
              </div>
              <div className="text-xs text-text-dim">points</div>
            </GlassCard>
          </motion.div>
        ))}
      </motion.div>

      {/* Late penalty */}
      <h3 className="h-display mb-3 mt-8 text-lg font-bold text-text-hi">Late penalty</h3>
      <GlassCard>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {LATE_MULTIPLIERS.map((p) => (
            <div key={p.day} className="rounded-xl border border-hairline bg-chip p-3 text-center">
              <div className="text-xs uppercase tracking-wider text-text-dim">{p.day}</div>
              <div
                className="h-display mt-1 text-2xl font-bold"
                style={{ color: p.mult === 1 ? "#22C55E" : p.mult >= 0.75 ? "#FBBF24" : "#EF4444" }}
              >
                ×{p.mult}
              </div>
            </div>
          ))}
        </div>
      </GlassCard>
    </PageTransition>
  );
}
