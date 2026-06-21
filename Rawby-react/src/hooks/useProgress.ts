// Per-project phase checklist (tick the weekly production phases).
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { patchSnapshot } from "../lib/snapshotPatch";
import { useMe } from "./queries";

export function useProgress() {
  const qc = useQueryClient();
  const { data } = useMe();
  const done: string[] = data?.snapshot?.phaseDone ?? [];

  const toggle = useMutation({
    mutationFn: (phase: string) =>
      patchSnapshot(qc, (s) => {
        const set = new Set(s.phaseDone ?? []);
        if (set.has(phase)) set.delete(phase);
        else set.add(phase);
        return { ...s, phaseDone: [...set] };
      }),
  });

  return { done, toggle };
}
