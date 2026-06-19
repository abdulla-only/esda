import { api, API_PREFIX } from "../../shared/api/client";
import type { StudyQueue } from "../../shared/api/types";

export const studyApi = {
  queue: (deck?: number, limit = 20) =>
    api
      .get<StudyQueue>(`${API_PREFIX}/study/queue`, { params: { deck, limit } })
      .then((r) => r.data),
  grade: (card: number, rating: number) =>
    api.post(`${API_PREFIX}/study/grade`, { card, rating }).then((r) => r.data),
};
