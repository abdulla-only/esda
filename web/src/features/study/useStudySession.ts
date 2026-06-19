import { useCallback, useEffect, useState } from "react";

import type { Rating, StudyCard } from "../../shared/api/types";
import { studyApi } from "./api";

/** All study orchestration (fetch queue, reveal, grade, advance) lives here. */
export function useStudySession(deck?: number) {
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

  const grade = useCallback(
    async (rating: Rating) => {
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
    },
    [current, grading, index, queue.length, load],
  );

  return {
    current,
    total: queue.length,
    index,
    revealed,
    loading,
    grading,
    reveal: () => setRevealed(true),
    grade,
    reload: load,
  };
}
