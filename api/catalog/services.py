from django.db.models import Count, Q
from django.utils.text import slugify

from .models import Deck


def unique_deck_slug(owner, parent, name: str) -> str:
    """A slug unique within (owner, parent)."""
    base = slugify(name) or "deck"
    slug = base
    i = 2
    while Deck.objects.filter(owner=owner, parent=parent, slug=slug).exists():
        slug = f"{base}-{i}"
        i += 1
    return slug


def build_deck_tree(user, language_code: str | None = None) -> list[Deck]:
    """Root decks (shared catalog + this user's own) with `.children_list` set.

    Card counts are annotated; the recursion happens in memory, so serializing
    the tree costs one DB query regardless of depth.
    """
    qs = (
        Deck.objects.filter(Q(owner=None) | Q(owner=user))
        .annotate(card_count=Count("cards"))
        .order_by("order", "name")
    )
    if language_code:
        qs = qs.filter(language__code=language_code)

    decks = list(qs)
    by_parent: dict[int | None, list[Deck]] = {}
    for deck in decks:
        by_parent.setdefault(deck.parent_id, []).append(deck)
    for deck in decks:
        deck.children_list = by_parent.get(deck.id, [])
    return by_parent.get(None, [])
