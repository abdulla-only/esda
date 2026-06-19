from django.db.models import Count

from .models import Deck


def build_deck_tree(language_code: str | None = None) -> list[Deck]:
    """Return root decks with `.children_list` populated, in a single query.

    Card counts are annotated; the recursion happens in memory, so serializing
    the tree costs one DB query regardless of depth.
    """
    qs = Deck.objects.annotate(card_count=Count("cards")).order_by("order", "name")
    if language_code:
        qs = qs.filter(language__code=language_code)

    decks = list(qs)
    by_parent: dict[int | None, list[Deck]] = {}
    for deck in decks:
        by_parent.setdefault(deck.parent_id, []).append(deck)
    for deck in decks:
        deck.children_list = by_parent.get(deck.id, [])
    return by_parent.get(None, [])
