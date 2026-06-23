import { motion } from "framer-motion";
import type { ReactNode } from "react";
import { Icon, type IconName } from "./Icon";

/** Small rounded eyebrow chip — the Framer-style label above a heading. */
export function Eyebrow({ icon, children }: { icon?: IconName; children: ReactNode }) {
  return (
    <span className="eyebrow-pill">
      {icon && <Icon name={icon} size={12} />}
      {children}
    </span>
  );
}

/** Reveal children on scroll into view (single wrapper — no list stagger). */
export function Reveal({
  children,
  className = "",
  delay = 0,
}: {
  children: ReactNode;
  className?: string;
  delay?: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1], delay }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

export function PageHeader({
  eyebrow,
  eyebrowIcon,
  title,
  sub,
  right,
}: {
  eyebrow?: string;
  eyebrowIcon?: IconName;
  title: string;
  sub?: string;
  right?: ReactNode;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
      className="mb-9 flex flex-wrap items-end justify-between gap-4"
    >
      <div>
        {eyebrow && (
          <div className="mb-3">
            <Eyebrow icon={eyebrowIcon}>{eyebrow}</Eyebrow>
          </div>
        )}
        <h1 className="h-display text-display-lg font-semibold text-text-hi md:text-display-xl">
          {title}
        </h1>
        {sub && <p className="measure mt-2.5 text-sm leading-relaxed text-text-dim">{sub}</p>}
      </div>
      {right}
    </motion.div>
  );
}

export function Spinner({ label }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-20 text-text-dim">
      <span
        className="h-8 w-8 animate-spin rounded-full border-2 border-hairline-strong border-t-cinema-500"
        aria-hidden="true"
      />
      {label && <span className="text-sm">{label}</span>}
    </div>
  );
}

export function ColdStartNote() {
  return (
    <p className="mt-4 text-center text-xs text-text-dim">
      Waking the server can take 30–60s on first load. Hang tight — we retry
      automatically.
    </p>
  );
}

export function EmptyState({
  icon,
  title,
  sub,
}: {
  icon?: IconName;
  title: string;
  sub?: string;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="glass flex flex-col items-center gap-3 py-16 text-center"
    >
      {icon && (
        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-chip text-text-dim">
          <Icon name={icon} size={24} />
        </div>
      )}
      <div className="font-semibold text-text-hi">{title}</div>
      {sub && <div className="measure text-sm text-text-dim">{sub}</div>}
    </motion.div>
  );
}
