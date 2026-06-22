// ============================================================
// RAWBY — SVG icon set (Lucide-style, 24px grid, stroke-based).
// No emoji icons anywhere. Consistent 1.75 stroke, round joins.
// ============================================================
import type { SVGProps } from "react";

export type IconName =
  | "home"
  | "clapper"
  | "trophy"
  | "aperture"
  | "bulb"
  | "sparkles"
  | "user"
  | "settings"
  | "star"
  | "flame"
  | "medal"
  | "refresh"
  | "send"
  | "camera"
  | "mic"
  | "sun"
  | "moon"
  | "scissors"
  | "palette"
  | "volume"
  | "clock"
  | "arrowRight"
  | "check"
  | "alert"
  | "film"
  | "logout"
  | "calendar"
  | "plus"
  | "quote"
  | "eye"
  | "eyeOff"
  | "shield"
  | "tag"
  | "heart";

// Inner SVG geometry per icon.
const PATHS: Record<IconName, JSX.Element> = {
  home: <><path d="M3 10.5 12 3l9 7.5" /><path d="M5 9.5V21h14V9.5" /><path d="M9.5 21v-6h5v6" /></>,
  clapper: <><path d="M3 8.5h18V19a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8.5Z" /><path d="m3.4 8.5 1-3.4 3.8.9-1 3.4" /><path d="m9.3 6.5 1-3.4 3.8.9-1 3.4" /><path d="m15.2 7.4 1-3.4 3.8.9-1 3.4" /></>,
  trophy: <><path d="M7 4h10v4a5 5 0 0 1-10 0V4Z" /><path d="M7 6H4v1a3 3 0 0 0 3 3" /><path d="M17 6h3v1a3 3 0 0 1-3 3" /><path d="M12 13v4" /><path d="M9 21h6" /><path d="M10 17h4l.5 4h-5l.5-4Z" /></>,
  aperture: <><circle cx="12" cy="12" r="9" /><path d="m12 3 4 7" /><path d="m21 12-8 0" /><path d="m16 19-4-7" /><path d="m8 21-4-7" /><path d="m3 12 8 0" /><path d="m8 5 4 7" /></>,
  bulb: <><path d="M9 18h6" /><path d="M10 21h4" /><path d="M12 3a6 6 0 0 0-4 10.5c.7.7 1 1.5 1 2.5h6c0-1 .3-1.8 1-2.5A6 6 0 0 0 12 3Z" /></>,
  sparkles: <><path d="M12 3l1.8 5L19 9.8 13.8 11 12 16l-1.8-5L5 9.8 10.2 8 12 3Z" /><path d="M19 15l.7 2 2 .7-2 .7L19 21l-.7-2-2-.7 2-.7.7-2Z" /></>,
  user: <><circle cx="12" cy="8" r="4" /><path d="M5 21a7 7 0 0 1 14 0" /></>,
  settings: <><circle cx="12" cy="12" r="3" /><path d="M19.4 13.5a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-2.7-1.1l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H3a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 4.6 8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 10 4.6V4a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7h.6a2 2 0 1 1 0 4h-.6a1.6 1.6 0 0 0-1.5 1Z" /></>,
  star: <><path d="m12 3 2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9 6.8 19.2l1-5.8L3.5 9.3l5.9-.9L12 3Z" /></>,
  flame: <><path d="M12 3c1 3-2 4-2 7a2.5 2.5 0 0 0 5 .3c1 1.2 1.5 2.4 1.5 3.7a4.5 4.5 0 0 1-9 0C7.5 9 12 8 12 3Z" /></>,
  medal: <><circle cx="12" cy="15" r="5" /><path d="m8.5 11-3-7" /><path d="m18.5 4-3 7" /><path d="m10 4 2 3 2-3" /><path d="M12 13.5v3" /></>,
  refresh: <><path d="M3 12a9 9 0 0 1 15-6.7L21 8" /><path d="M21 3v5h-5" /><path d="M21 12a9 9 0 0 1-15 6.7L3 16" /><path d="M3 21v-5h5" /></>,
  send: <><path d="M22 2 11 13" /><path d="M22 2 15 22l-4-9-9-4 20-7Z" /></>,
  camera: <><path d="M3 8h3l1.2-2h6.6L21 8v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8Z" /><circle cx="12" cy="13" r="3.2" /></>,
  mic: <><rect x="9" y="3" width="6" height="11" rx="3" /><path d="M5 11a7 7 0 0 0 14 0" /><path d="M12 18v3" /></>,
  sun: <><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5 4 4M20 20l-1-1M19 5l1-1M4 20l1-1" /></>,
  moon: <><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" /></>,
  scissors: <><circle cx="6" cy="6" r="2.5" /><circle cx="6" cy="18" r="2.5" /><path d="M8 8l12 8M8 16 20 8" /></>,
  palette: <><path d="M12 3a9 9 0 0 0 0 18c1.4 0 2-1 2-2 0-1.4 1-2 2-2h1a4 4 0 0 0 4-4c0-4.4-4-8-9-8Z" /><circle cx="8" cy="11" r="1" /><circle cx="12" cy="8" r="1" /><circle cx="16" cy="11" r="1" /></>,
  volume: <><path d="M4 9v6h4l5 4V5L8 9H4Z" /><path d="M17 8a5 5 0 0 1 0 8" /></>,
  clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  arrowRight: <><path d="M5 12h14" /><path d="m13 6 6 6-6 6" /></>,
  check: <><path d="m5 12 5 5L20 7" /></>,
  alert: <><circle cx="12" cy="12" r="9" /><path d="M12 8v4" /><path d="M12 16h.01" /></>,
  film: <><rect x="3" y="3" width="18" height="18" rx="2" /><path d="M7 3v18M17 3v18M3 8h4M3 12h4M3 16h4M17 8h4M17 12h4M17 16h4" /></>,
  logout: <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><path d="m16 17 5-5-5-5" /><path d="M21 12H9" /></>,
  calendar: <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M3 9h18M8 3v4M16 3v4" /></>,
  plus: <><path d="M12 5v14M5 12h14" /></>,
  quote: <><path d="M7 7H5a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h2v-2H5V9h2V7Zm10 0h-2a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h2v-2h-2V9h2V7Z" /></>,
  eye: <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z" /><circle cx="12" cy="12" r="3" /></>,
  eyeOff: <><path d="M9.9 4.2A10.9 10.9 0 0 1 12 4c6.5 0 10 7 10 7a18 18 0 0 1-3 3.7M6.5 6.5A18 18 0 0 0 2 11s3.5 7 10 7a10.9 10.9 0 0 0 4.3-.9" /><path d="M9.6 9.6a3 3 0 0 0 4.2 4.2" /><path d="M3 3l18 18" /></>,
  shield: <><path d="M12 3l7 3v5c0 4.6-3 7.7-7 9-4-1.3-7-4.4-7-9V6l7-3Z" /><path d="m9 12 2 2 4-4" /></>,
  tag: <><path d="M3 7v5a2 2 0 0 0 .6 1.4l7 7a2 2 0 0 0 2.8 0l5-5a2 2 0 0 0 0-2.8l-7-7A2 2 0 0 0 12 5H7a4 4 0 0 0-4 4Z" /><circle cx="8" cy="8" r="1.2" /></>,
  heart: <><path d="M12 20s-7-4.3-9.2-8.5C1.3 8.2 3 5 6 5c1.8 0 3 1 3 1s.2-.2 3-1c3 0 4.7 3.2 3.2 6.5C19 15.7 12 20 12 20Z" /></>,
};

interface Props extends SVGProps<SVGSVGElement> {
  name: IconName;
  size?: number;
}

export function Icon({ name, size = 20, className = "", ...rest }: Props) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill="none"
      stroke="currentColor"
      strokeWidth={1.75}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
      {...rest}
    >
      {PATHS[name]}
    </svg>
  );
}
