"""
Base settings shared by all environments.

Configuration is loaded from the environment via django-environ. The active
settings module is chosen with the DJANGO_SETTINGS_MODULE env var, e.g.:

    DJANGO_SETTINGS_MODULE=config.settings.local
    DJANGO_SETTINGS_MODULE=config.settings.development
    DJANGO_SETTINGS_MODULE=config.settings.production
"""
from datetime import timedelta
from pathlib import Path

import environ

# api/config/settings/base.py -> api/
BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env(
    DEBUG=(bool, False),
    SECRET_KEY=(str, "insecure-change-me"),
    ALLOWED_HOSTS=(list, ["*"]),
    DATABASE_URL=(str, "postgres://esda:esda@localhost:5432/esda"),
    BOT_TOKEN=(str, ""),
    MINI_APP_URL=(str, "http://localhost:5173"),
    TELEGRAM_AUTH_TTL=(int, 86400),  # seconds initData stays valid
    CORS_ALLOWED_ORIGINS=(list, ["http://localhost:5173"]),
    CORS_ALLOW_ALL_ORIGINS=(bool, False),
    JWT_ACCESS_TOKEN_LIFETIME_MIN=(int, 60),
    JWT_REFRESH_TOKEN_LIFETIME_DAYS=(int, 7),
    DAILY_NEW_LIMIT=(int, 20),
)

# Read a .env file if one sits next to manage.py (handy for host/local runs).
_dotenv = BASE_DIR / ".env"
if _dotenv.exists():
    environ.Env.read_env(str(_dotenv))

SECRET_KEY = env("SECRET_KEY")
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env("ALLOWED_HOSTS")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third party
    "rest_framework",
    "corsheaders",
    # Local apps
    "accounts",
    "catalog",
    "srs",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# Database — parsed from DATABASE_URL (psycopg3).
DATABASES = {"default": env.db("DATABASE_URL")}

# Custom user model MUST be set before the first migration.
AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# --- Django REST Framework ---
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_RENDERER_CLASSES": (
        "config.renderers.EnvelopeJSONRenderer",
        "rest_framework.renderers.BrowsableAPIRenderer",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    # Scoped throttles are applied per public endpoint; see the auth/health views.
    "DEFAULT_THROTTLE_RATES": {
        "register": "5/min",
        "telegram_auth": "10/min",
        "token": "10/min",
        "health": "120/min",
    },
}

# Throttling needs a shared cache to be accurate across gunicorn workers; use
# Redis when REDIS_URL is set (it is, in compose), else in-process for host dev.
_redis_url = env("REDIS_URL", default="")
if _redis_url:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.redis.RedisCache",
            "LOCATION": _redis_url,
        }
    }
else:
    CACHES = {
        "default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache"}
    }

# --- Simple JWT ---
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=env("JWT_ACCESS_TOKEN_LIFETIME_MIN")),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=env("JWT_REFRESH_TOKEN_LIFETIME_DAYS")),
    "AUTH_HEADER_TYPES": ("Bearer",),
}

# --- CORS ---
CORS_ALLOW_ALL_ORIGINS = env("CORS_ALLOW_ALL_ORIGINS")
CORS_ALLOWED_ORIGINS = env("CORS_ALLOWED_ORIGINS")

# --- Telegram / SRS app config ---
BOT_TOKEN = env("BOT_TOKEN")
MINI_APP_URL = env("MINI_APP_URL")
TELEGRAM_AUTH_TTL = env("TELEGRAM_AUTH_TTL")
DAILY_NEW_LIMIT = env("DAILY_NEW_LIMIT")
