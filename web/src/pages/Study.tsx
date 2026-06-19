import { useCallback, useEffect, useState } from "react";
import { Button, Card, Spinner, Title } from "@telegram-apps/telegram-ui";

import { studyApi } from "../api/client";
import type { Rating, StudyCard } from "../api/types";

const GRADES: { rating: Rating; label: string; color: string }[] = [
  { rating: 1, label: "Again", color: "#e64646" },
  { rating: 2, label: "Hard", color: "#e6a046" },
  { rating: 3, label: "Good", color: "#3aaf5c" },
  { rating: 4, label: "Easy", color: "#3390ec" },
];

export function Study({ deck }: { deck?: number }) {
  const [queue, setQueue] = useState<StudyCard[]>([]);
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [loading, setLoading] = useState(true);
  const [grading, setGrading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const q = await studyApi.queue(deck, 30);
      setQueue(q.results);
      setIndex(0);
      setRevealed(false);
    } finally {
      setLoading(false);
    }
  }, [deck]);

  useEffect(() => {
    load();
  }, [load]);

  const current = queue[index];

  async function grade(rating: Rating) {
    if (!current || grading) return;
    setGrading(true);
    try {
      await studyApi.grade(current.id, rating);
      if (index + 1 < queue.length) {
        setIndex(index + 1);
        setRevealed(false);
      } else {
        await load(); // refill from the server (newly-due cards may reappear)
      }
    } finally {
      setGrading(false);
    }
  }

  if (loading) {
    return (
      <div className="page center">
        <Spinner size="l" />
      </div>
    );
  }

  if (!current) {
    return (
      <div className="page center">
        <Title level="2" weight="2">
          🎉 All caught up!
        </Title>
        <p className="hint">No cards due right now.</p>
        <Button size="m" onClick={load}>
          Refresh
        </Button>
      </div>
    );
  }

  return (
    <div className="page">
      <p className="counter">
        {index + 1} / {queue.length}
        {current.review.is_new ? " · new" : ""}
      </p>

      <Card className="flashcard" onClick={() => setRevealed(true)}>
        <div className="card-body">
          <div className="front">{current.front}</div>
          {revealed ? (
            <>
              <div className="divider" />
              <div className="back">{current.back}</div>
              {current.description && (
                <div className="desc">{current.description}</div>
              )}
              {current.example && <div className="example">“{current.example}”</div>}
              <div className="pos">{current.part_of_speech}</div>
            </>
          ) : (
            <div className="tap-hint">tap to reveal</div>
          )}
        </div>
      </Card>

      {revealed ? (
        <div className="grades">
          {GRADES.map((g) => (
            <button
              key={g.rating}
              className="grade-btn"
              style={{ background: g.color }}
              disabled={grading}
              onClick={() => grade(g.rating)}
            >
              {g.label}
            </button>
          ))}
        </div>
      ) : (
        <Button size="l" stretched onClick={() => setRevealed(true)}>
          Reveal
        </Button>
      )}
    </div>
  );
}
