import { motion, type HTMLMotionProps } from "framer-motion";
import type { ReactNode } from "react";

type Variant = "cinema" | "green" | "story" | "ghost";

// Monochrome at rest, accent fills in on hover / press. No gradients, no glow.
// primary (cinema) = neutral outline → fills the accent. ghost = quieter.
const FILL = "hover:border-cinema-500 hover:bg-cinema-500 hover:text-[#16161a] active:border-cinema-500 active:bg-cinema-500 active:text-[#16161a]";
const VARIANTS: Record<Variant, string> = {
  cinema: `border border-text-hi/25 text-text-hi ${FILL}`,
  green: `border border-text-hi/25 text-text-hi ${FILL}`,
  story: `border border-text-hi/25 text-text-hi ${FILL}`,
  ghost: "border border-hairline text-text-dim hover:border-hairline-strong hover:bg-glass-hover hover:text-text-hi",
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
      className={`inline-flex items-center justify-center gap-2 rounded-full px-6 py-2.5 text-sm font-semibold tracking-wide transition-colors duration-200 ease-out disabled:cursor-not-allowed disabled:opacity-50 ${VARIANTS[variant]} ${className}`}
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
