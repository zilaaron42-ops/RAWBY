// ============================================================
// RAWBY — typed endpoint wrappers around the axios client.
// Mirrors server/lib/router.dart. React never holds AI keys.
// ============================================================
import { api } from "./api";
import type {
  AuthResponse,
  MeResponse,
  LeaderboardEntry,
  ChatMessage,
  ChatContext,
  AIProvider,
  Suggestion,
  GeneratedPrompt,
} from "../types";

export const auth = {
  login: (username: string, password: string) =>
    api.post<AuthResponse>("/api/login", { username, password }).then((r) => r.data),

  register: (body: {
    username: string;
    displayName: string;
    email: string;
    password: string;
  }) =>
    api
      .post<AuthResponse | { pending: true; message: string }>("/api/register", body)
      .then((r) => r.data),
};

export const session = {
  me: () => api.get<MeResponse>("/api/me").then((r) => r.data),
  health: () => api.get("/api/health").then((r) => r.data),
  /** Push the full local snapshot blob (server stores it + updates aggregates). */
  sync: (snapshot: Record<string, unknown>) =>
    api.post("/api/sync", snapshot).then((r) => r.data),
};

export const board = {
  leaderboard: () =>
    api.get<LeaderboardEntry[] | { leaderboard: LeaderboardEntry[] }>("/api/leaderboard").then(
      (r) => (Array.isArray(r.data) ? r.data : r.data.leaderboard ?? [])
    ),
  profile: (username: string) =>
    api.get(`/api/profile/${encodeURIComponent(username)}`).then((r) => r.data),
};

export const ai = {
  chat: (messages: ChatMessage[], context: ChatContext, provider: AIProvider) =>
    api
      .post<{ reply: string }>("/api/chat", { messages, context, provider })
      .then((r) => r.data.reply),

  skillFeedback: (body: {
    provider: AIProvider;
    model?: string;
    focusArea: string;
    notes?: string;
    history?: unknown[];
    stats?: unknown;
  }) => api.post<{ feedback: string }>("/api/skill-feedback", body).then((r) => r.data.feedback),

  generatePrompts: (
    provider: AIProvider,
    opts?: { region?: string; seasonalPrompts?: boolean }
  ) =>
    api
      .post<{ prompts: GeneratedPrompt[] }>("/api/generate-prompts", {
        provider,
        region: opts?.region && opts.region !== "Global" ? opts.region : "",
        seasonalPrompts: opts?.seasonalPrompts ?? false,
      })
      .then((r) => r.data.prompts ?? []),
};

export const community = {
  updates: () => api.get("/api/updates").then((r) => r.data),
  postPrompt: (text: string, category: string) =>
    api.post("/api/community-prompt", { text, category }).then((r) => r.data),
  getSuggestions: () =>
    api
      .get<{ suggestions: Suggestion[] }>("/api/suggestions")
      .then((r) => r.data.suggestions ?? []),
  postSuggestion: (text: string) =>
    api.post("/api/suggestions", { text }).then((r) => r.data),
};
