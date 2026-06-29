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
  const holidayMode = useSettings((s) => s.holidayMode);
  const setHolidayMode = useSettings((s) => s.setHolidayMode);
  const holidayDays = useSettings((s) => s.holidayDays);
  const setHolidayDays = useSettings((s) => s.setHolidayDays);
  const useClaude = useSettings((s) => s.useClaude);
  const setUseClaude = useSettings((s) => s.setUseClaude);

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

      {/* Holiday mode */}
      <GlassCard className="mb-4 space-y-4">
        <div className="flex items-center gap-2">
          <Icon name="sun" size={18} className="text-cinema-400" />
          <div>
            <div className="text-sm font-semibold text-text-hi">Holiday mode</div>
            <div className="text-xs text-text-dim">
              Summer schedule's off? Skip the Friday cycle — your filming clock starts when you
              lock in a prompt and runs a fixed window.
            </div>
          </div>
        </div>
        <button
          type="button"
          role="switch"
          aria-checked={holidayMode}
          onClick={() => setHolidayMode(!holidayMode)}
          className="flex w-full items-center justify-between gap-4 rounded-xl border border-hairline bg-chip px-4 py-3 text-left transition-colors hover:border-hairline-strong"
        >
          <div>
            <div className="text-sm font-medium text-text-hi">Start the clock on lock-in</div>
            <div className="text-xs text-text-dim">Countdown begins when you start, not on Friday.</div>
          </div>
          <span
            className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
              holidayMode ? "bg-cinema-500" : "bg-hairline-strong"
            }`}
          >
            <span
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                holidayMode ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
          </span>
        </button>
        {holidayMode && (
          <div className="flex items-center justify-between gap-4 rounded-xl border border-hairline bg-chip px-4 py-3">
            <div>
              <div className="text-sm font-medium text-text-hi">Filming window</div>
              <div className="text-xs text-text-dim">Days you get once a project starts.</div>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setHolidayDays(holidayDays - 1)}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-hairline text-text-hi transition-colors hover:border-cinema-500/70"
                aria-label="Fewer days"
              >
                <Icon name="plus" size={14} className="rotate-45" />
              </button>
              <span className="h-display w-10 text-center text-lg font-bold tabular-nums text-text-hi">
                {holidayDays}
              </span>
              <button
                onClick={() => setHolidayDays(holidayDays + 1)}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-hairline text-text-hi transition-colors hover:border-cinema-500/70"
                aria-label="More days"
              >
                <Icon name="plus" size={14} />
              </button>
            </div>
          </div>
        )}
      </GlassCard>

      {/* Aurora brain */}
      <GlassCard className="mb-4 space-y-4">
        <div className="flex items-center gap-2">
          <Icon name="sparkles" size={18} className="text-cinema-400" />
          <div>
            <div className="text-sm font-semibold text-text-hi">Aurora's brain</div>
            <div className="text-xs text-text-dim">
              By default Aurora runs on Groq (free). Switch her to your own Claude subscription via
              the bridge — see claude-bridge/README. Falls back to Groq if the bridge isn't set up.
            </div>
          </div>
        </div>
        <button
          type="button"
          role="switch"
          aria-checked={useClaude}
          onClick={() => setUseClaude(!useClaude)}
          className="flex w-full items-center justify-between gap-4 rounded-xl border border-hairline bg-chip px-4 py-3 text-left transition-colors hover:border-hairline-strong"
        >
          <div>
            <div className="text-sm font-medium text-text-hi">Use my Claude (Pro)</div>
            <div className="text-xs text-text-dim">Route Aurora through your Claude plan.</div>
          </div>
          <span
            className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
              useClaude ? "bg-cinema-500" : "bg-hairline-strong"
            }`}
          >
            <span
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                useClaude ? "translate-x-5" : "translate-x-0.5"
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
