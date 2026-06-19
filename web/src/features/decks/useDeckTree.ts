import { useEffect, useState } from "react";

import type { Deck } from "../../shared/api/types";
import { decksApi } from "./api";

export function useDeckTree() {
  const [decks, setDecks] = useState<Deck[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    decksApi
      .tree()
      .then((d) => !cancelled && setDecks(d))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  return { decks, loading };
}
