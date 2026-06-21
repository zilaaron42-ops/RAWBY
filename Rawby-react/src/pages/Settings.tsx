import { useNavigate } from "react-router-dom";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { ThemeControls } from "../components/ui/ThemeControls";
import { useAuth } from "../store/auth";
import { useSettings, REGIONS } from "../store/settings";
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
  const provider = useAuth((s) => s.aiProvider);
  const setProvider = useAuth((s) => s.setProvider);
  const logout = useAuth((s) => s.logout);
  const user = useAuth((s) => s.user);
  const region = useSettings((s) => s.region);
  const setRegion = useSettings((s) => s.setRegion);
  const seasonal = useSettings((s) => s.seasonalPrompts);
  const setSeasonal = useSettings((s) => s.setSeasonal);

  return (
    <PageTransition>
      <PageHeader eyebrow="Preferences" title="Settings" />

      <GlassCard className="mb-4">
        <ThemeControls />
      </GlassCard>

      <GlassCard className="mb-4 space-y-5">
        <div>
          <div className="text-sm font-semibold text-text-hi">Prompt tuning</div>
          <div className="text-xs text-text-dim">Country + season shape your generated prompts.</div>
        </div>
        <div className="flex items-center justify-between gap-4">
          <label htmlFor="set-region" className="text-sm text-text-hi">Country / region</label>
          <select
            id="set-region"
            value={region}
            onChange={(e) => setRegion(e.target.value)}
            className="rounded-xl border border-hairline bg-field px-3 py-2 text-sm text-text-hi outline-none focus:border-cinema-500/70"
          >
            {REGIONS.map((r) => (
              <option key={r} value={r} className="bg-ink-card">{r}</option>
            ))}
          </select>
        </div>
        <div className="flex items-center justify-between gap-4">
          <div>
            <div className="text-sm text-text-hi">Seasonal prompts</div>
            <div className="text-xs text-text-dim">Tune ideas to the time of year.</div>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={seasonal}
            onClick={() => setSeasonal(!seasonal)}
            className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
              seasonal ? "bg-cinema-500" : "border border-hairline bg-chip"
            }`}
          >
            <span
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                seasonal ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
          </button>
        </div>
      </GlassCard>

      <GlassCard className="mb-4 space-y-4">
        <div>
          <div className="text-sm font-semibold text-text-hi">Prompt tuning</div>
          <div className="text-xs text-text-dim">Country + season shape your generated prompts.</div>
        </div>
        <div className="flex items-center justify-between gap-4">
          <label htmlFor="set-region" className="text-sm text-text-dim">
            Country / region
          </label>
          <select
            id="set-region"
            value={region}
            onChange={(e) => setRegion(e.target.value)}
            className="rounded-xl border border-hairline bg-field px-3 py-2 text-sm text-text-hi outline-none focus:border-cinema-500/70"
          >
            {REGIONS.map((r) => (
              <option key={r} value={r} className="bg-ink-card">
                {r}
              </option>
            ))}
          </select>
        </div>
        <div className="flex items-center justify-between gap-4">
          <div>
            <div className="text-sm text-text-hi">Seasonal prompts</div>
            <div className="text-xs text-text-dim">Tune to the time of year.</div>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={seasonal}
            onClick={() => setSeasonal(!seasonal)}
            className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
              seasonal ? "bg-cinema-500" : "border border-hairline bg-chip"
            }`}
          >
            <span
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                seasonal ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
          </button>
        </div>
      </GlassCard>

      <GlassCard className="divide-y divide-divide">
        <Row label="AI provider" sub="Aurora's engine. Groq is free.">
          <div className="flex items-center gap-1 rounded-xl border border-hairline bg-field p-1 text-xs font-semibold">
            {(["groq", "claude"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setProvider(p)}
                className={`rounded-lg px-3 py-1.5 transition-colors ${
                  provider === p ? "bg-cinema-500 text-[#1A1100]" : "text-text-dim hover:text-text-hi"
                }`}
              >
                {p === "groq" ? "Groq" : "Claude"}
              </button>
            ))}
          </div>
        </Row>

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
