import { useEffect, useState } from "react";

import type { Deck, Language } from "../../shared/api/types";
import { decksApi } from "./api";

export interface DeckGroup {
  language: Language;
  decks: Deck[];
}

/** Fetches the deck tree + languages and groups root decks by language. */
export function useDeckTree() {
  const [groups, setGroups] = useState<DeckGroup[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    Promise.all([decksApi.tree(), decksApi.languages()])
      .then(([decks, languages]) => {
        if (cancelled) return;
        const byId = new Map(languages.map((l) => [l.id, l]));
        const grouped = languages
          .map((language) => ({
            language,
            decks: decks.filter((d) => d.language === language.id),
          }))
          .filter((g) => g.decks.length > 0);
        // Any decks whose language wasn't listed still show under a fallback.
        const orphaned = decks.filter((d) => !byId.has(d.language));
        if (orphaned.length) {
          grouped.push({
            language: { id: -1, code: "?", name: "Other" },
            decks: orphaned,
          });
        }
        setGroups(grouped);
      })
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  return { groups, loading };
}
