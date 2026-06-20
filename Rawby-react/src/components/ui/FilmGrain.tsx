// Faint animated film-grain overlay. Pointer-events off, above content.
// Opacity follows --grain-opacity (lighter in light theme).
export function FilmGrain({ opacity }: { opacity?: number }) {
  return (
    <div
      aria-hidden="true"
      className="film-grain pointer-events-none fixed inset-0 z-grain animate-grain mix-blend-overlay"
      style={{ opacity: opacity ?? "var(--grain-opacity)" }}
    />
  );
}
