import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageTransition } from "../components/layout/PageTransition";
import { GlassCard } from "../components/ui/GlassCard";
import { GradientButton } from "../components/ui/GradientButton";
import { PageHeader, Spinner, EmptyState } from "../components/ui/Bits";
import { Icon } from "../components/ui/Icon";
import { admin } from "../lib/endpoints";
import { useAuth } from "../store/auth";
import { toast } from "../store/toast";

const fieldCls =
  "w-full rounded-xl border border-hairline bg-field px-4 py-3 text-sm text-text-hi outline-none placeholder:text-text-dim/60 focus:border-cinema-500/70";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function asArray(d: any, key: string): any[] {
  if (Array.isArray(d)) return d;
  if (d && Array.isArray(d[key])) return d[key];
  return [];
}

export default function Admin() {
  const me = useAuth((s) => s.user);

  const [annT, setAnnT] = useState("");
  const [annB, setAnnB] = useState("");
  const [grant, setGrant] = useState("");

  const post = useMutation({
    mutationFn: () => admin.postUpdate({ title: annT.trim(), body: annB.trim() }),
    onSuccess: () => { setAnnT(""); setAnnB(""); toast.success("Announcement posted"); },
    onError: () => toast.error("Couldn't post announcement"),
  });
  const mkAdmin = useMutation({
    mutationFn: () => admin.setAdmin(grant.trim()),
    onSuccess: () => { setGrant(""); toast.success("Admin granted"); },
    onError: () => toast.error("Couldn't grant admin"),
  });

  const isAdmin = !!me?.isAdmin;
  const users = useQuery({ queryKey: ["admin", "users"], queryFn: admin.users, enabled: isAdmin });
  const sugg = useQuery({ queryKey: ["admin", "suggestions"], queryFn: admin.allSuggestions, enabled: isAdmin });

  if (!isAdmin) {
    return (
      <PageTransition>
        <PageHeader eyebrow="Restricted" title="Admin" />
        <EmptyState icon="alert" title="Admins only" sub="This area needs an admin account." />
      </PageTransition>
    );
  }

  const usersList = asArray(users.data, "users");
  const suggList = asArray(sugg.data, "suggestions");

  return (
    <PageTransition>
      <PageHeader eyebrow="Control room" title="Admin" sub={`Signed in as ${me?.displayName} · full controls.`} />

      <div className="grid gap-4 lg:grid-cols-2">
        {/* Announcement */}
        <GlassCard className="space-y-3">
          <h3 className="h-display text-lg font-bold text-text-hi">Post announcement</h3>
          <input value={annT} onChange={(e) => setAnnT(e.target.value)} placeholder="Title" className={fieldCls} />
          <textarea value={annB} onChange={(e) => setAnnB(e.target.value)} placeholder="Message to all users…" rows={3} className={`${fieldCls} resize-none`} />
          <GradientButton onClick={() => post.mutate()} loading={post.isPending} disabled={!annT.trim() || !annB.trim()}>
            <Icon name="send" size={15} /> Broadcast
          </GradientButton>
        </GlassCard>

        {/* Grant admin */}
        <GlassCard className="space-y-3">
          <h3 className="h-display text-lg font-bold text-text-hi">Grant admin</h3>
          <p className="text-xs text-text-dim">Give another user admin rights by username.</p>
          <input value={grant} onChange={(e) => setGrant(e.target.value)} placeholder="username" className={fieldCls} />
          <GradientButton variant="story" onClick={() => mkAdmin.mutate()} loading={mkAdmin.isPending} disabled={!grant.trim()}>
            <Icon name="user" size={15} /> Make admin
          </GradientButton>
        </GlassCard>
      </div>

      {/* Users */}
      <h3 className="h-display mb-3 mt-8 text-lg font-bold text-text-hi">
        Users {usersList.length ? <span className="text-sm font-normal text-text-dim">({usersList.length})</span> : null}
      </h3>
      {users.isLoading ? (
        <Spinner label="Loading users…" />
      ) : usersList.length === 0 ? (
        <EmptyState icon="user" title="No users" />
      ) : (
        <div className="space-y-2">
          {usersList.map((u, i) => (
            <GlassCard key={u.id ?? u.username ?? i} className="flex items-center justify-between py-3">
              <div className="min-w-0">
                <div className="truncate text-sm font-semibold text-text-hi">
                  {u.displayName ?? u.username}
                  {u.isAdmin && <span className="ml-2 rounded-full bg-cinema-500/15 px-2 py-0.5 text-[10px] font-semibold text-cinema-400">ADMIN</span>}
                </div>
                <div className="truncate text-xs text-text-dim">@{u.username} · {u.totalScore ?? 0} pts</div>
              </div>
            </GlassCard>
          ))}
        </div>
      )}

      {/* Suggestions */}
      <h3 className="h-display mb-3 mt-8 text-lg font-bold text-text-hi">
        Suggestions {suggList.length ? <span className="text-sm font-normal text-text-dim">({suggList.length})</span> : null}
      </h3>
      {sugg.isLoading ? (
        <Spinner label="Loading suggestions…" />
      ) : suggList.length === 0 ? (
        <EmptyState icon="bulb" title="No suggestions yet" />
      ) : (
        <div className="space-y-2">
          {suggList.map((s, i) => (
            <GlassCard key={s.id ?? i} className="py-3">
              <p className="text-sm text-text-hi">{s.text ?? s.message ?? JSON.stringify(s)}</p>
              {s.username && <div className="mt-1 text-xs text-text-dim">@{s.username}</div>}
            </GlassCard>
          ))}
        </div>
      )}
    </PageTransition>
  );
}
