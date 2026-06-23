import { motion, type HTMLMotionProps } from "framer-motion";
import type { ReactNode } from "react";

type Variant = "cinema" | "green" | "story" | "ghost";

const VARIANTS: Record<Variant, string> = {
  cinema: "bg-gradient-to-br from-cinema-400 to-cinema-600 text-[#1A1100] shadow-glow",
  green: "bg-gradient-to-br from-green-400 to-green-600 text-white shadow-[0_8px_30px_-8px_rgba(90,138,94,0.45)]",
  story: "bg-[linear-gradient(135deg,#E85D75,#B12B5C)] text-white shadow-[0_8px_30px_-8px_rgba(225,93,117,0.45)]",
  ghost: "bg-chip text-text-hi border border-hairline hover:bg-glass-hover",
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
