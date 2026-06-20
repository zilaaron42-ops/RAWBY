import { useState } from "react";
import { motion } from "framer-motion";
import { PageTransition, stagger } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { FilmTag } from "../components/ui/FilmTag";
import { Icon } from "../components/ui/Icon";
import { PageHeader } from "../components/ui/Bits";
import { SubmitFilmModal } from "../components/SubmitFilmModal";
import { useMe } from "../hooks/queries";
import { LEVELS, LATE_MULTIPLIERS } from "../lib/constants";

export default function Prompts() {
  const { data } = useMe();
  const snap = data?.snapshot;
  const level = snap?.promptLevel ?? "Short Story";
  const text =
    snap?.promptText ??
    "Tell a story of someone leaving a place they love — in 60 seconds.";
  const [submitOpen, setSubmitOpen] = useState(false);

  return (
    <PageTransition>
      <SubmitFilmModal open={submitOpen} onClose={() => setSubmitOpen(false)} defaultLevel={level} />
      <PageHeader
        eyebrow="This week"
        title="Prompt"
        sub="Locked Friday. Film, edit, grade, then submit before next Friday."
      />

      {/* Active prompt */}
      <GlassCard className="relative overflow-hidden p-6 md:p-8">
        <div
          className="pointer-events-none absolute -left-12 -top-12 h-48 w-48 rounded-full blur-3xl"
          style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.22), transparent 70%)" }}
        />
        <div className="relative">
          <FilmTag level={level} />
          <h2 className="h-display mt-4 text-2xl font-bold leading-snug text-text-hi md:text-3xl">
            {text}
          </h2>
          <div className="mt-6 flex flex-wrap gap-3">
            <GradientButton onClick={() => setSubmitOpen(true)}>
              <Icon name="film" size={16} /> Submit film
            </GradientButton>
            <GradientButton variant="ghost">
              <Icon name="refresh" size={16} />
              Regenerate {snap?.regensLeft != null ? `(${snap.regensLeft} left)` : ""}
            </GradientButton>
          </div>
        </div>
      </GlassCard>

      {/* Levels */}
      <h3 className="h-display mb-3 mt-8 text-lg font-bold text-text-hi">Levels & scoring</h3>
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4"
      >
        {LEVELS.map((l) => (
          <motion.div key={l.name} variants={{ hidden: { opacity: 0, y: 12 }, show: { opacity: 1, y: 0 } }}>
            <GlassCard interactive className="h-full">
              <div
                className="mb-3 h-1.5 w-12 rounded-full"
                style={{ background: l.glow }}
              />
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
