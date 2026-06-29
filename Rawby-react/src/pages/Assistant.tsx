import { useRef, useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useMutation } from "@tanstack/react-query";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { PlanTripModal } from "../components/PlanTripModal";
import { PrePostCheckModal } from "../components/PrePostCheckModal";
import { ai } from "../lib/endpoints";
import { useMe } from "../hooks/queries";
import { useNote, useAurora } from "../hooks/usePersonal";
import { useTrips } from "../hooks/useTrips";
import { gearLabels, filmSummaries, tripSummaries } from "../lib/personalize";
import { useAuth } from "../store/auth";
import { useSettings } from "../store/settings";
import { toast } from "../store/toast";
import type { ChatMessage, ChatContext } from "../types";

const GREETING: ChatMessage = {
  role: "assistant",
  content:
    "Hey — I'm Aurora. I shoot, cut and grade solo too, so ask me anything specific: camera settings for a shot, a shot list for your prompt, how to film yourself with no crew, an edit or colour fix, or a Reel hook that lands. The more detail you give (gear, location, what's not working), the sharper I am.",
};

// Quick-start questions to seed a useful conversation.
const STARTERS = [
  "Give me a 5-shot list for this week's prompt.",
  "Best camera settings to shoot myself alone, no crew?",
  "My footage looks flat — how do I grade it?",
  "Write 3 Reel hooks for this film.",
];

