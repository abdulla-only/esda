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

  const addCard = async (payload: CardPayload) => {
    setBusy(true);
    setError(null);
    try {
      const card = await myDecksApi.createCard(deckId, payload);
      setCards((prev) => [...prev, card]);
    } catch {
      setError("Couldn't add the card.");
    } finally {
      setBusy(false);
    }
  };

  const editCard = async (id: number, payload: Partial<CardPayload>) => {
    setBusy(true);
    setError(null);
    try {
      const updated = await myDecksApi.updateCard(id, payload);
      setCards((prev) => prev.map((c) => (c.id === id ? updated : c)));
    } catch {
      setError("Couldn't update the card.");
    } finally {
      setBusy(false);
    }
  };

  const deleteCard = async (id: number) => {
    setBusy(true);
    setError(null);
    try {
      await myDecksApi.deleteCard(id);
      setCards((prev) => prev.filter((c) => c.id !== id));
    } catch {
      setError("Couldn't delete the card.");
    } finally {
      setBusy(false);
    }
  };

  return { cards, loading, busy, error, addCard, editCard, deleteCard };
}
