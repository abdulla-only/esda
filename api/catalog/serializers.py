from rest_framework import serializers

from .models import Card, Deck, Language


class LanguageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Language
        fields = ("id", "code", "name")


class CardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Card
        fields = (
            "id",
            "deck",
            "front",
            "back",
            "description",
            "example",
            "part_of_speech",
            "order",
        )

    def validate_deck(self, deck):
        # On write, the target deck must belong to the requesting user.
        request = self.context.get("request")
        if request and deck.owner_id != request.user.id:
            raise serializers.ValidationError(
                "You can only manage cards in your own decks."
            )
        return deck


class DeckSerializer(serializers.ModelSerializer):
    card_count = serializers.IntegerField(read_only=True)  # annotated in the view

    class Meta:
        model = Deck
        fields = (
            "id",
            "language",
            "owner",
            "parent",
            "name",
            "slug",
            "order",
            "card_count",
        )
        # owner/slug/parent are managed server-side; personal decks are flat.
        read_only_fields = ("owner", "slug", "parent", "card_count")


class DeckTreeSerializer(serializers.ModelSerializer):
    """Nests child decks under ``children`` from a pre-built in-memory tree."""

    children = serializers.SerializerMethodField()
    card_count = serializers.IntegerField(read_only=True)  # annotated by build_deck_tree

    class Meta:
        model = Deck
        fields = (
            "id",
            "language",
            "owner",
            "name",
            "slug",
            "order",
            "card_count",
            "children",
        )

    def get_children(self, obj):
        return DeckTreeSerializer(
            obj.children_list, many=True, context=self.context
        ).data
