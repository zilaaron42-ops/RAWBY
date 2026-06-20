// ============================================================
// RAWBY logo — a solid block with the wordmark carved (engraved)
// into it, bold. Colour is driven by the --brand-* CSS variables
// (default cinema amber / gold) so a theme change repaints it.
// ============================================================
type Size = "sm" | "md" | "lg";

const SIZES: Record<Size, { pad: string; text: string; radius: string }> = {
  sm: { pad: "px-2.5 py-1", text: "text-base", radius: "rounded-lg" },
  md: { pad: "px-3.5 py-1.5", text: "text-2xl", radius: "rounded-xl" },
  lg: { pad: "px-5 py-2.5", text: "text-4xl", radius: "rounded-2xl" },
};

// Engraved text: dark fill + lower-edge highlight = pressed inward.
const CARVED_TEXT: React.CSSProperties = {
  color: "var(--brand-ink)",
  textShadow: "0 1px 0 rgba(255,255,255,0.35), 0 -1px 1px rgba(0,0,0,0.45)",
};

const BLOCK: React.CSSProperties = {
  background:
    "linear-gradient(155deg, var(--brand-1) 0%, var(--brand-2) 45%, var(--brand-3) 100%)",
  boxShadow:
    "inset 0 2px 5px rgba(0,0,0,0.45), inset 0 -2px 4px rgba(255,255,255,0.3), 0 6px 18px rgba(0,0,0,0.45)",
  border: "1px solid rgba(0,0,0,0.28)",
};

export function Logo({ size = "md", className = "" }: { size?: Size; className?: string }) {
  const s = SIZES[size];
  return (
    <div
      className={`inline-flex select-none items-center ${s.pad} ${s.radius} ${className}`}
      style={BLOCK}
      aria-label="RAWBY"
    >
      <span className={`h-display font-extrabold tracking-[0.12em] ${s.text}`} style={CARVED_TEXT}>
        RAWBY
      </span>
    </div>
  );
}

/** Compact square block with just an engraved “R”. */
export function LogoMark({ className = "" }: { className?: string }) {
  return (
    <div
      className={`flex h-9 w-9 select-none items-center justify-center rounded-lg ${className}`}
      style={BLOCK}
      aria-label="RAWBY"
    >
      <span className="h-display text-xl font-extrabold" style={CARVED_TEXT}>
        R
      </span>
    </div>
  );
}
