// Animated aurora backdrop — adapted from a 21st.dev aurora component and
// recoloured to RAWBY's gold accent. Pure CSS (no 3D), lightweight, sits
// behind all content with a soft edge vignette to keep text clean.
export function AuroraBackground() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden="true">
      <div className="aurora-layer" />
      <div className="cine-vignette" />
    </div>
  );
}
