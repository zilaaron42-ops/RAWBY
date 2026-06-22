// The "videography box" — four corner categories with an emotional heart
// at the centre. Shows how many films and avg likes sit in each. A film can
// belong to several categories, so counts overlap on purpose.
import { Icon, type IconName } from "./ui/Icon";
import { VIDEO_CATEGORIES } from "../lib/constants";
import type { ProjectHistoryItem } from "../types";

function statFor(history: ProjectHistoryItem[], id: string) {
  const items = history.filter((h) => h.categories?.includes(id));
  const liked = items.filter((h) => h.likes != null && h.likes > 0);
  const avg = liked.length
    ? Math.round(liked.reduce((s, h) => s + (h.likes ?? 0), 0) / liked.length)
    : null;
  return { count: items.length, avg };
}

const CORNER_ALIGN: Record<string, string> = {
  tl: "items-start text-left",
  tr: "items-end text-right",
  bl: "items-start text-left",
  br: "items-end text-right",
};

export function CategoryBox({ history }: { history: ProjectHistoryItem[] }) {
  const corners = VIDEO_CATEGORIES.filter((c) => c.corner !== "center");
  const heart = VIDEO_CATEGORIES.find((c) => c.corner === "center")!;
  const order = ["tl", "tr", "bl", "br"]; // grid order
  const hs = statFor(history, heart.id);

  return (
    <div className="relative">
      {/* connecting cross behind */}
      <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
        <div className="h-px w-full bg-hairline" />
      </div>
      <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
        <div className="h-full w-px bg-hairline" />
      </div>

      <div className="grid grid-cols-2 gap-3">
        {order.map((pos) => {
          const c = corners.find((x) => x.corner === pos)!;
          const s = statFor(history, c.id);
          return (
            <div
              key={c.id}
              className={`glass flex min-h-[120px] flex-col justify-between p-4 ${CORNER_ALIGN[pos]}`}
            >
              <div className={`flex w-full items-center gap-2 ${pos === "tr" || pos === "br" ? "flex-row-reverse" : ""}`}>
                <span
                  className="flex h-8 w-8 items-center justify-center rounded-lg"
                  style={{ background: `${c.color}22`, color: c.color }}
                >
                  <Icon name={c.icon as IconName} size={16} />
                </span>
                <span className="text-sm font-semibold text-text-hi">{c.label}</span>
              </div>
              <div>
                <div className="text-[11px] leading-tight text-text-dim">{c.blurb}</div>
                <div className="mt-1.5 flex items-center gap-2 text-xs">
                  <span className="h-display text-lg font-bold tabular-nums" style={{ color: c.color }}>
                    {s.count}
                  </span>
                  <span className="text-text-dim">films</span>
                  {s.avg != null && (
                    <span className="text-text-dim">· {s.avg} avg likes</span>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Emotional heart at the centre */}
      <div className="pointer-events-none absolute left-1/2 top-1/2 flex h-28 w-28 -translate-x-1/2 -translate-y-1/2 flex-col items-center justify-center rounded-full text-center shadow-glow"
        style={{
          background: "radial-gradient(circle at 50% 35%, rgba(232,93,117,0.95), rgba(177,43,92,0.95))",
          border: "1px solid rgba(255,255,255,0.15)",
        }}
      >
        <Icon name="heart" size={20} className="text-white" />
        <div className="mt-0.5 text-[11px] font-bold uppercase tracking-wider text-white">Emotions</div>
        <div className="text-[11px] text-white/85">
          {hs.count} {hs.count === 1 ? "film" : "films"}
          {hs.avg != null ? ` · ${hs.avg}♡` : ""}
        </div>
      </div>
    </div>
  );
}
