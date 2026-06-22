import { useEffect, useState } from "react";

import type { Card } from "../../shared/api/types";
import { myDecksApi, type CardPayload } from "./api";

/** Owns a selected deck's cards + add/edit/delete; all logic lives here. */
export function useDeckCards(deckId: number) {
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    myDecksApi
      .listCards(deckId)
      .then((list) => !cancelled && setCards(list))
      .catch(() => !cancelled && setError("Couldn't load cards."))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [deckId]);

  // Mutations rethrow on failure so the UI shows one toast (DRY feedback).
  const addCard = async (payload: CardPayload) => {
    setBusy(true);
    try {
      const card = await myDecksApi.createCard(deckId, payload);
      setCards((prev) => [...prev, card]);
    } finally {
      setBusy(false);
    }
  };

  const editCard = async (id: number, payload: Partial<CardPayload>) => {
    setBusy(true);
    try {
      const updated = await myDecksApi.updateCard(id, payload);
      setCards((prev) => prev.map((c) => (c.id === id ? updated : c)));
    } finally {
      setBusy(false);
    }
  };

  const deleteCard = async (id: number) => {
    setBusy(true);
    try {
      await myDecksApi.deleteCard(id);
      setCards((prev) => prev.filter((c) => c.id !== id));
    } finally {
      setBusy(false);
    }
  };

  return { cards, loading, busy, error, addCard, editCard, deleteCard };
}
