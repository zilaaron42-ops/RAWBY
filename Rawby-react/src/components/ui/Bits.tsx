import { motion } from "framer-motion";
import type { ReactNode } from "react";
import { Icon, type IconName } from "./Icon";

export function PageHeader({
  eyebrow,
  title,
  sub,
  right,
}: {
  eyebrow?: string;
  title: string;
  sub?: string;
  right?: ReactNode;
}) {
  return (
    <div className="mb-7 flex flex-wrap items-end justify-between gap-4">
      <div>
        {eyebrow && (
          <div className="mb-1.5 text-[0.7rem] font-semibold uppercase tracking-[0.22em] text-cinema-500">
            {eyebrow}
          </div>
        )}
        <h1 className="h-display text-[2rem] font-bold leading-tight text-text-hi md:text-[2.5rem]">
          {title}
        </h1>
        {sub && <p className="measure mt-2 text-sm leading-relaxed text-text-dim">{sub}</p>}
      </div>
      {right}
    </div>
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
