import { useNavigate } from "react-router-dom";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { ThemeControls } from "../components/ui/ThemeControls";
import { useAuth } from "../store/auth";
import { useSettings, COUNTRIES } from "../store/settings";
import { BASE_URL } from "../lib/api";

function Row({ label, sub, children }: { label: string; sub?: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 py-4">
      <div>
        <div className="text-sm font-semibold text-text-hi">{label}</div>
        {sub && <div className="text-xs text-text-dim">{sub}</div>}
      </div>
      {children}
    </div>
  );
}

export default function Settings() {
  const nav = useNavigate();
  const logout = useAuth((s) => s.logout);
  const user = useAuth((s) => s.user);
  const region = useSettings((s) => s.region);
  const setRegion = useSettings((s) => s.setRegion);
  const seasonal = useSettings((s) => s.seasonalPrompts);
  const setSeasonal = useSettings((s) => s.setSeasonal);
  const showCategories = useSettings((s) => s.showCategories);
  const setShowCategories = useSettings((s) => s.setShowCategories);

  return (
    <PageTransition>
      <PageHeader eyebrow="Preferences" title="Settings" />

      <GlassCard className="mb-4">
        <ThemeControls />
      </GlassCard>

      <GlassCard className="mb-4 space-y-5">
        <div>
          <div className="text-sm font-semibold text-text-hi">Prompt tuning</div>
          <div className="text-xs text-text-dim">Where you are + the season shape your prompts.</div>
        </div>
        <div>
          <label htmlFor="set-region" className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-text-dim">
            Country / region
          </label>
          <input
            id="set-region"
            list="country-list"
            value={region}
            onChange={(e) => setRegion(e.target.value)}
            placeholder="e.g. Hungary"
            className="w-full rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none focus:border-cinema-500/70"
          />
          <datalist id="country-list">
            {COUNTRIES.map((r) => (
              <option key={r} value={r} />
            ))}
          </datalist>
        </div>
        <button
          type="button"
          role="switch"
          aria-checked={seasonal}
          onClick={() => setSeasonal(!seasonal)}
          className="flex w-full items-center justify-between gap-4 rounded-xl border border-hairline bg-chip px-4 py-3 text-left transition-colors hover:border-hairline-strong"
        >
          <div>
            <div className="text-sm font-medium text-text-hi">Seasonal prompts</div>
            <div className="text-xs text-text-dim">Tune ideas to the time of year.</div>
          </div>
          <span
            className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
              seasonal ? "bg-cinema-500" : "bg-hairline-strong"
            }`}
          >
            <span
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                seasonal ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
          </span>
        </button>
        <button
          type="button"
          role="switch"
          aria-checked={showCategories}
          onClick={() => setShowCategories(!showCategories)}
          className="flex w-full items-center justify-between gap-4 rounded-xl border border-hairline bg-chip px-4 py-3 text-left transition-colors hover:border-hairline-strong"
        >
          <div>
            <div className="text-sm font-medium text-text-hi">Videography box on Home</div>
            <div className="text-xs text-text-dim">Show the category map + per-category stats.</div>
          </div>
          <span
            className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
              showCategories ? "bg-cinema-500" : "bg-hairline-strong"
            }`}
          >
            <span
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                showCategories ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
          </span>
        </button>
      </GlassCard>

      <GlassCard className="divide-y divide-divide">
        <Row label="Account" sub={user ? `@${user.username} · ${user.email ?? "no email"}` : "—"}>
          <span className="text-xs text-text-dim">{user?.displayName}</span>
        </Row>

        <Row label="API endpoint" sub="Backend the app talks to">
          <code className="rounded bg-field px-2 py-1 text-xs text-text-dim">{BASE_URL}</code>
        </Row>
      </GlassCard>

      <div className="mt-6">
        <GradientButton
          variant="ghost"
          className="!text-danger"
          onClick={() => {
            logout();
            nav("/login", { replace: true });
          }}
        >
          <Icon name="logout" size={16} /> Sign out
        </GradientButton>
      </div>

      <p className="mt-8 text-center text-xs text-text-dim">
        RAWBY · cinematic weekly film challenge · React web client
      </p>
    </PageTransition>
  );
}
