import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { StatTile } from "../components/ui/StatTile";
import { FilmTag } from "../components/ui/FilmTag";
import { PageHeader, EmptyState } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { stagger } from "../lib/motion";
import { useMe } from "../hooks/queries";
import { useFetchLikes } from "../hooks/useFetchLikes";
import { useAuth } from "../store/auth";
import type { ProjectHistoryItem } from "../types";

const nf = new Intl.NumberFormat("en-US");

function timeLabel(h: ProjectHistoryItem) {
  if (h.submittedAt) {
    const d = new Date(h.submittedAt);
    return d.toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
  }
  return h.date ?? `Week ${h.week ?? "—"}`;
}

export default function Profile() {
  const { data } = useMe();
  const user = useAuth((s) => s.user);
  const snap = data?.snapshot;
  const history: ProjectHistoryItem[] = data?.snapshot?.history ?? data?.history ?? [];
  const fetchLikes = useFetchLikes();

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

      <motion.div variants={stagger} initial="hidden" animate="show" className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
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
            <GlassCard key={h.id ?? i} className="flex flex-wrap items-center justify-between gap-3 py-3">
              <div className="min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-semibold text-text-hi">{h.title}</span>
                  {h.link && (
                    <a href={h.link} target="_blank" rel="noreferrer" className="text-text-dim hover:text-cinema-400" aria-label="Open link">
                      <Icon name="arrowRight" size={13} className="-rotate-45" />
                    </a>
                  )}
                </div>
                <div className="mt-0.5 flex flex-wrap items-center gap-x-3 gap-y-0.5 text-xs text-text-dim">
                  <span className="inline-flex items-center gap-1"><Icon name="clock" size={12} /> {timeLabel(h)}</span>
                  <span>{h.level}</span>
                  {h.likes != null && <span className="inline-flex items-center gap-1"><Icon name="flame" size={12} /> {nf.format(h.likes)} likes</span>}
                  {h.gear?.length ? <span>· {h.gear.length} gear</span> : null}
                </div>
              </div>
              <div className="flex items-center gap-3">
                {h.link && (
                  <button
                    onClick={() => fetchLikes.mutate(h)}
                    disabled={fetchLikes.isPending}
                    className="inline-flex items-center gap-1 rounded-lg border border-hairline bg-chip px-2.5 py-1.5 text-xs font-medium text-text-dim transition-colors hover:text-text-hi disabled:opacity-50"
                  >
                    <Icon name="refresh" size={13} /> Likes
                  </button>
                )}
                <span className="h-display text-lg font-bold text-cinema-400 tabular-nums">{nf.format(h.score ?? 0)}</span>
              </div>
            </GlassCard>
          ))}
        </div>
      )}
    </PageTransition>
  );
}
