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
