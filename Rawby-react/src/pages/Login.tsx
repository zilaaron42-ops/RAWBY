import { useState } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { useMutation } from "@tanstack/react-query";
import { AuthLayout, Field, PasswordField } from "../components/layout/AuthLayout";
import { GradientButton } from "../components/ui/GradientButton";
import { ColdStartNote } from "../components/ui/Bits";
import { auth } from "../lib/endpoints";
import { authErrorMessage } from "../lib/errors";
import { useAuth } from "../store/auth";

export default function Login() {
  const nav = useNavigate();
  const loc = useLocation() as { state?: { from?: string; notice?: string } };
  const setAuth = useAuth((s) => s.setAuth);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const m = useMutation({
    mutationFn: () => auth.login(username.trim(), password),
    onSuccess: (data) => {
      setAuth(data.token, data.user);
      nav(loc.state?.from ?? "/", { replace: true });
    },
  });

  return (
    <AuthLayout title="Welcome back" tagline="Sign in to continue your streak.">
      {loc.state?.notice && (
        <div className="mb-4 rounded-lg border border-success/30 bg-success/10 px-3 py-2 text-sm text-success">
          {loc.state.notice}
        </div>
      )}

      <form
        onSubmit={(e) => {
          e.preventDefault();
          m.mutate();
        }}
      >
        <Field
          label="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          autoComplete="username"
          required
        />
        <PasswordField
          label="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="current-password"
          required
        />

        {m.isError && (
          <div className="mb-4 rounded-lg border border-danger/30 bg-danger/10 px-3 py-2 text-sm text-danger">
            {authErrorMessage(m.error)}
          </div>
        )}

        <GradientButton type="submit" className="w-full" disabled={m.isPending}>
          {m.isPending ? "Signing in…" : "Sign in"}
        </GradientButton>
      </form>

      {m.isPending && <ColdStartNote />}

      <p className="mt-6 text-center text-sm text-text-dim">
        New here?{" "}
        <Link to="/register" className="font-semibold text-cinema-400 hover:underline">
          Create an account
        </Link>
      </p>
    </AuthLayout>
  );
}
