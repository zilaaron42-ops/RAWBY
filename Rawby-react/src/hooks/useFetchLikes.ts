// Fetch a project's reel likes and fold them into its score:
// score = base(points·lateMult) + likes·levelWeight·lateMult.
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { instagram } from "../lib/endpoints";
import { patchSnapshot, recalcTotal } from "../lib/snapshotPatch";
import { computeScore } from "./useSubmitFilm";
import { likesBonus, LATE_MULTIPLIERS } from "../lib/constants";
import { toast } from "../store/toast";
import type { ProjectHistoryItem } from "../types";

function extractLikes(d: Record<string, unknown>): number {
  const data = (d.data ?? d) as Record<string, unknown>;
  const cand = data.likes ?? data.like_count ?? data.count ?? data.likeCount;
  const n = Number(cand);
  return Number.isFinite(n) ? n : 0;
}

export function useFetchLikes() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (project: ProjectHistoryItem) => {
      if (!project.link) throw new Error("no link");
      const raw = await instagram.fetchReelLikes(project.link);
      const likes = extractLikes(raw);
      await patchSnapshot(qc, (s) => {
        const history = (s.history ?? []).map((h) => {
          if (h.id !== project.id) return h;
          const lateMult = LATE_MULTIPLIERS[h.lateIdx ?? 0]?.mult ?? 1;
          const base = computeScore(h.level, h.lateIdx ?? 0);
          return { ...h, likes, score: base + likesBonus(h.level, likes, lateMult) };
        });
        return { ...s, history, totalScore: recalcTotal(history) };
      });
      return likes;
    },
    onSuccess: (likes) => toast.success(`${likes} likes — score updated`),
    onError: () => toast.error("Couldn't fetch likes — needs a valid reel link"),
  });
}
