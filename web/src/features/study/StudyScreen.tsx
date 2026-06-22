import { useEffect } from "react";

import type { Rating } from "../../shared/api/types";
import { useStudySession } from "./useStudySession";

const GRADES: { rating: Rating; label: string; key: string }[] = [
  { rating: 1, label: "Again", key: "again" },
  { rating: 2, label: "Hard", key: "hard" },
  { rating: 3, label: "Good", key: "good" },
  { rating: 4, label: "Easy", key: "easy" },
];

export function StudyScreen({ deck }: { deck?: number }) {
  const { current, total, index, revealed, loading, grading, reveal, grade, reload } =
    useStudySession(deck);

  // Keyboard: Space reveals, 1–4 grade. A small power-user nicety.
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (!current) return;
      if (e.code === "Space" || e.key === "Enter") {
        e.preventDefault();
        if (!revealed) reveal();
      } else if (revealed && ["1", "2", "3", "4"].includes(e.key)) {
        grade(Number(e.key) as Rating);
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [current, revealed, reveal, grade]);

  if (loading) {
    return (
      <div className="screen screen--center">
        <div className="spinner" />
      </div>
    );
  }

  if (!current) {
    return (
      <div className="screen screen--center">
        <div className="empty-emoji">🌱</div>
        <h2 className="screen__title" style={{ margin: 0 }}>
          All caught up
        </h2>
        <p className="muted">No cards are due right now. Come back later!</p>
        <button className="btn" onClick={reload}>
          Refresh
        </button>
      </div>
    );
  }

  const pct = total ? Math.round((index / total) * 100) : 0;

  return (
    <div className="screen study">
      <div className="progress">
        <div className="progress__fill" style={{ width: `${pct}%` }} />
      </div>
      <div className="session-meta">
        <span>
          {index + 1} of {total}
        </span>
        {current.review.is_new && <span className="badge-new">new</span>}
      </div>

      <div
        className={`flashcard ${revealed ? "is-flipped" : ""}`}
        onClick={reveal}
        key={current.id}
      >
        <div className="flashcard__inner">
          <div className="face face--front">
            <span className="pos-chip">{current.part_of_speech}</span>
            <div className="term">{current.front}</div>
            <div className="reveal-hint">tap or press space to reveal</div>
          </div>
          <div className="face face--back">
            <span className="pos-chip">{current.part_of_speech}</span>
            <div className="term term--answer">{current.back}</div>
            {current.description && <div className="desc">{current.description}</div>}
            {current.example && <div className="example">“{current.example}”</div>}
          </div>
        </div>
      </div>

      {revealed ? (
        <div className="grades">
          {GRADES.map((g) => (
            <button
              key={g.rating}
              className={`grade grade--${g.key}`}
              disabled={grading}
              onClick={() => grade(g.rating)}
            >
              <span>{g.label}</span>
              <span className="kbd">{g.rating}</span>
            </button>
          ))}
        </div>
      ) : (
        <button className="btn btn-primary btn-block" onClick={reveal}>
          Reveal answer <span className="kbd">space</span>
        </button>
      )}
    </div>
  );
}
