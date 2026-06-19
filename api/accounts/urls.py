from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import MeView, TelegramAuthView, ThrottledTokenObtainPairView

urlpatterns = [
    # Telegram Mini App login.
    path("telegram", TelegramAuthView.as_view(), name="auth-telegram"),
    # Plain-web email/password login (USERNAME_FIELD is email -> field name "email").
    path("token", ThrottledTokenObtainPairView.as_view(), name="token-obtain"),
    path("token/refresh", TokenRefreshView.as_view(), name="token-refresh"),
    path("me", MeView.as_view(), name="auth-me"),
]
