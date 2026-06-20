import { levelStyle } from "../../lib/constants";

const GRADIENTS: Record<string, string> = {
  "level-sequence": "linear-gradient(135deg,#6FA373,#3D6B41)",
  "level-short": "linear-gradient(135deg,#E8B647,#C97E2C)",
  "level-story": "linear-gradient(135deg,#E85D75,#B12B5C)",
};

export function FilmTag({ level }: { level?: string }) {
  const s = levelStyle(level);
  const onLight = s.gradient === "level-short";
  return (
    <span
      className="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold shadow-sm"
      style={{
        backgroundImage: GRADIENTS[s.gradient],
        color: onLight ? "#1A1100" : "#fff",
      }}
    >
      {level ?? "Short Story"} · {s.points} pts
    </span>
  );
}
