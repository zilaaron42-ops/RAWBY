// Owned-gear inventory + status (active / rested / retired). Stored in the
// snapshot blob. Auto-rests gear unused in the last 10 projects and nudges
// to retire items that have been rested a long time.
import { useEffect, useRef } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { patchSnapshot, newId } from "../lib/snapshotPatch";
import { toast } from "../store/toast";
import { useMe } from "./queries";
import type { GearItem, GearStatus } from "../types";

const RECENT = 10; // projects window for "unused"
const RETIRE_DAYS = 21; // rested longer than this → suggest retiring

export function useGear() {
  const qc = useQueryClient();
  const { data } = useMe();
  const gear: GearItem[] = data?.snapshot?.gear ?? [];

  const add = useMutation({
    mutationFn: (g: { brand: string; type: string; category: string }) =>
      patchSnapshot(qc, (s) => ({
        ...s,
        gear: [
          ...(s.gear ?? []),
          { id: newId(), brand: g.brand.trim(), type: g.type.trim(), category: g.category, status: "active" },
        ],
      })),
    onSuccess: () => toast.success("Gear added"),
    onError: () => toast.error("Couldn't save gear"),
  });

  const remove = useMutation({
    mutationFn: (id: string) =>
      patchSnapshot(qc, (s) => ({ ...s, gear: (s.gear ?? []).filter((x) => x.id !== id) })),
  });

  const setStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: GearStatus }) =>
      patchSnapshot(qc, (s) => ({
        ...s,
        gear: (s.gear ?? []).map((g) =>
          g.id === id
            ? { ...g, status, restedAt: status === "rested" ? new Date().toISOString() : g.restedAt }
            : g
        ),
      })),
  });

  return { gear, add, remove, setStatus };
}

/** Runs once per mount: rests gear not used in the last 10 projects + nudges
 *  to retire long-rested items. Mount this on the Gear page. */
export function useGearAutoManage() {
  const qc = useQueryClient();
  const { data } = useMe();
  const ran = useRef(false);

  useEffect(() => {
    if (ran.current || !data) return;
    const snap = data.snapshot;
    const gear = snap?.gear ?? [];
    const history = snap?.history ?? [];
    if (gear.length === 0) return;

    const usedRecently = new Set(history.slice(0, RECENT).flatMap((h) => h.gear ?? []));

    // Auto-rest: active, owned through ≥10 projects, not used in the last 10.
    const toRest =
      history.length >= RECENT
        ? gear.filter((g) => (g.status ?? "active") === "active" && !usedRecently.has(g.id))
        : [];

    // Suggest retiring: rested longer than RETIRE_DAYS.
    const now = Date.now();
    const toRetire = gear.filter(
      (g) => g.status === "rested" && g.restedAt && now - new Date(g.restedAt).getTime() > RETIRE_DAYS * 86_400_000
    );

    if (toRest.length === 0 && toRetire.length === 0) return;
    ran.current = true;

    if (toRest.length > 0) {
      const ids = new Set(toRest.map((g) => g.id));
      patchSnapshot(qc, (s) => ({
        ...s,
        gear: (s.gear ?? []).map((g) =>
          ids.has(g.id) ? { ...g, status: "rested" as GearStatus, restedAt: new Date().toISOString() } : g
        ),
      })).then(() =>
        toast.info(`Rested ${toRest.length} unused gear item${toRest.length > 1 ? "s" : ""} — review below.`)
      );
    }
    if (toRetire.length > 0) {
      toast.info(`${toRetire.length} rested item${toRetire.length > 1 ? "s" : ""} unused a while — retire?`);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data]);
}
