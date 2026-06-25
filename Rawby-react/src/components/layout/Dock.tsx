// Apple-"Tahoe"-style floating liquid-glass dock with macOS-like magnify:
// tiles grow as the cursor nears them. Centred at the bottom.
import { useRef } from "react";
import { NavLink } from "react-router-dom";
import { motion, useMotionValue, useSpring, useTransform, type MotionValue } from "framer-motion";
import { Icon } from "../ui/Icon";
import type { NavItem } from "./nav";

function DockItem({ item, mouseX }: { item: NavItem; mouseX: MotionValue<number> }) {
  const ref = useRef<HTMLAnchorElement>(null);

  const distance = useTransform(mouseX, (val) => {
    const b = ref.current?.getBoundingClientRect() ?? { x: 0, width: 0 };
    return val - b.x - b.width / 2;
  });
  const sizeSync = useTransform(distance, [-120, 0, 120], [46, 62, 46]);
  const size = useSpring(sizeSync, { mass: 0.1, stiffness: 200, damping: 15 });

  return (
    <NavLink ref={ref} to={item.to} end={item.to === "/home"} title={item.label} className="group relative shrink-0">
      {({ isActive }) => (
        <motion.span
          style={{ width: size, height: size }}
          className={`flex items-center justify-center rounded-[18px] transition-colors duration-200 ${
            isActive
              ? "bg-cinema-500 text-[#16161a] shadow-[0_6px_18px_-6px_rgb(var(--c-500)/0.7)]"
              : "text-text-dim hover:bg-glass hover:text-text-hi"
          }`}
        >
          <Icon name={item.icon} size={22} strokeWidth={isActive ? 2.3 : 1.9} />
          <span className="pointer-events-none absolute -top-10 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-lg border border-hairline bg-[rgb(var(--surface))] px-2.5 py-1 text-[11px] font-semibold text-text-hi opacity-0 shadow-lg transition-opacity duration-150 group-hover:opacity-100">
            {item.label}
          </span>
        </motion.span>
      )}
    </NavLink>
  );
}

export function Dock({ items }: { items: NavItem[] }) {
  const mouseX = useMotionValue(Infinity);
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-nav flex justify-center px-3 pb-4 md:pb-6">
      <nav
        aria-label="Primary"
        onMouseMove={(e) => mouseX.set(e.clientX)}
        onMouseLeave={() => mouseX.set(Infinity)}
        className="dock no-scrollbar pointer-events-auto flex max-w-full items-end gap-2 overflow-x-auto rounded-[30px] border border-white/12 bg-[rgb(var(--surface)/0.45)] px-3 py-2.5 backdrop-blur-2xl"
      >
        {items.map((it) => (
          <DockItem key={it.to} item={it} mouseX={mouseX} />
        ))}
      </nav>
    </div>
  );
}
