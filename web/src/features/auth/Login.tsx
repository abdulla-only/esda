import { FormEvent, useState } from "react";
import { Button, Input, Section, Title } from "@telegram-apps/telegram-ui";

import { useAuth } from "./useAuth";

export function Login() {
  const { loginWithEmail, error } = useAuth();
  const [email, setEmail] = useState("demo@esda.app");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await loginWithEmail(email, password);
    } catch {
      /* error surfaced via context */
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page">
      <Title level="1" weight="2" style={{ marginBottom: 16 }}>
        Sign in to esda
      </Title>
      <form onSubmit={onSubmit}>
        <Section header="Email login">
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
          {busy ? "Signing in…" : "Sign in"}
        </Button>
      </form>
      <p className="hint">
        Opened inside Telegram, esda signs you in automatically. In a browser,
        use your email and password.
      </p>
    </div>
  );
}
