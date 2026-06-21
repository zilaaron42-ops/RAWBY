// ============================================================
// RAWBY — weekly prompt generation + selection.
// Generate (POST /api/generate-prompts) returns 3 prompts; picking
// one writes it into the snapshot (promptText/level) and spends a
// regen, pushed via /api/sync. Local-first, like the Flutter app.
// ============================================================
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { ai, session } from "../lib/endpoints";
import { useAuth } from "../store/auth";
import { useSettings } from "../store/settings";
import { toast } from "../store/toast";
import type { GeneratedPrompt, MeResponse, Snapshot } from "../types";

export function useGeneratePrompts() {
  const provider = useAuth((s) => s.aiProvider);
  const region = useSettings((s) => s.region);
  const seasonalPrompts = useSettings((s) => s.seasonalPrompts);
  return useMutation({
    mutationFn: () => ai.generatePrompts(provider, { region, seasonalPrompts }),
    onError: () => toast.error("Couldn't generate prompts — the server may be waking."),
  });
}

export function useSetActivePrompt() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (p: GeneratedPrompt) => {
      const me = qc.getQueryData<MeResponse>(["me"]);
      const snap: Snapshot = me?.snapshot ?? {};
      const next: Snapshot = {
        ...snap,
        promptText: p.text,
        promptLevel: p.level,
        regensLeft: Math.max(0, (snap.regensLeft ?? 3) - 1),
      };
      await session.sync(next as Record<string, unknown>);
      return next;
    },
    onSuccess: (next) => {
      qc.setQueryData<MeResponse>(["me"], (old) =>
        old ? { ...old, snapshot: next } : old
      );
      qc.invalidateQueries({ queryKey: ["me"] });
      toast.success("Prompt locked in for this week.");
    },
    onError: () => toast.error("Couldn't set the prompt. Try again."),
  });
}
