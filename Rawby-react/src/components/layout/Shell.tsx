// ============================================================
// RAWBY — app shell. Side-nav on desktop (>=768px), bottom-nav on
// mobile + a slim mobile top bar. Hosts the 3D AuraScene, grain,
// and animated routes.
// ============================================================
import { Suspense, lazy } from "react";
import { NavLink, Outlet, useLocation } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { FilmGrain } from "../ui/FilmGrain";
import { Icon } from "../ui/Icon";
import { Logo } from "../ui/Logo";
import { ModeToggle } from "../ui/ThemeControls";
import { Onboarding } from "../Onboarding";
import { NAV_ITEMS, SECONDARY_ITEMS, ADMIN_ITEM, type NavItem } from "./nav";
import { useAuth } from "../../store/auth";

// 3D background is heavy — defer so the dashboard paints first.
const AuraScene = lazy(() =>
  import("../three/AuraScene").then((m) => ({ default: m.AuraScene }))
);


function SideLink({ item }: { item: NavItem }) {
  return (
    <NavLink
      to={item.to}
      end={item.to === "/"}
      className={({ isActive }) =>
        `group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors duration-200 ${
          isActive
            ? "bg-glass-hover text-text-hi"
            : "text-text-dim hover:bg-glass hover:text-text-hi"
        }`
      }
    >
      {({ isActive }) => (
        <>
          {isActive && (
            <motion.span
              layoutId="nav-active"
              className="absolute left-0 top-1/2 h-6 w-1 -translate-y-1/2 rounded-r-full bg-cinema-500"
              transition={{ type: "spring", stiffness: 400, damping: 32 }}
            />
          )}
          <Icon name={item.icon} size={20} />
          {item.label}
        </>
      )}
    </NavLink>
  );
}

export function Shell() {
  const location = useLocation();
  const user = useAuth((s) => s.user);
  const navItems: NavItem[] = [
    ...NAV_ITEMS,
    ...SECONDARY_ITEMS,
    ...(user?.isAdmin ? [ADMIN_ITEM] : []),
  ];

  return (
    <div className="relative min-h-screen">
      <div className="ambient-aurora" aria-hidden="true" />
      <Suspense fallback={null}>
        <AuraScene />
      </Suspense>
      <FilmGrain />
      <Onboarding />

      <div className="relative z-base flex min-h-screen">
        {/* Desktop side-nav */}
        <aside className="sticky top-0 hidden h-screen w-60 shrink-0 flex-col gap-6 border-r border-hairline bg-ink-surface/80 px-3 py-6 backdrop-blur-xl md:flex">
          <div className="flex items-center justify-between px-2">
            <Logo size="md" />
            <ModeToggle />
          </div>
          <nav aria-label="Primary" className="flex flex-1 flex-col gap-1">
            {navItems.map((it) => (
              <SideLink key={it.to} item={it} />
            ))}
          </nav>
          {user && (
            <div className="glass flex items-center gap-3 p-3">
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-green-400 to-green-600 text-sm font-bold text-white">
                {user.displayName?.[0]?.toUpperCase() ?? "?"}
              </div>
              <div className="min-w-0">
                <div className="truncate text-sm font-semibold text-text-hi">
                  {user.displayName}
                </div>
                <div className="truncate text-xs text-text-dim">@{user.username}</div>
              </div>
            </div>
          )}
        </aside>

        <div className="flex-1">
          {/* Mobile top bar */}
          <div className="sticky top-0 z-nav flex items-center justify-between border-b border-hairline bg-ink-surface/80 px-4 py-3 backdrop-blur-xl md:hidden">
            <Logo size="sm" />
            <div className="flex items-center gap-2">
              <ModeToggle />
              {user && (
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-green-400 to-green-600 text-xs font-bold text-white">
                  {user.displayName?.[0]?.toUpperCase() ?? "?"}
                </div>
              )}
            </div>
          </div>

          <AnimatePresence mode="wait">
            <div key={location.pathname}>
              <Outlet />
            </div>
          </AnimatePresence>
        </div>
      </div>

      {/* Mobile bottom-nav */}
      <nav
        aria-label="Primary"
        className="fixed inset-x-0 bottom-0 z-nav flex items-center justify-around border-t border-hairline bg-ink-surface/85 px-2 py-2 backdrop-blur-2xl md:hidden"
      >
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === "/"}
            className={({ isActive }) =>
              `flex min-w-[44px] flex-col items-center gap-0.5 rounded-lg px-2 py-1.5 text-[10px] font-medium transition-colors duration-200 ${
                isActive ? "text-cinema-400" : "text-text-dim"
              }`
            }
          >
            <Icon name={item.icon} size={20} />
            {item.label}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
