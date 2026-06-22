import { api, API_PREFIX } from "../../shared/api/client";
import type { Card, Deck, Language, PartOfSpeech } from "../../shared/api/types";

interface Paginated<T> {
  results: T[];
}

export interface CardPayload {
  front: string;
  back: string;
  part_of_speech?: PartOfSpeech;
  example?: string;
  description?: string;
}

export const myDecksApi = {
  // owner=me → the caller's own (flat) personal decks.
  listMine: () =>
    api
      .get<Paginated<Deck>>(`${API_PREFIX}/decks`, { params: { owner: "me" } })
      .then((r) => r.data.results),
  createDeck: (language: number, name: string) =>
    api
      .post<Deck>(`${API_PREFIX}/decks`, { language, name })
      .then((r) => r.data),
  renameDeck: (id: number, name: string) =>
    api.patch<Deck>(`${API_PREFIX}/decks/${id}`, { name }).then((r) => r.data),
  deleteDeck: (id: number) =>
    api.delete(`${API_PREFIX}/decks/${id}`).then(() => undefined),
  listCards: (deckId: number) =>
    api
      .get<Paginated<Card>>(`${API_PREFIX}/cards`, { params: { deck: deckId } })
      .then((r) => r.data.results),
  createCard: (deck: number, payload: CardPayload) =>
    api
      .post<Card>(`${API_PREFIX}/cards`, { deck, ...payload })
      .then((r) => r.data),
  updateCard: (id: number, payload: Partial<CardPayload>) =>
    api.patch<Card>(`${API_PREFIX}/cards/${id}`, payload).then((r) => r.data),
  deleteCard: (id: number) =>
    api.delete(`${API_PREFIX}/cards/${id}`).then(() => undefined),
  languages: () =>
    api
      .get<Paginated<Language>>(`${API_PREFIX}/languages`)
      .then((r) => r.data.results),
};
