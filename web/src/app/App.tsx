import { useState } from "react";

import { useAuth } from "../features/auth/useAuth";
import { Login } from "../features/auth/Login";
import { MyDecks } from "../features/mydecks/MyDecks";
import { StudyScreen } from "../features/study/StudyScreen";

type Tab = "study" | "decks";

export function App() {
  const { authed, loading, logout } = useAuth();
  const [tab, setTab] = useState<Tab>("study");

  if (loading) {
    return (
      <div className="screen screen--center">
        <div className="spinner" />
      </div>
    );
  }

  if (!authed) {
    return <Login />;
  }

  return (
    <div className="app">
      {/* Desktop: persistent sidebar */}
      <aside className="sidebar">
        <div className="sidebar__brand">
          <img className="brand__img" src="/esda-icon-flashcard.svg" alt="" width={32} height={32} />
          <span className="brand__word">
            es<span className="brand__dot">da</span>
          </span>
        </div>
        <nav className="sidebar__nav">
          <button className={`navitem ${tab === "study" ? "active" : ""}`} onClick={() => setTab("study")}>
            <CardsGlyph size={20} />
            Study
          </button>
          <button className={`navitem ${tab === "decks" ? "active" : ""}`} onClick={() => setTab("decks")}>
            <LayersGlyph size={20} />
            Decks
          </button>
        </nav>
        <button className="navitem navitem--muted" onClick={logout}>
          <LogoutGlyph />
          Sign out
        </button>
      </aside>

      {/* Mobile: top bar */}
      <header className="topbar">
        <span className="brand">
          <img className="brand__img" src="/esda-icon-flashcard.svg" alt="esda" width={30} height={30} />
          <span className="brand__word">
            es<span className="brand__dot">da</span>
          </span>
        </span>
        <button className="icon-btn" onClick={logout} aria-label="Sign out">
          <LogoutGlyph />
        </button>
      </header>

      <main className="content">
        {tab === "study" ? <StudyScreen /> : <MyDecks />}
      </main>

      {/* Mobile: floating bottom nav */}
      <nav className="tabbar">
        <button className={`tab ${tab === "study" ? "active" : ""}`} onClick={() => setTab("study")}>
          <CardsGlyph size={18} />
          Study
        </button>
        <button className={`tab ${tab === "decks" ? "active" : ""}`} onClick={() => setTab("decks")}>
          <LayersGlyph size={18} />
          Decks
        </button>
      </nav>
    </div>
  );
}

function CardsGlyph({ size = 18 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <rect x="3" y="6" width="13" height="15" rx="3" fill="currentColor" opacity="0.4" />
      <rect x="8" y="3" width="13" height="15" rx="3" fill="currentColor" />
    </svg>
  );
}

function LayersGlyph({ size = 18 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M12 3l9 5-9 5-9-5 9-5z" fill="currentColor" />
      <path
        d="M3 13l9 5 9-5"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinejoin="round"
        opacity="0.5"
        fill="none"
      />
    </svg>
  );
}

function LogoutGlyph() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M15 12H4m0 0l4-4m-4 4l4 4M14 4h4a2 2 0 012 2v12a2 2 0 01-2 2h-4"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
