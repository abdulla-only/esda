import { api, API_PREFIX } from "../../shared/api/client";
import type { Deck } from "../../shared/api/types";

export const decksApi = {
  tree: () => api.get<Deck[]>(`${API_PREFIX}/decks/tree`).then((r) => r.data),
};
