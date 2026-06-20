// Cinematic split layout for login/register. 3D reel hero on the left
// (desktop), glass form on the right. Shares the AuraScene background.
import { Suspense, lazy, useState, type ReactNode } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { HERO_LABELS } from "../three/heroLabels";
import { FilmGrain } from "../ui/FilmGrain";
import { Logo } from "../ui/Logo";

// 3D is heavy — defer it so the form paints immediately.
const AuraScene = lazy(() =>
  import("../three/AuraScene").then((m) => ({ default: m.AuraScene }))
);
const AuthHero = lazy(() => import("../three/AuthHero"));

const reduced =
  typeof window !== "undefined" &&
  window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

export function AuthLayout({
  title,
  tagline,
  children,
}: {
  title: string;
  tagline: string;
  children: ReactNode;
}) {
  const [hero, setHero] = useState("camera");

  return (
    <div className="relative min-h-screen overflow-hidden">
      <Suspense fallback={null}>
        <AuraScene />
      </Suspense>
      <FilmGrain opacity={0.05} />

      <div className="relative z-10 grid min-h-screen lg:grid-cols-2">
        {/* Hero / cycling 3D object */}
        <div className="relative hidden flex-col justify-between p-12 lg:flex">
          <Logo size="md" />

          <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
            {!reduced && (
              <Suspense fallback={null}>
                <AuthHero onChange={setHero} />
              </Suspense>
            )}
          </div>

          <div className="relative max-w-sm">
            <div className="mb-3 h-5 overflow-hidden">
              <AnimatePresence mode="wait">
                <motion.span
                  key={hero}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -8 }}
                  transition={{ duration: 0.4 }}
                  className="text-xs font-semibold uppercase tracking-[0.25em] text-cinema-500"
                >
                  {HERO_LABELS[hero]}
                </motion.span>
              </AnimatePresence>
            </div>
            <h2 className="h-display text-4xl font-bold leading-tight text-text-hi">
              One film. <span className="text-cinema-400">Every week.</span>
            </h2>
            <p className="mt-3 text-sm text-text-dim">
              The weekly filmmaking challenge for solo videographers. Get a
              prompt, shoot, edit, grade, publish — then climb the ranks.
            </p>
          </div>
        </div>

        {/* Form */}
        <div className="flex items-center justify-center p-6 md:p-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: [0.34, 1.32, 0.64, 1] }}
            className="glass w-full max-w-md p-8"
          >
            <h1 className="h-display text-3xl font-bold text-text-hi">{title}</h1>
            <p className="mb-6 mt-1 text-sm text-text-dim">{tagline}</p>
            {children}
          </motion.div>
        </div>
      </div>
    </div>
  );
}

/** Shared field input. */
export function Field({
  label,
  ...props
}: { label: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="mb-4 block">
      <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-text-dim">
        {label}
      </span>
      <input
        {...props}
        className="w-full rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none transition-colors placeholder:text-text-dim/60 focus:border-cinema-500/70 focus:ring-2 focus:ring-cinema-500/20"
      />
    </label>
  );
}
