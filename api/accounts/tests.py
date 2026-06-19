import hashlib
import hmac
import json
import time
from urllib.parse import urlencode

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase, override_settings
from rest_framework.test import APITestCase

from .telegram import TelegramAuthError, validate_init_data

User = get_user_model()
BOT_TOKEN = "test:token"


def make_init_data(bot_token=BOT_TOKEN, user_id=555, auth_date=None, tamper=False):
    fields = {
        "auth_date": str(auth_date or int(time.time())),
        "query_id": "AAA",
        "user": json.dumps({"id": user_id, "first_name": "Ada", "username": "ada"}),
    }
    dcs = "\n".join(f"{k}={fields[k]}" for k in sorted(fields))
    secret = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    h = hmac.new(secret, dcs.encode(), hashlib.sha256).hexdigest()
    if tamper:
        h = "0" * 64
    return urlencode({**fields, "hash": h})


class InitDataValidationTests(TestCase):
    def test_valid(self):
        user = validate_init_data(make_init_data(), BOT_TOKEN, 86400)
        self.assertEqual(user.id, 555)

    def test_forged_hash_rejected(self):
        with self.assertRaises(TelegramAuthError):
            validate_init_data(make_init_data(tamper=True), BOT_TOKEN, 86400)

    def test_expired_rejected(self):
        old = make_init_data(auth_date=int(time.time()) - 99999)
        with self.assertRaises(TelegramAuthError):
            validate_init_data(old, BOT_TOKEN, 86400)

    def test_wrong_bot_token_rejected(self):
        with self.assertRaises(TelegramAuthError):
            validate_init_data(make_init_data(), "other:token", 86400)


@override_settings(BOT_TOKEN=BOT_TOKEN, TELEGRAM_AUTH_TTL=86400)
class TelegramAuthEndpointTests(APITestCase):
    url = "/api/v1/auth/telegram"

    def setUp(self):
        cache.clear()

    def test_valid_returns_enveloped_tokens_and_creates_user(self):
        res = self.client.post(self.url, {"init_data": make_init_data(user_id=777)}, format="json")
        self.assertEqual(res.status_code, 200)
        body = res.json()
        self.assertTrue(body["success"])
        self.assertIn("access", body["data"])
        self.assertEqual(body["data"]["user"]["telegram_id"], 777)
        self.assertTrue(User.objects.filter(telegram_id=777).exists())

    def test_forged_is_401_error_envelope(self):
        res = self.client.post(self.url, {"init_data": make_init_data(tamper=True)}, format="json")
        self.assertEqual(res.status_code, 401)
        body = res.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["error"]["code"], "invalid_init_data")


class EmailAuthTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(email="a@b.com", password="secretpass1")

    def test_login_returns_tokens(self):
        res = self.client.post(
            "/api/v1/auth/token", {"email": "a@b.com", "password": "secretpass1"}, format="json"
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.json()["data"])

    def test_bad_password_rejected(self):
        res = self.client.post(
            "/api/v1/auth/token", {"email": "a@b.com", "password": "wrong"}, format="json"
        )
        self.assertEqual(res.status_code, 401)
        self.assertFalse(res.json()["success"])

    def test_me_requires_auth(self):
        self.assertEqual(self.client.get("/api/v1/auth/me").status_code, 401)

    def test_me_returns_user_when_authed(self):
        self.client.force_authenticate(self.user)
        res = self.client.get("/api/v1/auth/me")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["data"]["email"], "a@b.com")
