from django.conf import settings
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .telegram import TelegramUser, validate_init_data


def issue_token_pair(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


def authenticate_telegram(init_data: str) -> tuple[User, bool]:
    """Validate initData and return the matching user, creating it on first sight.

    Raises TelegramAuthError (handled by the caller) on invalid/expired data.
    """
    tg_user: TelegramUser = validate_init_data(
        init_data,
        bot_token=settings.BOT_TOKEN,
        ttl_seconds=settings.TELEGRAM_AUTH_TTL,
    )
    return User.objects.get_or_create(
        telegram_id=tg_user.id,
        defaults={
            # Telegram accounts may have no email; a stable synthetic one keeps
            # the email-based USERNAME_FIELD usable.
            "email": f"tg_{tg_user.id}@telegram.local",
            "first_name": tg_user.first_name,
            "last_name": tg_user.last_name,
        },
    )
