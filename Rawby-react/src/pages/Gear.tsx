import { useState } from "react";
import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader, EmptyState } from "../components/ui/Bits";
import { Icon, type IconName } from "../components/ui/Icon";
import { stagger, item } from "../lib/motion";
import { GEAR_CATEGORIES } from "../lib/constants";
import { useGear } from "../hooks/useGear";

const CAT_ICON: Record<string, IconName> = {
  Camera: "camera",
  Lens: "aperture",
  Audio: "mic",
  Lighting: "sun",
  Support: "aperture",
  Accessory: "plus",
  Other: "film",
};

const TIPS: { cat: string; icon: IconName; accent: string; items: string[] }[] = [
  { cat: "Camera", icon: "camera", accent: "#E8B647", items: ["Lock exposure + white balance", "Shoot 24fps for cinematic motion"] },
  { cat: "Audio", icon: "mic", accent: "#6FA373", items: ["Record room tone", "Mic close to the source"] },
  { cat: "Light", icon: "sun", accent: "#FBBF24", items: ["One key + bounce fill", "Golden hour is free"] },
  { cat: "Grade", icon: "palette", accent: "#E85D75", items: ["Set black + white points", "Keep skin natural"] },
];

export default function Gear() {
  const { gear, add, remove } = useGear();
  const [name, setName] = useState("");
  const [category, setCategory] = useState<string>(GEAR_CATEGORIES[0]);

  const byCat = GEAR_CATEGORIES.map((c) => ({ cat: c, items: gear.filter((g) => g.category === c) })).filter(
    (g) => g.items.length
  );

  function submit() {
    if (!name.trim()) return;
    add.mutate({ name, category }, { onSuccess: () => setName("") });
  }

  return (
    <PageTransition>
      <PageHeader eyebrow="Toolkit" title="My gear" sub="Track what you own, tag what you used." />

      {/* Add gear */}
      <GlassCard className="mb-6">
        <div className="flex flex-col gap-3 sm:flex-row">
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && submit()}
            placeholder="e.g. Sony A7 IV, 35mm f/1.8, Rode VideoMic…"
            className="flex-1 rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none placeholder:text-text-dim/60 focus:border-cinema-500/70"
          />
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="rounded-xl border border-hairline bg-field px-3 py-3 text-sm text-text-hi outline-none focus:border-cinema-500/70"
          >
            {GEAR_CATEGORIES.map((c) => (
              <option key={c} value={c} className="bg-ink-card">{c}</option>
            ))}
          </select>
          <GradientButton onClick={submit} loading={add.isPending} disabled={!name.trim()}>
            <Icon name="plus" size={16} /> Add
          </GradientButton>
        </div>
      </GlassCard>

      {/* Inventory */}
      {gear.length === 0 ? (
        <EmptyState icon="aperture" title="No gear yet" sub="Add your kit above — you can then tag it on each film." />
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
                    <GlassCard className="flex items-center justify-between py-3">
                      <span className="text-sm text-text-hi">{g.name}</span>
                      <button
                        onClick={() => remove.mutate(g.id)}
                        aria-label={`Remove ${g.name}`}
                        className="text-text-dim transition-colors hover:text-danger"
                      >
                        <Icon name="plus" size={16} className="rotate-45" />
                      </button>
                    </GlassCard>
                  </motion.div>
                ))}
              </motion.div>
            </div>
          ))}
        </div>
      )}

      {/* Craft notes */}
      <h3 className="h-display mb-3 mt-10 text-lg font-bold text-text-hi">Craft notes</h3>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {TIPS.map((t) => (
          <GlassCard key={t.cat} className="h-full">
            <div className="mb-3 flex items-center gap-2">
              <span className="flex h-9 w-9 items-center justify-center rounded-xl" style={{ background: `${t.accent}1f`, color: t.accent }}>
                <Icon name={t.icon} size={18} />
              </span>
              <h4 className="text-sm font-semibold text-text-hi">{t.cat}</h4>
            </div>
            <ul className="space-y-2">
              {t.items.map((it) => (
                <li key={it} className="flex gap-2 text-xs leading-relaxed text-text-dim">
                  <span className="mt-1 h-1 w-1 shrink-0 rounded-full" style={{ background: t.accent }} />
                  {it}
                </li>
              ))}
            </ul>
          </GlassCard>
        ))}
      </div>
    </PageTransition>
  );
}
