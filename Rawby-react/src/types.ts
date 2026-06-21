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

export interface GearItem {
  id: string;
  name: string;
  category: string;
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
}

export type AIProvider = "groq" | "claude";

export interface Suggestion {
  id?: string;
  text: string;
  createdAt?: string;
}
