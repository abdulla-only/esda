import { api, API_PREFIX } from "../../shared/api/client";
import type { Deck, Language } from "../../shared/api/types";

interface Paginated<T> {
  results: T[];
}

export const decksApi = {
  tree: () => api.get<Deck[]>(`${API_PREFIX}/decks/tree`).then((r) => r.data),
  languages: () =>
    api
      .get<Paginated<Language>>(`${API_PREFIX}/languages`)
      .then((r) => r.data.results),
};
