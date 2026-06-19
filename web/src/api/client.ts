// API client with a JWT auth interceptor.
//
// - Requests get an `Authorization: Bearer <access>` header from localStorage.
// - Successful responses are unwrapped from the API envelope ({success,data}).
// - On a 401 we try once to refresh the access token, then replay the request.
import axios, {
  AxiosError,
  AxiosInstance,
  InternalAxiosRequestConfig,
} from "axios";

import type {
  Deck,
  StudyQueue,
  TelegramAuthResponse,
  TokenPair,
  User,
} from "./types";

const ACCESS_KEY = "esda.access";
const REFRESH_KEY = "esda.refresh";
const API = "/api/v1";

export const tokenStore = {
  get access() {
    return localStorage.getItem(ACCESS_KEY);
  },
  get refresh() {
    return localStorage.getItem(REFRESH_KEY);
  },
  set({ access, refresh }: TokenPair) {
    localStorage.setItem(ACCESS_KEY, access);
    localStorage.setItem(REFRESH_KEY, refresh);
  },
  setAccess(access: string) {
    localStorage.setItem(ACCESS_KEY, access);
  },
  clear() {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
  },
  get isAuthed() {
    return Boolean(localStorage.getItem(ACCESS_KEY));
  },
};

const baseURL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";

export const api: AxiosInstance = axios.create({ baseURL });

api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = tokenStore.access;
  if (token) {
    config.headers.set("Authorization", `Bearer ${token}`);
  }
  return config;
});

let refreshing: Promise<string | null> | null = null;

async function refreshAccess(): Promise<string | null> {
  const refresh = tokenStore.refresh;
  if (!refresh) return null;
  try {
    const { data } = await axios.post(`${baseURL}${API}/auth/token/refresh`, {
      refresh,
    });
    const access = data.data.access as string; // envelope: {success,data:{access}}
    tokenStore.setAccess(access);
    return access;
  } catch {
    tokenStore.clear();
    return null;
  }
}

api.interceptors.response.use(
  (res) => {
    // Unwrap the success envelope so callers see the payload directly.
    if (res.data && typeof res.data === "object" && "success" in res.data) {
      res.data = res.data.data;
    }
    return res;
  },
  async (error: AxiosError) => {
    const original = error.config as
      | (InternalAxiosRequestConfig & { _retried?: boolean })
      | undefined;

    if (error.response?.status === 401 && original && !original._retried) {
      original._retried = true;
      refreshing = refreshing ?? refreshAccess();
      const newAccess = await refreshing;
      refreshing = null;
      if (newAccess) {
        original.headers.set("Authorization", `Bearer ${newAccess}`);
        return api(original);
      }
    }
    return Promise.reject(error);
  },
);

export const authApi = {
  telegram: (initData: string) =>
    api
      .post<TelegramAuthResponse>(`${API}/auth/telegram`, { init_data: initData })
      .then((r) => r.data),
  emailLogin: (email: string, password: string) =>
    api.post<TokenPair>(`${API}/auth/token`, { email, password }).then((r) => r.data),
  me: () => api.get<User>(`${API}/auth/me`).then((r) => r.data),
};

export const catalogApi = {
  deckTree: () => api.get<Deck[]>(`${API}/decks/tree`).then((r) => r.data),
};

export const studyApi = {
  queue: (deck?: number, limit = 20) =>
    api
      .get<StudyQueue>(`${API}/study/queue`, { params: { deck, limit } })
      .then((r) => r.data),
  grade: (card: number, rating: number) =>
    api.post(`${API}/study/grade`, { card, rating }).then((r) => r.data),
};
