import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { PageHeader } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { SkeletonRow } from "../components/ui/Skeleton";
import { stagger, item } from "../lib/motion";
import { useLeaderboard } from "../hooks/queries";
import { useAuth } from "../store/auth";
import type { LeaderboardEntry } from "../types";

const DEMO: LeaderboardEntry[] = [
  { rank: 1, username: "nova", displayName: "Nova Reyes", totalScore: 1240, streak: 12 },
  { rank: 2, username: "kael", displayName: "Kael Adler", totalScore: 1110, streak: 9 },
  { rank: 3, username: "mira", displayName: "Mira Sol", totalScore: 980, streak: 7 },
  { rank: 4, username: "dax", displayName: "Dax Quinn", totalScore: 845, streak: 5 },
  { rank: 5, username: "isa", displayName: "Isa Vance", totalScore: 720, streak: 4 },
];

const medal = ["#E8B647", "#C7C7C7", "#CD7F32"];
const nf = new Intl.NumberFormat("en-US");

export default function Leaderboard() {
  const { data, isLoading } = useLeaderboard();
  const me = useAuth((s) => s.user);
  const rows = data && data.length ? data : DEMO;

  return (
    <PageTransition>
      <PageHeader
        eyebrow="Rankings"
        title="Leaderboard"
        sub="Points compound weekly. On-time submissions keep your multiplier at ×1.0."
      />

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <SkeletonRow key={i} />
          ))}
        </div>
      ) : (
        <motion.ul variants={stagger} initial="hidden" animate="show" className="space-y-2">
          {rows.map((r, i) => {
            const isMe = me?.username === r.username;
            return (
              <motion.li key={r.username} variants={item}>
                <GlassCard
                  interactive
                  className={`flex items-center gap-4 py-3 ${
                    isMe ? "border-cinema-500/50 bg-cinema-500/[0.06]" : ""
                  }`}
                >
                  <div
                    className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-sm font-bold tabular-nums"
                    style={{
                      background: i < 3 ? `${medal[i]}22` : "rgba(255,255,255,0.04)",
                      color: i < 3 ? medal[i] : "#9CA3AF",
                    }}
                  >
                    {r.rank}
                  </div>
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-green-400 to-green-600 text-sm font-bold text-white">
                    {r.displayName?.[0]?.toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-semibold text-text-hi">
                      {r.displayName}
                      {isMe && <span className="ml-1 text-cinema-400">· you</span>}
                    </div>
                    <div className="truncate text-xs text-text-dim">@{r.username}</div>
                  </div>
                  {r.streak != null && (
                    <div className="hidden items-center gap-1 text-xs text-text-dim sm:flex">
                      <Icon name="flame" size={14} className="text-[#E85D75]" />
                      {r.streak}
                    </div>
                  )}
                  <div className="h-display text-xl font-bold text-cinema-400 tabular-nums">
                    {nf.format(r.totalScore)}
                  </div>
                </GlassCard>
              </motion.li>
            );
          })}
        </motion.ul>
      )}
    </PageTransition>
  );
}
