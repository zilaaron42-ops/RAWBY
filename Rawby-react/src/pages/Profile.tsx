import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { StatTile } from "../components/ui/StatTile";
import { FilmTag } from "../components/ui/FilmTag";
import { PageHeader, EmptyState } from "../components/ui/Bits";
import { stagger } from "../lib/motion";
import { useMe } from "../hooks/queries";
import { useAuth } from "../store/auth";

const nf = new Intl.NumberFormat("en-US");

export default function Profile() {
  const { data } = useMe();
  const user = useAuth((s) => s.user);
  const snap = data?.snapshot;
  const history = data?.snapshot?.history ?? data?.history ?? [];

  return (
    <PageTransition>
      <PageHeader eyebrow="You" title="Profile" />

      <GlassCard className="flex flex-col items-center gap-4 text-center md:flex-row md:text-left">
        <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-green-400 to-green-600 text-3xl font-bold text-white shadow-[0_8px_30px_-8px_rgba(90,138,94,0.45)]">
          {user?.displayName?.[0]?.toUpperCase() ?? "?"}
        </div>
        <div>
          <h2 className="h-display text-2xl font-bold text-text-hi">{user?.displayName}</h2>
          <p className="text-sm text-text-dim">@{user?.username}</p>
          {snap?.promptLevel && (
            <div className="mt-2">
              <FilmTag level={snap.promptLevel} />
            </div>
          )}
        </div>
      </GlassCard>

      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4"
      >
        <StatTile icon="medal" value={`#${snap?.rank ?? "—"}`} label="Rank" />
        <StatTile icon="star" value={nf.format(snap?.totalScore ?? 0)} label="Total score" accent="#6FA373" />
        <StatTile icon="flame" value={snap?.streak ?? 0} label="Streak" accent="#E85D75" />
        <StatTile icon="film" value={history.length} label="Films" accent="#3B82F6" />
      </motion.div>

      <h3 className="h-display mb-3 mt-8 text-lg font-bold text-text-hi">Film history</h3>
      {history.length === 0 ? (
        <EmptyState icon="film" title="No films yet" sub="Submit your first weekly film to start your reel." />
      ) : (
        <div className="space-y-2">
          {history.map((h, i) => (
            <GlassCard key={h.id ?? i} className="flex items-center justify-between py-3">
              <div>
                <div className="text-sm font-semibold text-text-hi">{h.title}</div>
                <div className="text-xs text-text-dim">
                  {h.level} · {h.date ?? `Week ${h.week ?? "—"}`}
                </div>
              </div>
              <span className="h-display text-lg font-bold text-cinema-400 tabular-nums">
                {h.score ?? 0}
              </span>
            </GlassCard>
          ))}
        </div>
      )}
    </PageTransition>
  );
}
