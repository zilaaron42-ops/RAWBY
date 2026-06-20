// ============================================================
// RAWBY — theme store (Zustand, persisted). Drives the
// data-theme (light/dark) + data-accent (amber/green/azure/rose)
// attributes on <html>, which the CSS variables key off.
// ============================================================
import { create } from "zustand";
import { persist } from "zustand/middleware";

export type Mode = "dark" | "light";
export type Accent = "amber" | "green" | "azure" | "rose";

export const ACCENTS: { id: Accent; label: string; swatch: string }[] = [
  { id: "amber", label: "Cinema", swatch: "#E8B647" },
  { id: "green", label: "Pine", swatch: "#5A8A5E" },
  { id: "azure", label: "Azure", swatch: "#3B82F6" },
  { id: "rose", label: "Ember", swatch: "#E85D75" },
];

interface ThemeState {
  mode: Mode;
  accent: Accent;
  setMode: (m: Mode) => void;
  toggleMode: () => void;
  setAccent: (a: Accent) => void;
}

export function applyTheme(mode: Mode, accent: Accent) {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  root.setAttribute("data-theme", mode);
  root.setAttribute("data-accent", accent);
}

export const useTheme = create<ThemeState>()(
  persist(
    (set, get) => ({
      mode: "dark",
      accent: "amber",
      setMode: (mode) => {
        applyTheme(mode, get().accent);
        set({ mode });
      },
      toggleMode: () => {
        const mode = get().mode === "dark" ? "light" : "dark";
        applyTheme(mode, get().accent);
        set({ mode });
      },
      setAccent: (accent) => {
        applyTheme(get().mode, accent);
        set({ accent });
      },
    }),
    {
      name: "rawby-theme",
      onRehydrateStorage: () => (state) => {
        if (state) applyTheme(state.mode, state.accent);
      },
    }
  )
);
