from django.db.models import Count
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from rest_framework.response import Response

from .models import Card, Deck, Language
from .serializers import (
    CardSerializer,
    DeckSerializer,
    DeckTreeSerializer,
    LanguageSerializer,
)
from .services import build_deck_tree


class LanguageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Language.objects.all()
    serializer_class = LanguageSerializer
    permission_classes = [IsAuthenticated]


class DeckViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only deck access (content is curated via the Django admin)."""

    serializer_class = DeckSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = (
            Deck.objects.select_related("language", "parent")
            .annotate(card_count=Count("cards"))
            .order_by("order", "name")
        )
        language = self.request.query_params.get("language")
        return qs.filter(language__code=language) if language else qs

    @action(detail=False, methods=["get"])
    def tree(self, request):
        roots = build_deck_tree(request.query_params.get("language"))
        return Response(DeckTreeSerializer(roots, many=True, context={"request": request}).data)


class CardViewSet(viewsets.ModelViewSet):
    """Cards are readable by any user; writes are admin-only (curated content)."""

    serializer_class = CardSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [IsAuthenticated()]
        return [IsAdminUser()]

    def get_queryset(self):
        qs = Card.objects.select_related("deck").order_by("deck", "order", "id")
        deck = self.request.query_params.get("deck")
        return qs.filter(deck_id=deck) if deck else qs
