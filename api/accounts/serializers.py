from rest_framework import serializers


class TelegramAuthSerializer(serializers.Serializer):
    """Accepts the raw Telegram Web App initData string."""

    init_data = serializers.CharField(trim_whitespace=False)


class TokenPairSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()


class UserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    email = serializers.EmailField()
    telegram_id = serializers.IntegerField(allow_null=True)
    first_name = serializers.CharField()
    last_name = serializers.CharField()
