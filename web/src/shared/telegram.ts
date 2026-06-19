// Telegram init data access.
//
// Inside a Telegram client the official telegram-web-app.js script (loaded in
// index.html) and the SDK expose the launch params; we read the raw initData to
// send to /api/v1/auth/telegram. In a plain browser there is no init data, so we
// return null and the app falls back to email login. No mock is needed — the
// browser path simply doesn't touch Telegram.
import { retrieveRawInitData } from "@telegram-apps/sdk-react";

/** Raw Telegram initData query string, or null when not inside Telegram. */
export function getRawInitData(): string | null {
  try {
    const raw = retrieveRawInitData();
    if (raw) return raw;
  } catch {
    // Not a Telegram environment (e.g. a plain browser tab).
  }
  const fromWebApp = (
    window as unknown as { Telegram?: { WebApp?: { initData?: string } } }
  ).Telegram?.WebApp?.initData;
  return fromWebApp || null;
}
