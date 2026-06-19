from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers


class TelegramAuthSerializer(serializers.Serializer):
    """Accepts the raw Telegram Web App initData string."""

    init_data = serializers.CharField(trim_whitespace=False)


class RegisterSerializer(serializers.Serializer):
    """Validates a new email/password account."""

    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    first_name = serializers.CharField(required=False, allow_blank=True, default="")

    def validate_email(self, value):
        if get_user_model().objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_password(self, value):
        validate_password(value)
        return value


class TokenPairSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()


class UserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    email = serializers.EmailField()
    telegram_id = serializers.IntegerField(allow_null=True)
    first_name = serializers.CharField()
    last_name = serializers.CharField()
