import { FormEvent, useState } from "react";
import { Button, Input, Section, Title } from "@telegram-apps/telegram-ui";

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
      if (isRegister) {
        await registerWithEmail(email, password);
      } else {
        await loginWithEmail(email, password);
      }
    } catch {
      /* error surfaced via context */
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page">
      <Title level="1" weight="2" style={{ marginBottom: 16 }}>
        {isRegister ? "Create your esda account" : "Sign in to esda"}
      </Title>
      <form onSubmit={onSubmit}>
        <Section header={isRegister ? "Register" : "Email login"}>
          <Input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.currentTarget.value)}
          />
          <Input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.currentTarget.value)}
          />
        </Section>
        {error && <p className="error">{error}</p>}
        <Button type="submit" size="l" stretched disabled={busy}>
          {busy
            ? isRegister
              ? "Creating…"
              : "Signing in…"
            : isRegister
              ? "Create account"
              : "Sign in"}
        </Button>
      </form>
      <button
        type="button"
        className="link-btn"
        onClick={() => setMode(isRegister ? "login" : "register")}
      >
        {isRegister
          ? "Already have an account? Sign in"
          : "New here? Create an account"}
      </button>
      <p className="hint">
        Opened inside Telegram, esda signs you in automatically. In a browser,
        use your email and password.
      </p>
    </div>
  );
}
