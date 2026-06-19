import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { tokenStore } from "../../shared/api/client";
import { getRawInitData, isTelegramReal } from "../../shared/telegram";
import { authApi } from "./api";

interface AuthState {
  authed: boolean;
  loading: boolean;
  error: string | null;
  loginWithEmail: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [authed, setAuthed] = useState<boolean>(tokenStore.isAuthed);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // On launch, if we're inside Telegram and not already authed, exchange
  // initData for a JWT automatically.
  useEffect(() => {
    let cancelled = false;
    async function bootstrap() {
      if (tokenStore.isAuthed) {
        setAuthed(true);
        setLoading(false);
        return;
      }
      if (isTelegramReal()) {
        const initData = getRawInitData();
        if (initData) {
          try {
            const res = await authApi.telegram(initData);
            tokenStore.set(res);
            if (!cancelled) setAuthed(true);
          } catch {
            if (!cancelled) setError("Telegram authentication failed.");
          }
        }
      }
      if (!cancelled) setLoading(false);
    }
    bootstrap();
    return () => {
      cancelled = true;
    };
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      authed,
      loading,
      error,
      async loginWithEmail(email, password) {
        setError(null);
        try {
          const tokens = await authApi.emailLogin(email, password);
          tokenStore.set(tokens);
          setAuthed(true);
        } catch {
          setError("Invalid email or password.");
          throw new Error("login failed");
        }
      },
      logout() {
        tokenStore.clear();
        setAuthed(false);
      },
    }),
    [authed, loading, error],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
