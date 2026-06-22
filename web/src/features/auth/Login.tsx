import { FormEvent, useState } from "react";

import { ThemeToggle } from "../../app/ThemeToggle";
import { useAuth } from "./useAuth";

type Mode = "login" | "register";

export function Login() {
  const { loginWithEmail, registerWithEmail, error } = useAuth();
  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("demo@esda.app");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  const isRegister = mode === "register";

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await (isRegister
        ? registerWithEmail(email, password)
        : loginWithEmail(email, password));
    } catch {
      /* surfaced via context */
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth">
      <div className="auth__theme">
        <ThemeToggle />
      </div>
      <div className="auth__hero">
        <img
          className="auth__wordmark"
          src="/esda-wordmark.svg"
          alt="esda.uz — So'zlar esda qoladi."
          width={280}
          height={88}
        />
      </div>

      <div className="card">
        <div className="segmented" role="tablist">
          <button
            type="button"
            data-active={!isRegister}
            onClick={() => setMode("login")}
          >
            Sign in
          </button>
          <button
            type="button"
            data-active={isRegister}
            onClick={() => setMode("register")}
          >
            Register
          </button>
        </div>

        <form onSubmit={onSubmit}>
          <label className="field">
            <span className="field__label">Email</span>
            <input
              className="input"
              type="email"
              autoComplete="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.currentTarget.value)}
            />
          </label>
          <label className="field">
            <span className="field__label">Password</span>
            <input
              className="input"
              type="password"
              autoComplete={isRegister ? "new-password" : "current-password"}
              placeholder={isRegister ? "At least 8 characters" : "Your password"}
              value={password}
              onChange={(e) => setPassword(e.currentTarget.value)}
            />
          </label>

          {error && <div className="alert">{error}</div>}

          <button type="submit" className="btn btn-primary btn-block" disabled={busy}>
            {busy
              ? isRegister
                ? "Creating account…"
                : "Signing in…"
              : isRegister
                ? "Create account"
                : "Sign in"}
          </button>
        </form>

        <div className="switch-line">
          <button
            type="button"
            className="link"
            onClick={() => setMode(isRegister ? "login" : "register")}
          >
            {isRegister
              ? "Already have an account? Sign in"
              : "New to esda? Create an account"}
          </button>
        </div>
      </div>

      <p className="auth__note">
        Inside Telegram you’re signed in automatically. In a browser, use your
        email and password.
      </p>
    </div>
  );
}
