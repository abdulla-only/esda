// Telegram SDK bootstrap.
//
// In a real Telegram client we initialize the SDK against the live environment.
// In a plain browser we install a mock environment so the app (and the
// @telegram-apps/telegram-ui components) still render — there we fall back to
// the email/password login path instead of Telegram auth.
import {
  init as initSDK,
  isTMA,
  mockTelegramEnv,
  retrieveRawInitData,
} from "@telegram-apps/sdk-react";

let telegramReal = false;

function buildMockInitData(): string {
  // NOTE: this hash is fake on purpose — it will NOT validate against the real
  // BOT_TOKEN server-side. Browser dev uses email login; this only keeps the
  // SDK/UI happy outside Telegram.
  return new URLSearchParams({
    user: JSON.stringify({
      id: 1,
      first_name: "Dev",
      last_name: "User",
      username: "dev",
      language_code: "en",
    }),
    auth_date: String(Math.floor(Date.now() / 1000)),
    hash: "0".repeat(64),
    chat_type: "sender",
    chat_instance: "0",
  }).toString();
}

export function initTelegram(): void {
  try {
    telegramReal = isTMA();
  } catch {
    telegramReal = false;
  }

  if (!telegramReal) {
    mockTelegramEnv({
      launchParams: {
        tgWebAppPlatform: "web",
        tgWebAppVersion: "8.0",
        tgWebAppData: buildMockInitData(),
        tgWebAppThemeParams: {
          bg_color: "#ffffff",
          text_color: "#000000",
          button_color: "#3390ec",
          button_text_color: "#ffffff",
          hint_color: "#707579",
          link_color: "#3390ec",
        },
      },
    });
  }

  try {
    initSDK();
  } catch (err) {
    // Non-fatal: the SDK may already be initialized or unavailable.
    console.warn("Telegram SDK init skipped:", err);
  }
}

/** True only inside a genuine Telegram client (not the browser mock). */
export function isTelegramReal(): boolean {
  return telegramReal;
}

/** Raw initData query string to POST to /api/auth/telegram, or null. */
export function getRawInitData(): string | null {
  try {
    return retrieveRawInitData() ?? null;
  } catch {
    return null;
  }
}
