import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useMutation } from "@tanstack/react-query";
import { AuthLayout, Field } from "../components/layout/AuthLayout";
import { GradientButton } from "../components/ui/GradientButton";
import { ColdStartNote } from "../components/ui/Bits";
import { auth } from "../lib/endpoints";
import { authErrorMessage } from "../lib/errors";
import { useAuth } from "../store/auth";

export default function Register() {
  const nav = useNavigate();
  const setAuth = useAuth((s) => s.setAuth);
  const [f, setF] = useState({
    username: "",
    displayName: "",
    email: "",
    password: "",
  });
  const upd = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setF((s) => ({ ...s, [k]: e.target.value }));

  const m = useMutation({
    mutationFn: () =>
      auth.register({
        username: f.username.trim(),
        displayName: f.displayName.trim(),
        email: f.email.trim(),
        password: f.password,
      }),
    onSuccess: (data) => {
      if ("token" in data) {
        // Instant login (e.g. admin / verification disabled).
        setAuth(data.token, data.user);
        nav("/", { replace: true });
      } else {
        // Email verification required — bounce to login with a note.
        nav("/login", {
          replace: true,
          state: { notice: data.message ?? "Check your email to verify your account." },
        });
      }
    },
  });

  return (
    <AuthLayout title="Join RAWBY" tagline="Start your first weekly challenge.">
      <form
        onSubmit={(e) => {
          e.preventDefault();
          m.mutate();
        }}
      >
        <Field label="Display name" value={f.displayName} onChange={upd("displayName")} required />
        <Field label="Username" value={f.username} onChange={upd("username")} autoComplete="username" required />
        <Field label="Email" type="email" value={f.email} onChange={upd("email")} autoComplete="email" required />
        <Field
          label="Password"
          type="password"
          value={f.password}
          onChange={upd("password")}
          autoComplete="new-password"
          minLength={6}
          required
        />

        {m.isError && (
          <div className="mb-4 rounded-lg border border-danger/30 bg-danger/10 px-3 py-2 text-sm text-danger">
            {authErrorMessage(m.error)}
          </div>
        )}

        <GradientButton type="submit" variant="green" className="w-full" disabled={m.isPending}>
          {m.isPending ? "Creating…" : "Create account"}
        </GradientButton>
      </form>

      {m.isPending && <ColdStartNote />}

      <p className="mt-6 text-center text-sm text-text-dim">
        Already have an account?{" "}
        <Link to="/login" className="font-semibold text-cinema-400 hover:underline">
          Sign in
        </Link>
      </p>
    </AuthLayout>
  );
}
