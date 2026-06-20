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
