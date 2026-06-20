import { Icon } from "./Icon";
import { useTheme, ACCENTS } from "../../store/theme";

/** Compact light/dark toggle for nav bars. */
export function ModeToggle({ className = "" }: { className?: string }) {
  const mode = useTheme((s) => s.mode);
  const toggle = useTheme((s) => s.toggleMode);
  return (
    <button
      onClick={toggle}
      aria-label={mode === "dark" ? "Switch to light theme" : "Switch to dark theme"}
      className={`flex h-9 w-9 items-center justify-center rounded-lg border border-hairline bg-chip text-text-dim transition-colors duration-200 hover:text-text-hi ${className}`}
    >
      <Icon name={mode === "dark" ? "sun" : "moon"} size={18} />
    </button>
  );
}

/** Accent swatch picker. */
export function AccentPicker() {
  const accent = useTheme((s) => s.accent);
  const setAccent = useTheme((s) => s.setAccent);
  return (
    <div className="flex items-center gap-2">
      {ACCENTS.map((a) => (
        <button
          key={a.id}
          onClick={() => setAccent(a.id)}
          aria-label={`${a.label} accent`}
          aria-pressed={accent === a.id}
          title={a.label}
          className="h-7 w-7 rounded-full transition-transform duration-200 hover:scale-110"
          style={{
            background: a.swatch,
            boxShadow:
              accent === a.id
                ? `0 0 0 2px rgb(var(--bg)), 0 0 0 4px ${a.swatch}`
                : "inset 0 0 0 1px rgba(0,0,0,0.25)",
          }}
        />
      ))}
    </div>
  );
}

/** Full theme block for Settings. */
export function ThemeControls() {
  const mode = useTheme((s) => s.mode);
  const setMode = useTheme((s) => s.setMode);
  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between gap-4">
        <div>
          <div className="text-sm font-semibold text-text-hi">Appearance</div>
          <div className="text-xs text-text-dim">Light or dark surface.</div>
        </div>
        <div className="flex items-center gap-1 rounded-xl border border-hairline bg-field p-1 text-xs font-semibold">
          {(["dark", "light"] as const).map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 capitalize transition-colors ${
                mode === m ? "bg-cinema-500 text-[#1A1100]" : "text-text-dim hover:text-text-hi"
              }`}
            >
              <Icon name={m === "dark" ? "moon" : "sun"} size={14} />
              {m}
            </button>
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between gap-4">
        <div>
          <div className="text-sm font-semibold text-text-hi">Accent</div>
          <div className="text-xs text-text-dim">Recolours the UI + logo.</div>
        </div>
        <AccentPicker />
      </div>
    </div>
  );
}
