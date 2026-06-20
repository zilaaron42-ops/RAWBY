import { motion } from "framer-motion";
import type { ReactNode } from "react";
import { pageVariants } from "../../lib/motion";

// Cinematic page transition: fade + slide with spring overshoot.
export function PageTransition({ children }: { children: ReactNode }) {
  return (
    <motion.main
      variants={pageVariants}
      initial="hidden"
      animate="show"
      exit="exit"
      className="mx-auto w-full max-w-6xl px-4 pb-28 pt-6 md:px-8 md:pb-12 md:pt-8"
    >
      {children}
    </motion.main>
  );
}

// Convenience re-exports so pages can pull stagger tokens from one place.
export { stagger, item } from "../../lib/motion";
