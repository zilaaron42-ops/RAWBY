// Apple-"Tahoe"-style floating liquid-glass dock — simple, fixed-size icon
// tiles (no magnify). Centred at the bottom.
import { NavLink } from "react-router-dom";
import { Icon } from "../ui/Icon";
import type { NavItem } from "./nav";

export function Dock({ items }: { items: NavItem[] }) {
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-nav flex justify-center px-3 pb-4 md:pb-6">
      <nav
        aria-label="Primary"
        className="dock no-scrollbar pointer-events-auto flex max-w-full items-center gap-1.5 overflow-x-auto rounded-[28px] border border-white/[0.07] bg-[rgb(var(--dock))] px-2.5 py-2"
      >
        {items.map((it) => (
          <NavLink
            key={it.to}
            to={it.to}
            end={it.to === "/home"}
            title={it.label}
            className={({ isActive }) =>
              `group relative flex h-12 w-12 shrink-0 items-center justify-center rounded-[16px] transition-colors duration-200 ${
                isActive
                  ? "bg-cinema-500 text-[#16161a] shadow-[0_6px_18px_-6px_rgb(var(--c-500)/0.7)]"
                  : "text-text-dim hover:bg-glass hover:text-text-hi"
              }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon name={it.icon} size={22} strokeWidth={isActive ? 2.3 : 1.9} />
                <span className="pointer-events-none absolute -top-10 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-lg border border-hairline bg-[rgb(var(--surface))] px-2.5 py-1 text-[11px] font-semibold text-text-hi opacity-0 shadow-lg transition-opacity duration-150 group-hover:opacity-100">
                  {it.label}
                </span>
              </>
            )}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
