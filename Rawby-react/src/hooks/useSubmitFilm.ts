// ============================================================
// RAWBY — submit a film. Mirrors the Flutter local-first model:
// compute the score, merge into the existing snapshot (so phone
// data isn't clobbered), push via /api/sync, update cache optimistically.
// ============================================================
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { session } from "../lib/endpoints";
import { recalcTotal, newId } from "../lib/snapshotPatch";
import { toast } from "../store/toast";
import { LEVELS, LATE_MULTIPLIERS } from "../lib/constants";
import type { MeResponse, ProjectHistoryItem, Snapshot } from "../types";

export interface SubmitInput {
  title: string;
  link?: string;
  level: string;
  lateIdx: number; // index into LATE_MULTIPLIERS
  gear?: string[]; // gear item ids used
  categories?: string[]; // video taxonomy ids
}

export function computeScore(level: string, lateIdx: number): number {
  const base = LEVELS.find((l) => l.name === level)?.points ?? 0;
  const mult = LATE_MULTIPLIERS[lateIdx]?.mult ?? 1;
  return Math.round(base * mult);
}

export function useSubmitFilm() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (input: SubmitInput) => {
      const me = qc.getQueryData<MeResponse>(["me"]);
      const snap: Snapshot = me?.snapshot ?? {};
      const prevHistory: ProjectHistoryItem[] = snap.history ?? me?.history ?? [];
      const score = computeScore(input.level, input.lateIdx);

      const now = new Date();
      const project: ProjectHistoryItem = {
        id: newId(),
        title: input.title.trim(),
        link: input.link?.trim() || undefined,
        level: input.level,
        score,
        date: now.toISOString().slice(0, 10),
        submittedAt: now.toISOString(), // auto-tracked submit time
        lateIdx: input.lateIdx,
        gear: input.gear?.length ? input.gear : undefined,
        categories: input.categories?.length ? input.categories : undefined,
        week: snap.weekNumber,
      };

      // Merge — keep every existing snapshot field intact.
      const history = [project, ...prevHistory];
      const nextSnapshot: Snapshot = {
        ...snap,
        history,
        totalScore: recalcTotal(history),
        streak: (snap.streak ?? 0) + 1,
      };

      await session.sync(nextSnapshot as Record<string, unknown>);
      return { nextSnapshot, project };
    },
    onSuccess: ({ nextSnapshot }) => {
      qc.setQueryData<MeResponse>(["me"], (old) =>
        old
          ? { ...old, snapshot: nextSnapshot, history: nextSnapshot.history }
          : ({ user: { username: "", displayName: "" }, snapshot: nextSnapshot } as MeResponse)
      );
      qc.invalidateQueries({ queryKey: ["me"] });
      qc.invalidateQueries({ queryKey: ["leaderboard"] });
    },
    onError: () => toast.error("Couldn't submit your film — the server may be waking."),
  });
}
