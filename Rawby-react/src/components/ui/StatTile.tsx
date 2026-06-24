import { Icon, type IconName } from "./Icon";
import { CountUp } from "./CountUp";

interface Props {
  icon: IconName;
  /** Static display value (used when `count` is not provided). */
  value?: React.ReactNode;
  /** When set, the number counts up from 0 on scroll-in. */
  count?: number;
  prefix?: string;
  format?: (n: number) => string;
  label: string;
  accent?: string;
}

/**
 * Premium metric tile — accent chip, prominent animated number, micro-label,
 * a faint top sheen and an accent glow that warms on hover. Static layout
 * (no entrance stagger) so it never freezes mid-animation.
 */
export function StatTile({ icon, value, count, prefix = "", format, label }: Props) {
  return (
    <div className="glass group relative flex flex-col gap-3 overflow-hidden p-4 transition-[transform,box-shadow,border-color] duration-300 ease-out hover:-translate-y-0.5 hover:border-cinema-500/40 hover:shadow-glow-sm">
      {/* accent glow — appears only on hover */}
      <span
        className="pointer-events-none absolute -right-6 -top-6 h-20 w-20 rounded-full opacity-0 blur-2xl transition-opacity duration-300 group-hover:opacity-70"
        style={{ background: "radial-gradient(circle, rgb(var(--c-500) / 0.5), transparent 70%)" }}
      />
      <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-chip text-text-dim ring-1 ring-inset ring-hairline transition-colors duration-300 group-hover:text-cinema-400">
        <Icon name={icon} size={18} />
      </div>
      <div className="h-display text-[2rem] font-bold leading-none text-text-hi tabular-nums">
        {count != null ? <CountUp value={count} prefix={prefix} format={format} /> : value}
      </div>
      <div className="text-[0.7rem] font-semibold uppercase tracking-[0.16em] text-text-dim">
        {label}
      </div>
    </div>
  );
}
