import { motion, type HTMLMotionProps } from "framer-motion";
import { forwardRef, type ReactNode } from "react";

type Props = Omit<HTMLMotionProps<"div">, "children"> & {
  /** Adds hover lift + pointer (transform/shadow only — no layout shift). */
  interactive?: boolean;
  children?: ReactNode;
};

export const GlassCard = forwardRef<HTMLDivElement, Props>(
  ({ className = "", interactive = false, children, ...rest }, ref) => (
    <motion.div
      ref={ref}
      className={`glass p-5 ${interactive ? "card-hover" : ""} ${className}`}
      {...rest}
    >
      {children}
    </motion.div>
  )
);
GlassCard.displayName = "GlassCard";
