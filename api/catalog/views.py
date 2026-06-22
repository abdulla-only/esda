from django.db.models import Count, Q
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Card, Deck, Language
from .permissions import IsCardDeckOwnerOrReadOnly, IsDeckOwnerOrReadOnly
from .serializers import (
    CardSerializer,
    DeckSerializer,
    DeckTreeSerializer,
    LanguageSerializer,
)
from .services import build_deck_tree, unique_deck_slug


class LanguageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Language.objects.all()
    serializer_class = LanguageSerializer
    permission_classes = [IsAuthenticated]


class DeckViewSet(viewsets.ModelViewSet):
    """
    Shared catalog decks (owner NULL) are read-only; a user fully manages their
    own decks. `?owner=me` lists only the user's decks; `?language=<code>` filters.
    """

    serializer_class = DeckSerializer
    permission_classes = [IsAuthenticated, IsDeckOwnerOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        qs = (
            Deck.objects.select_related("language", "parent")
            .filter(Q(owner=None) | Q(owner=user))
            .annotate(card_count=Count("cards"))
            .order_by("order", "name")
        )
        if self.request.query_params.get("owner") == "me":
            qs = qs.filter(owner=user)
        language = self.request.query_params.get("language")
        return qs.filter(language__code=language) if language else qs

    def perform_create(self, serializer):
        # Personal decks are flat (parent stays NULL); owner + slug set here.
        name = serializer.validated_data["name"]
        slug = unique_deck_slug(self.request.user, None, name)
        serializer.save(owner=self.request.user, slug=slug)

    @action(detail=False, methods=["get"])
    def tree(self, request):
        roots = build_deck_tree(request.user, request.query_params.get("language"))
        return Response(
            DeckTreeSerializer(roots, many=True, context={"request": request}).data
        )


class CardViewSet(viewsets.ModelViewSet):
    """Cards in shared or own decks are readable; writes only in your own decks."""

    serializer_class = CardSerializer
    permission_classes = [IsAuthenticated, IsCardDeckOwnerOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        qs = (
            Card.objects.select_related("deck")
            .filter(Q(deck__owner=None) | Q(deck__owner=user))
            .order_by("deck", "order", "id")
        )
        deck = self.request.query_params.get("deck")
        return qs.filter(deck_id=deck) if deck else qs
