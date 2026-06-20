import { motion } from "framer-motion";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { PageHeader } from "../components/ui/Bits";
import { Icon, type IconName } from "../components/ui/Icon";
import { stagger, item } from "../lib/motion";

const GEAR: { cat: string; icon: IconName; accent: string; items: string[] }[] = [
  { cat: "Camera", icon: "camera", accent: "#E8B647", items: ["Any phone or mirrorless", "Lock exposure + white balance", "Shoot 24fps for cinematic motion"] },
  { cat: "Audio", icon: "mic", accent: "#6FA373", items: ["Record room tone", "Lav or shotgun close to source", "Monitor with headphones"] },
  { cat: "Light", icon: "sun", accent: "#FBBF24", items: ["One key + bounce fill", "Motivate practicals", "Golden hour is free"] },
  { cat: "Edit", icon: "scissors", accent: "#3B82F6", items: ["Cut on motion", "J/L cuts for flow", "Match cuts on action"] },
  { cat: "Grade", icon: "palette", accent: "#E85D75", items: ["Set black + white points", "Split-tone shadows/highlights", "Keep skin natural"] },
  { cat: "Sound", icon: "volume", accent: "#A78BFA", items: ["Layer SFX for depth", "Sidechain music under VO", "−14 LUFS for web"] },
];

export default function Gear() {
  return (
    <PageTransition>
      <PageHeader
        eyebrow="Toolkit"
        title="Gear & craft"
        sub="Field notes for shooting solo. Small kit, big intention."
      />
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3"
      >
        {GEAR.map((g) => (
          <motion.div key={g.cat} variants={item}>
            <GlassCard interactive className="h-full">
              <div className="mb-4 flex items-center gap-3">
                <span
                  className="flex h-10 w-10 items-center justify-center rounded-xl"
                  style={{ background: `${g.accent}1f`, color: g.accent }}
                >
                  <Icon name={g.icon} size={20} />
                </span>
                <h3 className="h-display text-lg font-bold text-text-hi">{g.cat}</h3>
              </div>
              <ul className="space-y-2.5">
                {g.items.map((it) => (
                  <li key={it} className="flex gap-2.5 text-sm leading-relaxed text-text-dim">
                    <span
                      className="mt-[7px] h-1.5 w-1.5 shrink-0 rounded-full"
                      style={{ background: g.accent }}
                    />
                    {it}
                  </li>
                ))}
              </ul>
            </GlassCard>
          </motion.div>
        ))}
      </motion.div>
    </PageTransition>
  );
}
