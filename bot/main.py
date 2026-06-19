"""
esda Telegram bot (aiogram 3.x).

  /start   -> greeting + an inline button that launches the Mini App.
  /study   -> shortcut button straight into the study session.
  /remind  -> stub that demonstrates the reminder flow (sends *you* a reminder
              with a deep-link button). See send_due_reminders() for where a
              scheduled job would fan this out to every user with due cards.
"""
from __future__ import annotations

import asyncio
import logging
import os

import httpx
from aiogram import Bot, Dispatcher, Router
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.filters import Command, CommandStart
from aiogram.types import (
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Message,
    WebAppInfo,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("esda.bot")

BOT_TOKEN = os.environ.get("BOT_TOKEN", "")
MINI_APP_URL = os.environ.get("MINI_APP_URL", "http://localhost:5173")
# Reachable API base URL from the bot's network (compose: http://api:8000).
API_URL = os.environ.get("BOT_API_URL", os.environ.get("VITE_API_URL", "http://api:8000"))

router = Router()


def open_app_keyboard(start_param: str | None = None) -> InlineKeyboardMarkup:
    """Inline keyboard with a web_app button that opens the Mini App."""
    url = MINI_APP_URL
    if start_param:
        sep = "&" if "?" in url else "?"
        url = f"{url}{sep}startapp={start_param}"
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="📚 Open esda",
                    web_app=WebAppInfo(url=url),
                )
            ]
        ]
    )


@router.message(CommandStart())
async def on_start(message: Message) -> None:
    name = message.from_user.first_name if message.from_user else "there"
    await message.answer(
        f"Hi {name}! 👋\n\n"
        "<b>esda</b> helps you learn English & Russian vocabulary with "
        "spaced repetition. Tap the button below to start studying.",
        reply_markup=open_app_keyboard(),
    )


@router.message(Command("study"))
async def on_study(message: Message) -> None:
    await message.answer(
        "Jump straight into your study session:",
        reply_markup=open_app_keyboard(start_param="study"),
    )


@router.message(Command("remind"))
async def on_remind(message: Message) -> None:
    """Stub: demonstrate the reminder message a due-card job would send."""
    await message.answer(
        "⏰ You have cards due for review! Keep your streak going:",
        reply_markup=open_app_keyboard(start_param="study"),
    )


async def send_due_reminders(bot: Bot) -> None:
    """
    Stub for a scheduled reminder job.

    A real implementation would ask the API which users have cards due now
    (e.g. an authenticated GET /api/study/due-users endpoint) and DM each one a
    deep-link button into the study session. Wire this to a scheduler
    (APScheduler / cron / Celery beat) in production.
    """
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(f"{API_URL}/api/v1/health")
            logger.info("API health for reminder job: %s", resp.json())
    except Exception as exc:  # noqa: BLE001
        logger.warning("Reminder job could not reach the API: %s", exc)
    # for user_id in users_with_due_cards:
    #     await bot.send_message(user_id, "⏰ Cards due!", reply_markup=open_app_keyboard("study"))
    logger.info("send_due_reminders: stub complete (no users messaged).")


async def main() -> None:
    if not BOT_TOKEN or BOT_TOKEN.startswith("123456:"):
        # No real token yet (e.g. fresh `make dev`). Stay alive but idle so the
        # container doesn't crash-loop; set a real BOT_TOKEN from @BotFather.
        logger.warning(
            "BOT_TOKEN is not a real token — bot is idle. "
            "Set BOT_TOKEN in your env file to enable it."
        )
        await asyncio.Event().wait()
        return

    bot = Bot(token=BOT_TOKEN, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
    dp = Dispatcher()
    dp.include_router(router)

    logger.info("esda bot starting (Mini App: %s)", MINI_APP_URL)
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
