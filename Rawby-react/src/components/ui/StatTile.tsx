import { motion } from "framer-motion";
import { Icon, type IconName } from "./Icon";
import { item } from "../../lib/motion";

interface Props {
  icon: IconName;
  value: React.ReactNode;
  label: string;
  accent?: string;
}

export function StatTile({ icon, value, label, accent = "#E8B647" }: Props) {
  return (
    <motion.div variants={item} className="glass flex flex-col gap-3 p-4">
      <div
        className="flex h-9 w-9 items-center justify-center rounded-lg"
        style={{ background: `${accent}1f`, color: accent }}
      >
        <Icon name={icon} size={18} />
      </div>
      <div className="h-display text-[1.75rem] font-bold leading-none text-text-hi tabular-nums">
        {value}
      </div>
      <div className="text-[0.7rem] font-semibold uppercase tracking-[0.14em] text-text-dim">
        {label}
      </div>
    </motion.div>
  );
}
