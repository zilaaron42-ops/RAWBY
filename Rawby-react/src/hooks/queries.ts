// ============================================================
// RAWBY — shared TanStack Query hooks.
// ============================================================
import { useQuery } from "@tanstack/react-query";
import { session, board, community } from "../lib/endpoints";
import { useAuth } from "../store/auth";

export function useMe() {
  const authed = useAuth((s) => !!s.token);
  return useQuery({
    queryKey: ["me"],
    queryFn: session.me,
    enabled: authed,
  });
}

export function useLeaderboard() {
  const authed = useAuth((s) => !!s.token);
  return useQuery({
    queryKey: ["leaderboard"],
    queryFn: board.leaderboard,
    enabled: authed,
  });
}

export function useSuggestions() {
  const authed = useAuth((s) => !!s.token);
  return useQuery({
    queryKey: ["suggestions"],
    queryFn: community.getSuggestions,
    enabled: authed,
  });
}
