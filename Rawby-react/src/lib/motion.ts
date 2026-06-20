// ============================================================
// RAWBY — motion tokens. ease-out for entering, ease-in for
// exiting (per UX guidance). One spring for tactile controls.
// ============================================================
import type { Transition, Variants } from "framer-motion";

export const EASE_OUT: [number, number, number, number] = [0.22, 1, 0.36, 1];
export const EASE_IN: [number, number, number, number] = [0.4, 0, 1, 1];
export const EASE_CINEMA: [number, number, number, number] = [0.34, 1.32, 0.64, 1];

export const spring: Transition = { type: "spring", stiffness: 320, damping: 26 };

export const DUR = { micro: 0.18, base: 0.28, slow: 0.45 } as const;

/** Page-level enter/exit. */
export const pageVariants: Variants = {
  hidden: { opacity: 0, y: 14 },
  show: { opacity: 1, y: 0, transition: { duration: DUR.slow, ease: EASE_CINEMA } },
  exit: { opacity: 0, y: -8, transition: { duration: DUR.base, ease: EASE_IN } },
};

/** Stagger container for lists/grids. */
export const stagger: Variants = {
  hidden: {},
  show: { transition: { staggerChildren: 0.05, delayChildren: 0.04 } },
};

/** Child item used inside `stagger`. */
export const item: Variants = {
  hidden: { opacity: 0, y: 12 },
  show: { opacity: 1, y: 0, transition: { duration: DUR.base, ease: EASE_OUT } },
};
