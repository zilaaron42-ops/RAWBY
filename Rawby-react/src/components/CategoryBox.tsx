// The "videography map" — four corner lanes around an emotional core. Shows
// how many films and avg likes sit in each. A film can belong to several
// lanes, so counts overlap on purpose.
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
  const order = ["tl", "tr", "bl", "br"];
  const hs = statFor(history, heart.id);

  return (
    <div className="relative">
      {/* connecting cross — gradient hairlines that fade toward the core */}
      <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
        <div
          className="h-px w-[92%]"
          style={{ background: "linear-gradient(90deg, transparent, rgb(var(--hairline-strong)) 50%, transparent)" }}
        />
      </div>
      <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
        <div
          className="h-[92%] w-px"
          style={{ background: "linear-gradient(180deg, transparent, rgb(var(--hairline-strong)) 50%, transparent)" }}
        />
      </div>

      <div className="grid grid-cols-2 gap-4 md:gap-5">
        {order.map((pos) => {
          const c = corners.find((x) => x.corner === pos)!;
          const s = statFor(history, c.id);
          const flip = pos === "tr" || pos === "br";
          return (
            <div
              key={c.id}
              className={`glass group relative flex min-h-[156px] flex-col justify-between overflow-hidden p-5 transition-[transform,box-shadow] duration-300 hover:-translate-y-0.5 hover:shadow-glow-sm ${CORNER_ALIGN[pos]}`}
            >
              <span
                className="pointer-events-none absolute h-24 w-24 rounded-full opacity-0 blur-2xl transition-opacity duration-300 group-hover:opacity-70"
                style={{
                  background: "radial-gradient(circle, rgb(var(--c-500) / 0.45), transparent 70%)",
                  [pos.includes("t") ? "top" : "bottom"]: "-1.5rem",
                  [pos.includes("l") ? "left" : "right"]: "-1.5rem",
                }}
              />
              <div className={`flex w-full items-center gap-2.5 ${flip ? "flex-row-reverse" : ""}`}>
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-chip text-text-dim ring-1 ring-inset ring-hairline transition-colors duration-300 group-hover:text-cinema-400">
                  <Icon name={c.icon as IconName} size={17} />
                </span>
                <span className="text-[0.95rem] font-semibold text-text-hi">{c.label}</span>
              </div>
              <div>
                <div className="text-[11px] leading-snug text-text-dim">{c.blurb}</div>
                <div className={`mt-2 flex items-baseline gap-1.5 ${flip ? "justify-end" : ""}`}>
                  <span className="h-display text-xl font-bold tabular-nums text-text-hi">{s.count}</span>
                  <span className="text-[11px] text-text-dim">{s.count === 1 ? "film" : "films"}</span>
                  {s.avg != null && <span className="text-[11px] text-text-dim">· {s.avg}♡</span>}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Emotional core — a calm dark medallion with a rose accent, not a ball */}
      <div
        className="pointer-events-none absolute left-1/2 top-1/2 flex h-[6.5rem] w-[6.5rem] -translate-x-1/2 -translate-y-1/2 flex-col items-center justify-center rounded-full border border-cinema-500/40 text-center"
        style={{
          background: "rgb(var(--surface))",
          boxShadow: "0 0 0 6px rgb(var(--bg)), 0 0 28px -6px rgb(var(--c-500) / 0.5)",
        }}
      >
        <span className="flex h-8 w-8 items-center justify-center rounded-full bg-cinema-500/15 text-cinema-400">
          <Icon name="heart" size={16} />
        </span>
        <div className="mt-1 text-[0.6rem] font-semibold uppercase tracking-[0.16em] text-text-hi">Emotions</div>
        <div className="text-[10px] text-text-dim">
          {hs.count} {hs.count === 1 ? "film" : "films"}
          {hs.avg != null ? ` · ${hs.avg}♡` : ""}
        </div>
      </div>
    </div>
  );
}
