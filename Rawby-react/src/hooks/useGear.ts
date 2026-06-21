// Owned-gear inventory, stored in the snapshot blob (synced to server).
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { patchSnapshot, newId } from "../lib/snapshotPatch";
import { toast } from "../store/toast";
import { useMe } from "./queries";
import type { GearItem } from "../types";

export function useGear() {
  const qc = useQueryClient();
  const { data } = useMe();
  const gear: GearItem[] = data?.snapshot?.gear ?? [];

  const add = useMutation({
    mutationFn: (g: { name: string; category: string }) =>
      patchSnapshot(qc, (s) => ({
        ...s,
        gear: [...(s.gear ?? []), { id: newId(), name: g.name.trim(), category: g.category }],
      })),
    onSuccess: () => toast.success("Gear added"),
    onError: () => toast.error("Couldn't save gear"),
  });

  const remove = useMutation({
    mutationFn: (id: string) =>
      patchSnapshot(qc, (s) => ({ ...s, gear: (s.gear ?? []).filter((x) => x.id !== id) })),
  });

  return { gear, add, remove };
}