export default function Assistant() {
  const { data } = useMe();
  const user = useAuth((s) => s.user);

  const { note, save: saveNote } = useNote();
  const { thread, saveThread } = useAurora();
  const { trips } = useTrips();
  const useClaude = useSettings((s) => s.useClaude);
  const [noteDraft, setNoteDraft] = useState(note);
  const [messages, setMessages] = useState<ChatMessage[]>([GREETING]);
  const [input, setInput] = useState("");
  const [planOpen, setPlanOpen] = useState(false);
  const [checkOpen, setCheckOpen] = useState(false);
  const hydrated = useRef(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  // Aurora remembers: hydrate the thread from the snapshot once on load.
  useEffect(() => {
    if (hydrated.current || !data?.snapshot) return;
    hydrated.current = true;
    if (thread.length) setMessages(thread);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data?.snapshot]);

  const snap = data?.snapshot;
  const context: ChatContext = {
    displayName: user?.displayName,
    rank: snap?.rank,
    totalScore: snap?.totalScore,
    streak: snap?.streak,
    regensLeft: snap?.regensLeft,
    daysLeft: snap?.daysLeft,
    promptLevel: snap?.promptLevel,
    promptText: snap?.promptText,
    note: noteDraft || note,
    location: snap?.profile?.location,
    style: snap?.profile?.style,
    gear: gearLabels(snap?.gear ?? []),
    films: filmSummaries(snap?.history ?? []),
    memory: snap?.aurora?.facts ?? [],
    trips: tripSummaries(trips),
  };

  const m = useMutation({
    mutationFn: (history: ChatMessage[]) => ai.chat(history, context, useClaude ? "claude" : "groq"),
    onSuccess: (reply) =>
      setMessages((prev) => {
        const next = [...prev, { role: "assistant" as const, content: reply }];
        saveThread.mutate(next); // persist so Aurora remembers next session
        return next;
      }),
    onError: () =>
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            "I couldn't reach the studio just now — the server may be waking up. Try again in a moment.",
        },
      ]),
  });

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, m.isPending]);

  // Bridge to the user's own Claude Pro: copy the question + context and open
  // claude.ai so they paste it into their plan (no API/automation possible).
  function askMyClaude() {
    const q = input.trim() || [...messages].reverse().find((m) => m.role === "user")?.content || "";
    if (!q) {
      toast.error("Type a question first.");
      return;
    }
    const ctxLines = [
      user?.displayName && `Filmmaker: ${user.displayName}`,
      context.location && `Shoots around: ${context.location}`,
      context.gear?.length ? `Gear: ${context.gear.join(", ")}` : "",
      context.promptText && `This week's prompt: ${context.promptText}`,
    ].filter(Boolean).join("\n");
    const text =
      `You are my expert filmmaking co-pilot for solo video — be concrete and technical.\n\n${ctxLines}\n\nQuestion: ${q}`;
    navigator.clipboard?.writeText(text).then(
      () => toast.success("Copied — paste it into Claude"),
      () => toast.error("Couldn't copy — open Claude and type it.")
    );
    window.open("https://claude.ai/new", "_blank", "noopener,noreferrer");
  }

  function send(textArg?: string) {
    const text = (textArg ?? input).trim();
    if (!text || m.isPending) return;
    const next = [...messages, { role: "user" as const, content: text }];
    setMessages(next);
    setInput("");
    m.mutate(next);
  }

  return (
    <PageTransition>
      <PageHeader
        eyebrow="AI Co-pilot"
        title="Aurora"
        sub="Cinematic guidance for this week's film. Plain talk, no fluff."
      />

      <div className="mb-4 flex flex-wrap items-center gap-2">
        <GradientButton variant="ghost" onClick={() => setPlanOpen(true)}>
          <Icon name="sun" size={15} /> Plan a trip
        </GradientButton>
        <GradientButton variant="ghost" onClick={() => setCheckOpen(true)}>
          <Icon name="film" size={15} /> Check my video
        </GradientButton>
        <GradientButton variant="ghost" onClick={askMyClaude}>
          <Icon name="sparkles" size={15} /> Ask my Claude
        </GradientButton>
        {messages.length > 1 && (
          <GradientButton
            variant="ghost"
            onClick={() => {
              setMessages([GREETING]);
              saveThread.mutate([]);
            }}
          >
            <Icon name="refresh" size={15} /> New chat
          </GradientButton>
        )}
        <span className="text-xs text-text-dim">
          Talk through a trip, then save it — Aurora drops the prompt in on the day.
        </span>
      </div>

      <GlassCard className="mb-4 p-4">
        <label htmlFor="quick-note" className="mb-1.5 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-text-dim">
          <Icon name="bulb" size={13} /> Quick note — Aurora sees this
        </label>
        <input
          id="quick-note"
          value={noteDraft}
          onChange={(e) => setNoteDraft(e.target.value)}
          onBlur={() => noteDraft !== note && saveNote.mutate(noteDraft)}
          placeholder="e.g. shooting a rainy market this week, no tripod"
          className="w-full rounded-xl border border-hairline bg-field px-4 py-2.5 text-sm text-text-hi outline-none placeholder:text-text-dim/60 focus:border-cinema-500/70"
        />
      </GlassCard>

      <GlassCard className="flex h-[62vh] flex-col p-0">
        <div ref={scrollRef} className="flex-1 space-y-4 overflow-y-auto p-5">
          <AnimatePresence initial={false}>
            {messages.map((msg, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[78%] whitespace-pre-wrap rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${
                    msg.role === "user"
                      ? "bg-gradient-to-br from-cinema-400 to-cinema-600 text-[#1A1100]"
                      : "border border-hairline bg-chip text-text-hi"
                  }`}
                >
                  {msg.content}
                </div>
              </motion.div>
            ))}
          </AnimatePresence>

          {m.isPending && (
            <div className="flex justify-start">
              <div className="flex gap-1.5 rounded-2xl border border-hairline bg-chip px-4 py-3">
                {[0, 1, 2].map((d) => (
                  <motion.span
                    key={d}
                    className="h-2 w-2 rounded-full bg-cinema-400"
                    animate={{ opacity: [0.3, 1, 0.3] }}
                    transition={{ repeat: Infinity, duration: 1, delay: d * 0.2 }}
                  />
                ))}
              </div>
            </div>
          )}

          {messages.length === 1 && !m.isPending && (
            <div className="flex flex-wrap gap-2 pt-1">
              {STARTERS.map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => send(s)}
                  className="rounded-full border border-hairline bg-chip px-3 py-1.5 text-left text-xs text-text-dim transition-colors hover:border-cinema-500/60 hover:text-text-hi"
                >
                  {s}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="flex items-center gap-2 border-t border-hairline p-3">
          <label htmlFor="aurora-input" className="sr-only">
            Message Aurora
          </label>
          <input
            id="aurora-input"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && send()}
            placeholder="Ask Aurora about your shot, cut, or grade…"
            className="flex-1 rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none transition-colors placeholder:text-text-dim/60 focus:border-cinema-500/70"
          />
          <button
            onClick={() => send()}
            disabled={m.isPending || !input.trim()}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-cinema-400 to-cinema-600 text-[#16161a] transition-[filter] duration-200 hover:brightness-110 disabled:opacity-40"
            aria-label="Send message"
          >
            <Icon name="send" size={18} />
          </button>
        </div>
      </GlassCard>

      <PlanTripModal open={planOpen} onClose={() => setPlanOpen(false)} />
      <PrePostCheckModal open={checkOpen} onClose={() => setCheckOpen(false)} />
    </PageTransition>
  );
}
