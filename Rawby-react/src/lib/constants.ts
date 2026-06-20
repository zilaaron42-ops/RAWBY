// ============================================================
// RAWBY — domain constants (scoring, weekly cycle, level styling)
// ============================================================

export const LEVELS = [
  { name: "Sequence", points: 10, gradient: "level-sequence", glow: "#5A8A5E" },
  { name: "Short Story", points: 30, gradient: "level-short", glow: "#E8B647" },
  { name: "Story + Character", points: 50, gradient: "level-story", glow: "#E85D75" },
  { name: "Big Project", points: 150, gradient: "level-story", glow: "#B12B5C" },
] as const;

export function levelStyle(level?: string) {
  return LEVELS.find((l) => l.name === level) ?? LEVELS[1];
}

// Late penalty multipliers (days past deadline).
export const LATE_MULTIPLIERS = [
  { day: "On time", mult: 1.0 },
  { day: "Day 1", mult: 0.9 },
  { day: "Day 2", mult: 0.75 },
  { day: "Day 3+", mult: 0.5 },
] as const;

// Weekly production cycle.
export const WEEKLY_CYCLE = [
  { day: "Friday", phase: "Song + Prompt", desc: "Song selection + prompt locked" },
  { day: "Sat–Sun", phase: "Filming", desc: "Shoot your footage" },
  { day: "Mon–Tue", phase: "Rough Edit", desc: "Assemble the cut" },
  { day: "Tue–Wed", phase: "VFX + Text", desc: "Effects + overlays" },
  { day: "Tue–Wed", phase: "SFX + Sound", desc: "Sound design" },
  { day: "Wed–Thu", phase: "Colour Grade", desc: "Grade the look" },
  { day: "Friday", phase: "Polish + Publish", desc: "Finish + release" },
] as const;
