import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Modal } from "./ui/Modal";
import { GradientButton } from "./ui/GradientButton";
import { Icon } from "./ui/Icon";
import { LEVELS, LATE_MULTIPLIERS } from "../lib/constants";
import { useSubmitFilm, computeScore } from "../hooks/useSubmitFilm";

interface Props {
  open: boolean;
  onClose: () => void;
  defaultLevel?: string;
}

const fieldCls =
  "w-full rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none transition-colors placeholder:text-text-dim/60 focus:border-cinema-500/70";

// Auto late-penalty from the submit time. Deadline = Friday; Mon–Fri is the
// filming window (on time), weekend after slips the multiplier.
function computeAutoLate() {
  const day = new Date().getDay(); // 0 Sun … 6 Sat
  const idx = day === 6 ? 1 : day === 0 ? 2 : 0;
  return { idx, ...LATE_MULTIPLIERS[idx] };
}

export function SubmitFilmModal({ open, onClose, defaultLevel = "Short Story" }: Props) {
  const [title, setTitle] = useState("");
  const [link, setLink] = useState("");
  const [level, setLevel] = useState(defaultLevel);
  const [lateIdx, setLateIdx] = useState(0);
  const submit = useSubmitFilm();

  // Reset when (re)opened.
  useEffect(() => {
    if (open) {
      setTitle("");
      setLink("");
      setLevel(defaultLevel);
      setLateIdx(computeAutoLate().idx);
      submit.reset();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, defaultLevel]);

  const score = computeScore(level, lateIdx);

  return (
    <Modal open={open} onClose={onClose} title="Submit film">
      {submit.isSuccess ? (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex flex-col items-center gap-3 py-6 text-center"
        >
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-success/15 text-success">
            <Icon name="check" size={28} />
          </div>
          <div className="h-display text-2xl font-bold text-text-hi">
            +{submit.data?.project.score} pts
          </div>
          <p className="text-sm text-text-dim">
            “{submit.data?.project.title}” logged. Nice work.
          </p>
          <GradientButton onClick={onClose} className="mt-2 w-full">
            Done
          </GradientButton>
        </motion.div>
      ) : (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            if (title.trim()) submit.mutate({ title, link, level, lateIdx });
          }}
          className="space-y-4"
        >
          <div>
            <label htmlFor="film-title" className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-text-dim">
              Film title
            </label>
            <input
              id="film-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. The Last Reel"
              className={fieldCls}
              required
              autoFocus
            />
          </div>

          <div>
            <label htmlFor="film-link" className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-text-dim">
              Link <span className="normal-case text-text-dim/70">(optional)</span>
            </label>
            <input
              id="film-link"
              type="url"
              value={link}
              onChange={(e) => setLink(e.target.value)}
              placeholder="https://…"
              className={fieldCls}
            />
          </div>

          <div>
            <label htmlFor="film-level" className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-text-dim">
              Level
            </label>
            <select
              id="film-level"
              value={level}
              onChange={(e) => setLevel(e.target.value)}
              className={fieldCls}
            >
              {LEVELS.map((l) => (
                <option key={l.name} value={l.name} className="bg-ink-card">
                  {l.name} · {l.points}
                </option>
              ))}
            </select>
          </div>

          {/* Submit time + penalty are tracked automatically */}
          <div className="flex items-center justify-between rounded-xl border border-hairline bg-chip px-4 py-3">
            <span className="inline-flex items-center gap-2 text-sm text-text-dim">
              <Icon name="clock" size={15} />
              Submitted now · {LATE_MULTIPLIERS[lateIdx].day}
            </span>
            <span className="text-sm font-semibold text-text-hi">×{LATE_MULTIPLIERS[lateIdx].mult}</span>
          </div>

          {/* Live score preview */}
          <div className="flex items-center justify-between rounded-xl border border-cinema-500/30 bg-cinema-500/[0.08] px-4 py-3">
            <span className="text-sm font-medium text-text-dim">Score this earns</span>
            <span className="h-display text-2xl font-bold text-cinema-400 tabular-nums">
              {score} pts
            </span>
          </div>

          {submit.isError && (
            <div className="rounded-lg border border-danger/30 bg-danger/10 px-3 py-2 text-sm text-danger">
              Couldn’t submit — the server may be waking. Try again.
            </div>
          )}

          <GradientButton type="submit" loading={submit.isPending} disabled={!title.trim()} className="w-full">
            Submit film
          </GradientButton>
        </form>
      )}
    </Modal>
  );
}
