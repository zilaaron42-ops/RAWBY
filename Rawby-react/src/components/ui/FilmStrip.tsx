// Film-strip ticker — a horizontally scrolling reel with sprocket-hole rails,
// edge fades and a hover-pause. On-brand cinematic "ticker".
const SPROCKET =
  "repeating-linear-gradient(90deg, transparent 0 10px, rgb(var(--bg)) 10px 18px, transparent 18px 28px)";

export function FilmStrip({ items }: { items: string[] }) {
  // Duplicated once so the -50% keyframe loops seamlessly.
  const reel = [...items, ...items];
  return (
    <div
      className="group relative overflow-hidden rounded-glass border border-hairline bg-ink-surface/60 backdrop-blur-xl"
      aria-hidden="true"
    >
      {/* sprocket rails */}
      <div className="h-2 w-full" style={{ background: SPROCKET, opacity: 0.6 }} />
      <div className="relative overflow-hidden py-2.5">
        <div className="flex w-max animate-marquee items-center gap-8 group-hover:[animation-play-state:paused]">
          {reel.map((label, i) => (
            <span key={i} className="flex items-center gap-8 whitespace-nowrap">
              <span className="text-[0.78rem] font-semibold uppercase tracking-[0.28em] text-text-dim">
                {label}
              </span>
              <span className="h-1 w-1 rounded-full bg-cinema-500/70" />
            </span>
          ))}
        </div>
        {/* edge fades */}
        <div className="pointer-events-none absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-ink-bg to-transparent" />
        <div className="pointer-events-none absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-ink-bg to-transparent" />
      </div>
      <div className="h-2 w-full" style={{ background: SPROCKET, opacity: 0.6 }} />
    </div>
  );
}
