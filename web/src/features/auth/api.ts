import { api, API_PREFIX } from "../../shared/api/client";
import type { TelegramAuthResponse, TokenPair, User } from "../../shared/api/types";

export const authApi = {
  telegram: (initData: string) =>
    api
      .post<TelegramAuthResponse>(`${API_PREFIX}/auth/telegram`, { init_data: initData })
      .then((r) => r.data),
  register: (email: string, password: string) =>
    api
      .post<TelegramAuthResponse>(`${API_PREFIX}/auth/register`, { email, password })
      .then((r) => r.data),
  emailLogin: (email: string, password: string) =>
    api.post<TokenPair>(`${API_PREFIX}/auth/token`, { email, password }).then((r) => r.data),
  me: () => api.get<User>(`${API_PREFIX}/auth/me`).then((r) => r.data),
};
