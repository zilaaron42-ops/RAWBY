import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader, EmptyState } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { Skeleton } from "../components/ui/Skeleton";
import { stagger, item } from "../lib/motion";
import { community } from "../lib/endpoints";
import { useSuggestions } from "../hooks/queries";

const SEED = [
  "A conversation told entirely through reflections.",
  "Someone returns an object they should have kept.",
  "The last five minutes before a place closes forever.",
  "A character who only appears in the background — until they don't.",
];

export default function IdeaBank() {
  const { data, isLoading } = useSuggestions();
  const qc = useQueryClient();
  const [text, setText] = useState("");

  const post = useMutation({
    mutationFn: (t: string) => community.postSuggestion(t),
    onSuccess: () => {
      setText("");
      qc.invalidateQueries({ queryKey: ["suggestions"] });
    },
  });

  const ideas = (data?.length ? data.map((s) => s.text) : SEED).slice(0, 24);
  const submit = () => text.trim() && post.mutate(text.trim());

  return (
    <PageTransition>
      <PageHeader
        eyebrow="Inspiration"
        title="Idea bank"
        sub="Community story sparks. Drop one, borrow one."
      />

      <GlassCard className="mb-6">
        <div className="flex flex-col gap-3 sm:flex-row">
          <label htmlFor="idea-input" className="sr-only">
            Share a story spark
          </label>
          <input
            id="idea-input"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && submit()}
            placeholder="Share a story spark…"
            className="flex-1 rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none transition-colors placeholder:text-text-dim/60 focus:border-cinema-500/70"
          />
          <GradientButton onClick={submit} loading={post.isPending} disabled={!text.trim()}>
            <Icon name="plus" size={16} /> Add idea
          </GradientButton>
        </div>
      </GlassCard>

      {isLoading ? (
        <div className="columns-1 gap-4 sm:columns-2 lg:columns-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="mb-4 h-24 w-full" />
          ))}
        </div>
      ) : ideas.length === 0 ? (
        <EmptyState icon="bulb" title="No ideas yet" sub="Be the first to drop a spark." />
      ) : (
        <motion.div
          variants={stagger}
          initial="hidden"
          animate="show"
          className="columns-1 gap-4 sm:columns-2 lg:columns-3"
        >
          <AnimatePresence>
            {ideas.map((idea, i) => (
              <motion.div key={idea + i} variants={item} className="mb-4 break-inside-avoid">
                <GlassCard interactive>
                  <Icon name="quote" size={18} className="mb-2 text-cinema-500" />
                  <p className="text-sm leading-relaxed text-text-hi">{idea}</p>
                </GlassCard>
              </motion.div>
            ))}
          </AnimatePresence>
        </motion.div>
      )}
    </PageTransition>
  );
}
