// ============================================================
// RAWBY — auth + session store (Zustand, persisted to localStorage)
// ============================================================
import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { User, AIProvider } from "../types";

interface AuthState {
  token: string | null;
  user: User | null;
  /** AI provider toggle — default groq (free). */
  aiProvider: AIProvider;
  setAuth: (token: string, user: User) => void;
  setUser: (user: User) => void;
  setProvider: (p: AIProvider) => void;
  logout: () => void;
  isAuthed: () => boolean;
}

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      user: null,
      aiProvider: "groq",
      setAuth: (token, user) => set({ token, user }),
      setUser: (user) => set({ user }),
      setProvider: (aiProvider) => set({ aiProvider }),
      logout: () => set({ token: null, user: null }),
      isAuthed: () => !!get().token,
    }),
    { name: "rawby-auth" }
  )
);

/** Non-hook accessor for the axios interceptor. */
export const getToken = () => useAuth.getState().token;
export const forceLogout = () => useAuth.getState().logout();
