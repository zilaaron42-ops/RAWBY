// ============================================================
// RAWBY — app shell. Side-nav on desktop (>=768px), bottom-nav on
// mobile + a slim mobile top bar. Hosts the 3D AuraScene, grain,
// and animated routes.
// ============================================================
import { NavLink, Outlet, useLocation } from "react-router-dom";
import { AnimatePresence } from "framer-motion";
import { FilmGrain } from "../ui/FilmGrain";
import { AuroraBackground } from "../ui/AuroraBackground";
import { Icon } from "../ui/Icon";
import { Logo } from "../ui/Logo";
import { ModeToggle } from "../ui/ThemeControls";
import { Onboarding } from "../Onboarding";
import { NAV_ITEMS, SECONDARY_ITEMS, ADMIN_ITEM, type NavItem } from "./nav";
import { useAuth } from "../../store/auth";

// Instagram-style nav row: roomy, icon + label, no persistent background.
// Active = bold label + accent icon; hover = subtle wash.
function SideLink({ item }: { item: NavItem }) {
  return (
    <NavLink
      to={item.to}
      end={item.to === "/home"}
      className={({ isActive }) =>
        `group flex items-center gap-4 rounded-xl px-3 py-2.5 text-[0.95rem] transition-colors duration-200 hover:bg-glass ${
          isActive ? "font-semibold text-text-hi" : "font-normal text-text-dim hover:text-text-hi"
        }`
      }
    >
      {({ isActive }) => (
        <>
          <Icon
            name={item.icon}
            size={23}
            strokeWidth={isActive ? 2.4 : 1.9}
            className={`shrink-0 transition-transform duration-200 group-hover:scale-110 ${
              isActive ? "text-cinema-400" : ""
            }`}
          />
          {item.label}
        </>
      )}
    </NavLink>
  );
}

function Avatar({ initial, size = "md" }: { initial: string; size?: "sm" | "md" }) {
  const cls = size === "sm" ? "h-8 w-8 text-xs" : "h-9 w-9 text-sm";
  return (
    <div
      className={`flex ${cls} items-center justify-center rounded-full bg-gradient-to-br from-cinema-300 to-cinema-600 font-bold text-[#1a1200] ring-1 ring-cinema-300/30`}
    >
      {initial}
    </div>
  );
}

export function Shell() {
  const location = useLocation();
  const user = useAuth((s) => s.user);
  const allItems: NavItem[] = [
    ...NAV_ITEMS,
    ...SECONDARY_ITEMS,
    ...(user?.isAdmin ? [ADMIN_ITEM] : []),
  ];
  const initial = user?.displayName?.[0]?.toUpperCase() ?? "?";

  return (
    <div className="relative min-h-screen">
      <AuroraBackground />
      <FilmGrain />
      <Onboarding />

      <div className="relative z-base flex min-h-screen">
        {/* Desktop side-nav */}
        <aside className="sticky top-0 hidden h-screen w-[15.5rem] shrink-0 flex-col border-r border-hairline bg-[rgb(var(--surface)/0.7)] px-3 py-5 backdrop-blur-xl md:flex">
          <div className="mb-4 flex items-center justify-between px-1.5">
            <Logo size="md" />
            <ModeToggle />
          </div>

          <nav aria-label="Primary" className="flex flex-1 flex-col gap-0.5 overflow-y-auto">
            {allItems.map((it) => (
              <SideLink key={it.to} item={it} />
            ))}
          </nav>

          {user && (
            <NavLink
              to="/profile"
              className="mt-3 flex items-center gap-3 rounded-xl border border-hairline bg-[rgb(var(--card-fill))] p-2.5 transition-colors hover:border-hairline-strong"
            >
              <Avatar initial={initial} />
              <div className="min-w-0">
                <div className="truncate text-sm font-semibold text-text-hi">{user.displayName}</div>
                <div className="truncate text-xs text-text-dim">@{user.username}</div>
              </div>
            </NavLink>
          )}
        </aside>

        <div className="flex-1">
          {/* Mobile top bar */}
          <div className="sticky top-0 z-nav flex items-center justify-between border-b border-hairline bg-[rgb(var(--surface)/0.8)] px-4 py-3 backdrop-blur-xl md:hidden">
            <Logo size="sm" />
            <div className="flex items-center gap-2">
              <ModeToggle />
              {user && <Avatar initial={initial} size="sm" />}
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
        className="fixed inset-x-0 bottom-0 z-nav flex items-center justify-around border-t border-hairline bg-[rgb(var(--surface)/0.85)] px-2 py-2 backdrop-blur-2xl md:hidden"
      >
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === "/home"}
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
