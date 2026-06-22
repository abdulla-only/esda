import { useEffect, useState } from "react";

import type { Deck, Language } from "../../shared/api/types";
import { myDecksApi } from "./api";

/** Owns the user's decks list + create/rename/delete; all logic lives here. */
export function useMyDecks() {
  const [decks, setDecks] = useState<Deck[]>([]);
  const [languages, setLanguages] = useState<Language[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    Promise.all([myDecksApi.listMine(), myDecksApi.languages()])
      .then(([mine, langs]) => {
        if (cancelled) return;
        setDecks(mine);
        setLanguages(langs);
      })
      .catch(() => !cancelled && setError("Couldn't load your decks."))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  // Mutations rethrow on failure so the UI can show one toast (DRY feedback).
  const createDeck = async (language: number, name: string) => {
    setBusy(true);
    try {
      const deck = await myDecksApi.createDeck(language, name);
      setDecks((prev) => [...prev, deck]);
    } finally {
      setBusy(false);
    }
  };

  const renameDeck = async (id: number, name: string) => {
    setBusy(true);
    try {
      const updated = await myDecksApi.renameDeck(id, name);
      setDecks((prev) => prev.map((d) => (d.id === id ? updated : d)));
    } finally {
      setBusy(false);
    }
  };

  const deleteDeck = async (id: number) => {
    setBusy(true);
    try {
      await myDecksApi.deleteDeck(id);
      setDecks((prev) => prev.filter((d) => d.id !== id));
    } finally {
      setBusy(false);
    }
  };

  return {
    decks,
    languages,
    loading,
    busy,
    error,
    createDeck,
    renameDeck,
    deleteDeck,
  };
}
