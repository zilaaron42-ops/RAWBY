// ============================================================
// RAWBY — user prompt settings (Zustand, persisted). Region +
// seasonal toggle feed /api/generate-prompts for local/seasonal results.
// ============================================================
import { create } from "zustand";
import { persist } from "zustand/middleware";

// Suggestions for the region picker — it's a free-text input, so any
// country works even if it's not listed here.
export const COUNTRIES = [
  "Global",
  "Argentina", "Australia", "Austria", "Belgium", "Brazil", "Bulgaria",
  "Canada", "Chile", "China", "Colombia", "Croatia", "Czechia", "Denmark",
  "Egypt", "Estonia", "Finland", "France", "Germany", "Greece", "Hungary",
  "Iceland", "India", "Indonesia", "Ireland", "Israel", "Italy", "Japan",
  "Kenya", "Latvia", "Lithuania", "Malaysia", "Mexico", "Morocco",
  "Netherlands", "New Zealand", "Nigeria", "Norway", "Pakistan", "Peru",
  "Philippines", "Poland", "Portugal", "Romania", "Saudi Arabia", "Serbia",
  "Singapore", "Slovakia", "Slovenia", "South Africa", "South Korea", "Spain",
  "Sweden", "Switzerland", "Thailand", "Turkey", "Ukraine",
  "United Arab Emirates", "United Kingdom", "United States", "Vietnam",
] as const;

interface SettingsState {
  region: string;
  seasonalPrompts: boolean;
  showCategories: boolean; // the videography box on Home
  setRegion: (r: string) => void;
  setSeasonal: (s: boolean) => void;
  setShowCategories: (s: boolean) => void;
}

export const useSettings = create<SettingsState>()(
  persist(
    (set) => ({
      region: "Global",
      seasonalPrompts: true,
      showCategories: true,
      setRegion: (region) => set({ region }),
      setSeasonal: (seasonalPrompts) => set({ seasonalPrompts }),
      setShowCategories: (showCategories) => set({ showCategories }),
    }),
    { name: "rawby-settings" }
  )
);
