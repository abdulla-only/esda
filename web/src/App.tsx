import { useState } from "react";
import { Button, Spinner, Tabbar } from "@telegram-apps/telegram-ui";

import { useAuth } from "./auth/AuthContext";
import { Decks } from "./pages/Decks";
import { Login } from "./pages/Login";
import { Study } from "./pages/Study";

type Tab = "study" | "decks";

export function App() {
  const { authed, loading, logout } = useAuth();
  const [tab, setTab] = useState<Tab>("study");
  const [deckFilter, setDeckFilter] = useState<number | undefined>(undefined);

  if (loading) {
    return (
      <div className="page center">
        <Spinner size="l" />
      </div>
    );
  }

  if (!authed) {
    return <Login />;
  }

  return (
    <div className="app">
      <header className="topbar">
        <strong>esda</strong>
        <Button mode="plain" size="s" onClick={logout}>
          Sign out
        </Button>
      </header>

      <main className="content">
        {tab === "study" ? (
          <Study deck={deckFilter} />
        ) : (
          <Decks
            onStudy={(deckId) => {
              setDeckFilter(deckId);
              setTab("study");
            }}
          />
        )}
      </main>

      <Tabbar>
        <Tabbar.Item
          text="Study"
          selected={tab === "study"}
          onClick={() => {
            setDeckFilter(undefined);
            setTab("study");
          }}
        >
          📚
        </Tabbar.Item>
        <Tabbar.Item
          text="Decks"
          selected={tab === "decks"}
          onClick={() => setTab("decks")}
        >
          🗂️
        </Tabbar.Item>
      </Tabbar>
    </div>
  );
}
