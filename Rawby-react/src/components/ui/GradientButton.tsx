import { motion, type HTMLMotionProps } from "framer-motion";
import type { ReactNode } from "react";

type Variant = "cinema" | "green" | "story" | "ghost";

// Disciplined set: gold is the only bright primary. Everything else is a
// deep, desaturated, filmic tone or a quiet charcoal — no candy gradients.
const VARIANTS: Record<Variant, string> = {
  cinema: "bg-gradient-to-b from-cinema-300 to-cinema-500 text-[#1a1200] shadow-glow",
  green: "bg-[linear-gradient(180deg,#5E8E62,#33543A)] text-white shadow-[0_10px_30px_-12px_rgba(90,138,94,0.5)]",
  story: "bg-[linear-gradient(180deg,#A8506B,#5E1E3E)] text-white shadow-[0_10px_30px_-12px_rgba(150,50,90,0.5)]",
  ghost: "border border-hairline bg-[rgb(var(--card-fill))] text-text-hi hover:border-hairline-strong hover:bg-glass-hover",
};

type Props = Omit<HTMLMotionProps<"button">, "children"> & {
  variant?: Variant;
  loading?: boolean;
  children?: ReactNode;
};

export function GradientButton({
  variant = "cinema",
  loading = false,
  className = "",
  children,
  disabled,
  ...rest
}: Props) {
  return (
    <motion.button
      whileTap={{ scale: 0.97 }}
      transition={{ type: "spring", stiffness: 400, damping: 22 }}
      disabled={disabled || loading}
      aria-busy={loading}
      className={`inline-flex items-center justify-center gap-2 rounded-full px-6 py-3 text-sm font-semibold tracking-wide transition-[filter,background-color,transform] duration-200 ease-out hover:-translate-y-0.5 hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:translate-y-0 disabled:hover:brightness-100 ${variant !== "ghost" ? "sheen" : ""} ${VARIANTS[variant]} ${className}`}
      {...rest}
    >
      {loading && (
        <span
          className="h-4 w-4 shrink-0 animate-spin rounded-full border-2 border-current border-r-transparent opacity-70"
          aria-hidden="true"
        />
      )}
      {children}
    </motion.button>
  );
}
