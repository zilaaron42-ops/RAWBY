// ============================================================
// RAWBY — shared API types (mirror the Dart server payloads)
// ============================================================

export interface User {
  id?: string;
  username: string;
  displayName: string;
  email?: string;
  isAdmin?: boolean;
  accent?: string;
  rank?: number;
  totalScore?: number;
  streak?: number;
  avatarUrl?: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export type PromptLevel =
  | "Sequence"
  | "Short Story"
  | "Story + Character"
  | "Big Project";

export interface PromptItem {
  id?: string;
  level: PromptLevel | string;
  title: string;
  text: string;
  points?: number;
}

export interface Song {
  title: string;
  artist: string;
  tier?: string;
  why?: string;
}

/** A prompt object as returned by /api/generate-prompts. */
export interface GeneratedPrompt {
  text: string;
  level: string;
  points?: number;
  category?: string;
  emotion?: string;
  outcome?: string;
  purpose?: string;
  shots?: string[];
  songs?: Song[];
}

/** Live weekly snapshot returned by /api/me */
export interface Snapshot {
  rank?: number;
  totalScore?: number;
  streak?: number;
  regensLeft?: number;
  daysLeft?: number;
  promptLevel?: string;
  promptText?: string;
  phase?: string;
  weekNumber?: number;
  history?: ProjectHistoryItem[];
  gear?: GearItem[]; // owned gear inventory
  phaseDone?: string[]; // completed phases for the current project
  bigProject?: BigProject; // active personal Big Project
  note?: string; // quick note Aurora can see
  profile?: UserProfile; // onboarding answers — personalises prompts
  activeDraft?: PromptWorkspace; // the prompt currently being worked out
  visibility?: Visibility; // what others see on your profile
}

export interface UserProfile {
  location?: string; // where exactly they live / shoot
  style?: string; // visual style / vibe
  experience?: string; // beginner / intermediate / pro
  focus?: string; // what they want from filmmaking
  completed?: boolean;
}

export interface PromptWorkspace {
  promptText: string;
  level: string;
  storyline: string;
  shots: string[];
  music: string[];
  notes: string;
  gear: string[]; // gear item ids
}

export interface BigProject {
  id: string;
  title: string;
  deadline: string; // ISO date the user sets as their own time limit
  startedAt: string; // ISO
}

export interface MeResponse {
  user: User;
  snapshot?: Snapshot;
  prompts?: PromptItem[];
  history?: ProjectHistoryItem[];
}

export interface ProjectHistoryItem {
  id?: string;
  title: string;
  level: string;
  score?: number;
  week?: number;
  date?: string;
  link?: string;
  submittedAt?: string; // ISO timestamp, captured automatically
  lateIdx?: number; // index into LATE_MULTIPLIERS at submit time
  gear?: string[]; // gear item ids used on this project
  likes?: number; // fetched reel likes (feeds scoring)
}

export type GearStatus = "active" | "rested" | "retired";

export interface GearItem {
  id: string;
  brand: string; // e.g. Sony, Rode, DJI
  type: string; // e.g. Camera body, Shotgun mic, Tripod
  category: string;
  status?: GearStatus; // missing = active
  restedAt?: string; // ISO, when auto/ manually rested
}

export interface Visibility {
  publicProfile: boolean;
  showScore: boolean;
  showStreak: boolean;
  showRank: boolean;
  showFilms: boolean;
  showGear: boolean;
}

export interface LeaderboardEntry {
  rank: number;
  username: string;
  displayName: string;
  totalScore: number;
  streak?: number;
  avatarUrl?: string;
}

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface ChatContext {
  displayName?: string;
  rank?: number;
  totalScore?: number;
  streak?: number;
  regensLeft?: number;
  daysLeft?: number;
  promptLevel?: string;
  promptText?: string;
  note?: string; // quick note
  location?: string;
  style?: string;
  gear?: string[]; // owned gear, brand+type strings
}

export type AIProvider = "groq" | "claude";

export interface Suggestion {
  id?: string;
  text: string;
  createdAt?: string;
}
