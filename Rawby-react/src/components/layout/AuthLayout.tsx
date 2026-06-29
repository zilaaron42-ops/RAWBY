// Cinematic split layout for login/register. 3D reel hero on the left
// (desktop), glass form on the right. Shares the themed video background.
import { Suspense, lazy, useState, type ReactNode } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { HERO_LABELS } from "../three/heroLabels";
import { FilmGrain } from "../ui/FilmGrain";
import { ThemeBackground } from "../ui/ThemeBackground";
import { Logo } from "../ui/Logo";
import { Icon } from "../ui/Icon";

// 3D is heavy — defer it so the form paints immediately.
const AuthHero = lazy(() => import("../three/AuthHero"));

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
      <ThemeBackground />
      <FilmGrain opacity={0.05} />

      <div className="relative z-10 grid min-h-screen lg:grid-cols-2">
        {/* Hero / cycling 3D object */}
        <div className="relative hidden flex-col justify-between p-12 lg:flex">
          <Logo size="md" />

          {/* Backlight halo so the dark 3D object reads against black */}
          <div
            className="pointer-events-none absolute left-1/2 top-1/2 h-80 w-80 -translate-x-1/2 -translate-y-1/2 rounded-full blur-3xl"
            style={{ background: "radial-gradient(circle, rgb(var(--glow) / 0.22), transparent 70%)" }}
          />

          <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
            <Suspense fallback={null}>
              <AuthHero onChange={setHero} />
            </Suspense>
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

/** Password input with a show/hide toggle. */
export function PasswordField({
  label,
  ...props
}: { label: string } & Omit<React.InputHTMLAttributes<HTMLInputElement>, "type">) {
  const [show, setShow] = useState(false);
  return (
    <label className="mb-4 block">
      <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-text-dim">
        {label}
      </span>
      <div className="relative">
        <input
          {...props}
          type={show ? "text" : "password"}
          className="w-full rounded-xl border border-hairline bg-field px-4 py-3 pr-11 text-sm text-text-hi outline-none transition-colors placeholder:text-text-dim/60 focus:border-cinema-500/70 focus:ring-2 focus:ring-cinema-500/20"
        />
        <button
          type="button"
          onClick={() => setShow((s) => !s)}
          aria-label={show ? "Hide password" : "Show password"}
          aria-pressed={show}
          className="absolute right-2 top-1/2 flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-lg text-text-dim transition-colors hover:text-text-hi"
        >
          <Icon name={show ? "eyeOff" : "eye"} size={18} />
        </button>
      </div>
    </label>
  );
}
