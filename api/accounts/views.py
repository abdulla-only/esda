from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import RegisterSerializer, TelegramAuthSerializer, UserSerializer
from .services import authenticate_telegram, issue_token_pair, register_user
from .telegram import TelegramAuthError


class InvalidTelegramData(APIException):
    status_code = 401
    default_detail = "Invalid Telegram init data."
    default_code = "invalid_init_data"


def _user_payload(user):
    return UserSerializer(
        {
            "id": user.id,
            "email": user.email,
            "telegram_id": user.telegram_id,
            "first_name": user.first_name,
            "last_name": user.last_name,
        }
    ).data


class ThrottledTokenObtainPairView(TokenObtainPairView):
    """Email/password login, rate-limited because it is public."""

    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "token"


class RegisterView(APIView):
    """POST /auth/register — create an email/password account and return a JWT pair."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "register"

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = register_user(**serializer.validated_data)
        return Response(
            {"user": _user_payload(user), **issue_token_pair(user)},
            status=status.HTTP_201_CREATED,
        )


class TelegramAuthView(APIView):
    """POST /auth/telegram — validate Telegram initData and return a JWT pair."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "telegram_auth"

    def post(self, request):
        serializer = TelegramAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user, _created = authenticate_telegram(serializer.validated_data["init_data"])
        except TelegramAuthError as exc:
            raise InvalidTelegramData(str(exc)) from exc
        return Response({"user": _user_payload(user), **issue_token_pair(user)})


class MeView(APIView):
    """GET /auth/me — the authenticated user."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(_user_payload(request.user))
