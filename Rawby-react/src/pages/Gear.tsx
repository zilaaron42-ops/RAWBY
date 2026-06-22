import { useState } from "react";
import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader, EmptyState } from "../components/ui/Bits";
import { Icon, type IconName } from "../components/ui/Icon";
import { stagger, item } from "../lib/motion";
import { GEAR_CATEGORIES } from "../lib/constants";
import { useGear, useGearAutoManage } from "../hooks/useGear";
import { useMe } from "../hooks/queries";
import type { GearItem, ProjectHistoryItem } from "../types";

const CAT_ICON: Record<string, IconName> = {
  Filming: "camera",
  Editing: "scissors",
  Digital: "aperture",
};

const fieldCls =
  "rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none placeholder:text-text-dim/60 focus:border-cinema-500/70";

const label = (g: GearItem) => [g.brand, g.type].filter(Boolean).join(" ");

export default function Gear() {
  const { gear, add, remove, setStatus } = useGear();
  const { data } = useMe();
  useGearAutoManage();
  const history: ProjectHistoryItem[] = data?.snapshot?.history ?? data?.history ?? [];
  const usage = (id: string) => history.filter((h) => h.gear?.includes(id)).length;
  const [brand, setBrand] = useState("");
  const [type, setType] = useState("");
  const [category, setCategory] = useState<string>(GEAR_CATEGORIES[0]);

  const active = gear.filter((g) => (g.status ?? "active") === "active");
  const rested = gear.filter((g) => g.status === "rested");
  const retired = gear.filter((g) => g.status === "retired");
  const byCat = GEAR_CATEGORIES.map((c) => ({ cat: c, items: active.filter((g) => g.category === c) })).filter(
    (g) => g.items.length
  );

  function submit() {
    if (!brand.trim() && !type.trim()) return;
    add.mutate({ brand, type, category }, { onSuccess: () => { setBrand(""); setType(""); } });
  }

  return (
    <PageTransition>
      <PageHeader eyebrow="Toolkit" title="My gear" sub="Track what you own, tag what you used. Idle kit auto-rests." />

      <GlassCard className="mb-6">
        <div className="grid gap-3 sm:grid-cols-[1fr_1.3fr_auto_auto]">
          <input value={brand} onChange={(e) => setBrand(e.target.value)} onKeyDown={(e) => e.key === "Enter" && submit()} placeholder="Brand (e.g. Sony)" className={fieldCls} />
          <input value={type} onChange={(e) => setType(e.target.value)} onKeyDown={(e) => e.key === "Enter" && submit()} placeholder="Type (e.g. A7 IV, 35mm lens)" className={fieldCls} />
          <select value={category} onChange={(e) => setCategory(e.target.value)} className={fieldCls}>
            {GEAR_CATEGORIES.map((c) => (
              <option key={c} value={c} className="bg-ink-card">{c}</option>
            ))}
          </select>
          <GradientButton onClick={submit} loading={add.isPending} disabled={!brand.trim() && !type.trim()}>
            <Icon name="plus" size={16} /> Add
          </GradientButton>
        </div>
      </GlassCard>

      {gear.length === 0 ? (
        <EmptyState icon="aperture" title="No gear yet" sub="Add your kit above — then tag it on each film." />
      ) : (
        <div className="space-y-6">
          {byCat.map((group) => (
            <div key={group.cat}>
              <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-text-hi">
                <Icon name={CAT_ICON[group.cat] ?? "film"} size={16} className="text-cinema-400" />
                {group.cat}
                <span className="text-xs font-normal text-text-dim">({group.items.length})</span>
              </div>
              <motion.div variants={stagger} initial="hidden" animate="show" className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {group.items.map((g) => (
                  <motion.div key={g.id} variants={item}>
                    <GlassCard className="flex items-center justify-between gap-2 py-3">
                      <div className="min-w-0">
                        <div className="truncate text-sm text-text-hi">
                          {g.brand && <span className="font-semibold">{g.brand}</span>}
                          {g.brand && g.type ? " " : ""}
                          <span className="text-text-dim">{g.type}</span>
                        </div>
                        <div className="text-[11px] text-text-dim">used {usage(g.id)}× in projects</div>
                      </div>
                      <div className="flex shrink-0 items-center gap-1">
                        <button onClick={() => setStatus.mutate({ id: g.id, status: "rested" })} className="rounded-md px-2 py-1 text-[11px] text-text-dim transition-colors hover:bg-chip hover:text-text-hi" title="Rest this item">
                          Rest
                        </button>
                        <button onClick={() => remove.mutate(g.id)} aria-label="Remove gear" className="text-text-dim transition-colors hover:text-danger">
                          <Icon name="plus" size={16} className="rotate-45" />
                        </button>
                      </div>
                    </GlassCard>
                  </motion.div>
                ))}
              </motion.div>
            </div>
          ))}

          {active.length === 0 && (
            <p className="text-sm text-text-dim">All your gear is rested or retired.</p>
          )}

          {/* Rested */}
          {rested.length > 0 && (
            <div>
              <div className="mb-2 text-sm font-semibold text-text-dim">Rested ({rested.length})</div>
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {rested.map((g) => (
                  <GlassCard key={g.id} className="flex items-center justify-between gap-2 py-3 opacity-80">
                    <span className="truncate text-sm text-text-dim">{label(g)}</span>
                    <div className="flex shrink-0 items-center gap-1 text-[11px]">
                      <button onClick={() => setStatus.mutate({ id: g.id, status: "active" })} className="rounded-md px-2 py-1 text-cinema-400 hover:bg-chip">Reactivate</button>
                      <button onClick={() => setStatus.mutate({ id: g.id, status: "retired" })} className="rounded-md px-2 py-1 text-text-dim hover:bg-chip hover:text-text-hi">Retire</button>
                    </div>
                  </GlassCard>
                ))}
              </div>
            </div>
          )}

          {/* Retired */}
          {retired.length > 0 && (
            <div>
              <div className="mb-2 text-sm font-semibold text-text-dim">Retired ({retired.length})</div>
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {retired.map((g) => (
                  <GlassCard key={g.id} className="flex items-center justify-between gap-2 py-3 opacity-60">
                    <span className="truncate text-sm text-text-dim line-through">{label(g)}</span>
                    <div className="flex shrink-0 items-center gap-1 text-[11px]">
                      <button onClick={() => setStatus.mutate({ id: g.id, status: "active" })} className="rounded-md px-2 py-1 text-cinema-400 hover:bg-chip">Restore</button>
                      <button onClick={() => remove.mutate(g.id)} className="rounded-md px-2 py-1 text-text-dim hover:text-danger">Delete</button>
                    </div>
                  </GlassCard>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </PageTransition>
  );
}
