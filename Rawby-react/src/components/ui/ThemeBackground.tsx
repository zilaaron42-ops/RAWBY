// Per-theme cinematic backdrop. Each accent streams its own looping video
// (free CC0 footage from Pexels' CDN). If a stream fails we fall back to the
// animated gold-aurora layer, so the app always has a moving background.
// A veil + vignette keep glass + text readable.
import { useState } from "react";
import { useTheme } from "../../store/theme";

const SRC: Record<string, string> = {
  amber: "/bg/amber.mp4", // spiral galaxy / deep space
  green: "/bg/green.mp4", // forest, drone over trees
  azure: "/bg/azure.mp4", // ocean waves
  rose: "/bg/rose.mp4", // campfire flames
};

export function ThemeBackground() {
  const accent = useTheme((s) => s.accent);
  const [failed, setFailed] = useState<Record<string, boolean>>({});
  const useVideo = !failed[accent];

  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden bg-ink-bg" aria-hidden="true">
      {useVideo ? (
        <video
          key={accent}
          src={SRC[accent]}
          autoPlay
          loop
          muted
          playsInline
          preload="auto"
          onLoadedMetadata={(e) => {
            e.currentTarget.playbackRate = 0.45; // slow + cinematic
          }}
          onError={() => setFailed((f) => ({ ...f, [accent]: true }))}
          className="animate-fade-in absolute inset-0 h-full w-full object-cover"
          style={{ filter: "brightness(1.1) saturate(1.15) contrast(1.04)" }}
        />
      ) : (
        <div className="aurora-layer" />
      )}

      {/* Veil — dims the footage just enough to keep glass + text readable
          while the scene still reads clearly. */}
      <div className="absolute inset-0" style={{ background: "rgb(var(--bg) / 0.44)" }} />
      {/* Soft top accent wash + edge vignette. */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(75% 45% at 50% -12%, rgb(var(--c-500) / 0.12), transparent 60%), radial-gradient(135% 110% at 50% 34%, transparent 42%, rgb(var(--bg) / 0.82) 100%)",
        }}
      />
    </div>
  );
}
