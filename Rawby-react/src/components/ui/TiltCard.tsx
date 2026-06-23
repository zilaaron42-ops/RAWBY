// 3D tilt — the card leans toward the cursor with a soft spring, plus a
// moving sheen highlight. Pure transform/opacity, disabled for touch +
// reduced-motion. Framer "3D transforms" translated to the web.
import { useRef, type ReactNode } from "react";
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";

const prefersReduced =
  typeof window !== "undefined" &&
  window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

export function TiltCard({
  children,
  className = "",
  max = 7,
}: {
  children: ReactNode;
  className?: string;
  max?: number; // max tilt in degrees
}) {
  const ref = useRef<HTMLDivElement>(null);
  const px = useMotionValue(0.5);
  const py = useMotionValue(0.5);
  const sx = useSpring(px, { stiffness: 180, damping: 18 });
  const sy = useSpring(py, { stiffness: 180, damping: 18 });

  const rotateY = useTransform(sx, [0, 1], [-max, max]);
  const rotateX = useTransform(sy, [0, 1], [max, -max]);
  const glareX = useTransform(sx, [0, 1], ["0%", "100%"]);

  function onMove(e: React.MouseEvent) {
    const el = ref.current;
    if (!el || prefersReduced) return;
    const r = el.getBoundingClientRect();
    px.set((e.clientX - r.left) / r.width);
    py.set((e.clientY - r.top) / r.height);
  }
  function reset() {
    px.set(0.5);
    py.set(0.5);
  }

  if (prefersReduced) return <div className={className}>{children}</div>;

  return (
    <motion.div
      ref={ref}
      onMouseMove={onMove}
      onMouseLeave={reset}
      style={{ rotateX, rotateY, transformPerspective: 1200, transformStyle: "preserve-3d" }}
      className={`relative ${className}`}
    >
      {children}
      {/* moving sheen highlight that follows the cursor */}
      <motion.div
        aria-hidden
        className="pointer-events-none absolute inset-0 rounded-glass"
        style={{
          background: useTransform(
            glareX,
            (x) => `radial-gradient(45% 65% at ${x} -10%, rgb(var(--c-400) / 0.12), transparent 70%)`
          ),
        }}
      />
    </motion.div>
  );
}
