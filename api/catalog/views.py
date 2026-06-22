from django.db.models import Count
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Card, Deck, Language
from .permissions import IsCardDeckOwnerOrReadOnly, IsDeckOwnerOrReadOnly
from .serializers import CardSerializer, DeckSerializer, LanguageSerializer
from .services import unique_deck_slug


class LanguageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Language.objects.all()
    serializer_class = LanguageSerializer
    permission_classes = [IsAuthenticated]


class DeckViewSet(viewsets.ModelViewSet):
    """A user's own decks (`?language=<code>` filters). No shared catalog."""

    serializer_class = DeckSerializer
    permission_classes = [IsAuthenticated, IsDeckOwnerOrReadOnly]

    def get_queryset(self):
        qs = (
            Deck.objects.select_related("language")
            .filter(owner=self.request.user)
            .annotate(card_count=Count("cards"))
            .order_by("order", "name")
        )
        language = self.request.query_params.get("language")
        return qs.filter(language__code=language) if language else qs

    def perform_create(self, serializer):
        # Personal decks are flat; owner + slug set server-side.
        slug = unique_deck_slug(self.request.user, None, serializer.validated_data["name"])
        serializer.save(owner=self.request.user, slug=slug)


class CardViewSet(viewsets.ModelViewSet):
    """Cards in the user's own decks (`?deck=<id>` filters)."""

    serializer_class = CardSerializer
    permission_classes = [IsAuthenticated, IsCardDeckOwnerOrReadOnly]

    def get_queryset(self):
        qs = (
            Card.objects.select_related("deck")
            .filter(deck__owner=self.request.user)
            .order_by("deck", "order", "id")
        )
        deck = self.request.query_params.get("deck")
        return qs.filter(deck_id=deck) if deck else qs
