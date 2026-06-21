// ============================================================
// RAWBY — user prompt settings (Zustand, persisted). Region +
// seasonal toggle feed /api/generate-prompts for local/seasonal results.
// ============================================================
import { create } from "zustand";
import { persist } from "zustand/middleware";

export const REGIONS = [
  "Global",
  "United States",
  "United Kingdom",
  "Canada",
  "Australia",
  "Ireland",
  "Germany",
  "France",
  "Spain",
  "Italy",
  "Netherlands",
  "Sweden",
  "Norway",
  "Poland",
  "India",
  "Japan",
  "South Korea",
  "Brazil",
  "Mexico",
  "South Africa",
  "Nigeria",
  "United Arab Emirates",
] as const;

interface SettingsState {
  region: string;
  seasonalPrompts: boolean;
  setRegion: (r: string) => void;
  setSeasonal: (s: boolean) => void;
}

export const useSettings = create<SettingsState>()(
  persist(
    (set) => ({
      region: "Global",
      seasonalPrompts: true,
      setRegion: (region) => set({ region }),
      setSeasonal: (seasonalPrompts) => set({ seasonalPrompts }),
    }),
    { name: "rawby-settings" }
  )
);
