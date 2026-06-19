import { Button, Card, Spinner, Title } from "@telegram-apps/telegram-ui";

import type { Rating } from "../../shared/api/types";
import { useStudySession } from "./useStudySession";

const GRADES: { rating: Rating; label: string; color: string }[] = [
  { rating: 1, label: "Again", color: "#e64646" },
  { rating: 2, label: "Hard", color: "#e6a046" },
  { rating: 3, label: "Good", color: "#3aaf5c" },
  { rating: 4, label: "Easy", color: "#3390ec" },
];

export function StudyScreen({ deck }: { deck?: number }) {
  const { current, total, index, revealed, loading, grading, reveal, grade, reload } =
    useStudySession(deck);

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
        <Button size="m" onClick={reload}>
          Refresh
        </Button>
      </div>
    );
  }

  return (
    <div className="page">
      <p className="counter">
        {index + 1} / {total}
        {current.review.is_new ? " · new" : ""}
      </p>

      <Card className="flashcard" onClick={reveal}>
        <div className="card-body">
          <div className="front">{current.front}</div>
          {revealed ? (
            <>
              <div className="divider" />
              <div className="back">{current.back}</div>
              {current.description && <div className="desc">{current.description}</div>}
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
        <Button size="l" stretched onClick={reveal}>
          Reveal
        </Button>
      )}
    </div>
  );
}
