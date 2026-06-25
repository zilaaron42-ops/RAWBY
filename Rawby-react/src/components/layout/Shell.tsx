// ============================================================
// RAWBY — app shell. Slim top bar (logo + profile / settings / admin)
// and a floating liquid-glass dock at the bottom for the 6 core
// destinations. Hosts the aurora background, grain, animated routes.
// ============================================================
import { NavLink, Outlet, useLocation } from "react-router-dom";
import { AnimatePresence } from "framer-motion";
import { FilmGrain } from "../ui/FilmGrain";
import { AuroraBackground } from "../ui/AuroraBackground";
import { Icon, type IconName } from "../ui/Icon";
import { Logo } from "../ui/Logo";
import { ModeToggle } from "../ui/ThemeControls";
import { Onboarding } from "../Onboarding";
import { Dock } from "./Dock";
import { NAV_ITEMS } from "./nav";
import { useAuth } from "../../store/auth";

function TopIcon({ to, icon, label }: { to: string; icon: IconName; label: string }) {
  return (
    <NavLink
      to={to}
      title={label}
      aria-label={label}
      className={({ isActive }) =>
        `flex h-9 w-9 items-center justify-center rounded-full border border-hairline transition-colors ${
          isActive ? "bg-glass-hover text-cinema-400" : "text-text-dim hover:bg-glass hover:text-text-hi"
        }`
      }
    >
      <Icon name={icon} size={18} />
    </NavLink>
  );
}

export function Shell() {
  const location = useLocation();
  const user = useAuth((s) => s.user);
  const initial = user?.displayName?.[0]?.toUpperCase() ?? "?";

  return (
    <div className="relative min-h-screen">
      <AuroraBackground />
      <FilmGrain />
      <Onboarding />

      {/* Slim top bar */}
      <header className="sticky top-0 z-nav flex items-center justify-between border-b border-hairline/60 bg-[rgb(var(--bg)/0.55)] px-4 py-3 backdrop-blur-xl md:px-8">
        <Logo size="md" />
        <div className="flex items-center gap-1.5">
          <ModeToggle />
          <TopIcon to="/settings" icon="settings" label="Settings" />
          {user?.isAdmin && <TopIcon to="/admin" icon="shield" label="Admin" />}
          {user && (
            <NavLink to="/profile" aria-label="Profile" title={user.displayName} className="ml-1">
              <span className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-cinema-300 to-cinema-600 text-sm font-bold text-[#16161a] ring-1 ring-cinema-300/30">
                {initial}
              </span>
            </NavLink>
          )}
        </div>
      </header>

      {/* Routed content */}
      <AnimatePresence mode="wait">
        <div key={location.pathname} className="relative z-base">
          <Outlet />
        </div>
      </AnimatePresence>

      {/* Floating liquid-glass dock — 6 core destinations */}
      <Dock items={NAV_ITEMS} />
    </div>
  );
}
