// ============================================================
// Merge a partial change into the cached snapshot, push it via
// /api/sync, and update the React Query cache optimistically.
// Single path for gear / likes / progress / submit mutations so
// they never clobber other snapshot fields.
// ============================================================
import type { QueryClient } from "@tanstack/react-query";
import { session } from "./endpoints";
import type { MeResponse, Snapshot } from "../types";

export async function patchSnapshot(
  qc: QueryClient,
  patch: (snap: Snapshot) => Snapshot
): Promise<Snapshot> {
  const me = qc.getQueryData<MeResponse>(["me"]);
  const snap: Snapshot = me?.snapshot ?? {};
  const next = patch(snap);
  await session.sync(next as Record<string, unknown>);
  qc.setQueryData<MeResponse>(["me"], (old) =>
    old
      ? { ...old, snapshot: next }
      : ({ user: { username: "", displayName: "" }, snapshot: next } as MeResponse)
  );
  return next;
}

export function newId() {
  return globalThis.crypto?.randomUUID?.() ?? `id_${Date.now()}_${Math.random().toString(36).slice(2)}`;
}

/** Total score = sum of every project's score (single source of truth). */
export function recalcTotal(history: { score?: number }[]): number {
  return history.reduce((sum, h) => sum + (h.score ?? 0), 0);
}
