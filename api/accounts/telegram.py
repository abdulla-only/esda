"""
Validation of Telegram Web App ``initData``.

Reference: https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app

The client sends the raw ``initData`` query string. We:
  1. split it into key/value pairs and pull out ``hash``;
  2. build the data-check-string (all other pairs, sorted by key, ``k=v`` joined
     by newlines);
  3. derive the secret key as HMAC-SHA256("WebAppData") over the bot token;
  4. compare HMAC-SHA256(data_check_string, secret_key) against ``hash``;
  5. reject if ``auth_date`` is older than the configured TTL.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import time
from dataclasses import dataclass
from urllib.parse import parse_qsl


class TelegramAuthError(Exception):
    """Raised when initData is malformed, forged, or expired."""


@dataclass
class TelegramUser:
    id: int
    first_name: str = ""
    last_name: str = ""
    username: str = ""
    language_code: str = ""


def _data_check_string(pairs: dict[str, str]) -> str:
    return "\n".join(f"{k}={pairs[k]}" for k in sorted(pairs))


def validate_init_data(init_data: str, bot_token: str, ttl_seconds: int) -> TelegramUser:
    """Validate raw initData and return the embedded Telegram user.

    Raises TelegramAuthError on any problem (forged hash, missing fields,
    expired auth_date, missing user).
    """
    if not init_data:
        raise TelegramAuthError("Empty initData")
    if not bot_token:
        raise TelegramAuthError("Server is not configured with a BOT_TOKEN")

    # keep_blank_values so an empty field still participates in the check string
    pairs = dict(parse_qsl(init_data, keep_blank_values=True))

    received_hash = pairs.pop("hash", None)
    if not received_hash:
        raise TelegramAuthError("initData is missing the hash field")

    data_check_string = _data_check_string(pairs)

    secret_key = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    expected_hash = hmac.new(
        secret_key, data_check_string.encode(), hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(expected_hash, received_hash):
        raise TelegramAuthError("initData hash mismatch (forged or wrong bot token)")

    # Freshness check.
    auth_date_raw = pairs.get("auth_date")
    if not auth_date_raw:
        raise TelegramAuthError("initData is missing auth_date")
    try:
        auth_date = int(auth_date_raw)
    except ValueError as exc:
        raise TelegramAuthError("initData auth_date is not an integer") from exc

    if ttl_seconds and (time.time() - auth_date) > ttl_seconds:
        raise TelegramAuthError("initData has expired")

    # User payload.
    user_raw = pairs.get("user")
    if not user_raw:
        raise TelegramAuthError("initData has no user payload")
    try:
        user_data = json.loads(user_raw)
    except json.JSONDecodeError as exc:
        raise TelegramAuthError("initData user payload is not valid JSON") from exc

    if "id" not in user_data:
        raise TelegramAuthError("initData user payload has no id")

    return TelegramUser(
        id=int(user_data["id"]),
        first_name=user_data.get("first_name", ""),
        last_name=user_data.get("last_name", ""),
        username=user_data.get("username", ""),
        language_code=user_data.get("language_code", ""),
    )
