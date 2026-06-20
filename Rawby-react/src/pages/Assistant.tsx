import { useRef, useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useMutation } from "@tanstack/react-query";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { PageHeader } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { ai } from "../lib/endpoints";
import { useMe } from "../hooks/queries";
import { useAuth } from "../store/auth";
import type { ChatMessage, ChatContext } from "../types";

const GREETING: ChatMessage = {
  role: "assistant",
  content:
    "Hey — I'm Aurora, your filmmaking co-pilot. Tell me what you're shooting this week and I'll help you frame it, cut it, or grade it.",
};

export default function Assistant() {
  const { data } = useMe();
  const provider = useAuth((s) => s.aiProvider);
  const setProvider = useAuth((s) => s.setProvider);
  const user = useAuth((s) => s.user);

  const [messages, setMessages] = useState<ChatMessage[]>([GREETING]);
  const [input, setInput] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);

  const context: ChatContext = {
    displayName: user?.displayName,
    rank: data?.snapshot?.rank,
    totalScore: data?.snapshot?.totalScore,
    streak: data?.snapshot?.streak,
    regensLeft: data?.snapshot?.regensLeft,
    daysLeft: data?.snapshot?.daysLeft,
    promptLevel: data?.snapshot?.promptLevel,
    promptText: data?.snapshot?.promptText,
  };

  const m = useMutation({
    mutationFn: (history: ChatMessage[]) => ai.chat(history, context, provider),
    onSuccess: (reply) =>
      setMessages((prev) => [...prev, { role: "assistant", content: reply }]),
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

  function send() {
    const text = input.trim();
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
        right={
          <div className="flex items-center gap-1 rounded-xl border border-hairline bg-field p-1 text-xs font-semibold">
            {(["groq", "claude"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setProvider(p)}
                className={`rounded-lg px-3 py-1.5 transition-colors ${
                  provider === p
                    ? "bg-cinema-500 text-[#1A1100]"
                    : "text-text-dim hover:text-text-hi"
                }`}
              >
                {p === "groq" ? "Groq · free" : "Claude"}
              </button>
            ))}
          </div>
        }
      />

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
            onClick={send}
            disabled={m.isPending || !input.trim()}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-cinema-400 to-cinema-600 text-[#1A1100] transition-[filter] duration-200 hover:brightness-110 disabled:opacity-40"
            aria-label="Send message"
          >
            <Icon name="send" size={18} />
          </button>
        </div>
      </GlassCard>
    </PageTransition>
  );
}
