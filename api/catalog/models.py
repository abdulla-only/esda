from django.conf import settings
from django.db import models


class Language(models.Model):
    code = models.CharField(max_length=8, unique=True)  # e.g. "en", "ru"
    name = models.CharField(max_length=64)

    class Meta:
        ordering = ("code",)

    def __str__(self):
        return f"{self.name} ({self.code})"


class Deck(models.Model):
    """A user-owned deck. Every deck belongs to an ``owner``; ``Card`` ownership
    derives from ``deck.owner``. (``parent`` exists for optional nesting.)"""

    language = models.ForeignKey(
        Language, on_delete=models.CASCADE, related_name="decks"
    )
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="owned_decks",
    )
    parent = models.ForeignKey(
        "self",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="children",
    )
    name = models.CharField(max_length=128)
    slug = models.SlugField(max_length=128)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("order", "name")
        # slug is unique per owner within a parent (shared catalog = owner NULL).
        unique_together = ("owner", "parent", "slug")

    def __str__(self):
        return self.name


class Card(models.Model):
    class PartOfSpeech(models.TextChoices):
        NOUN = "noun", "Noun"
        VERB = "verb", "Verb"
        ADJECTIVE = "adjective", "Adjective"
        ADVERB = "adverb", "Adverb"
        PHRASE = "phrase", "Phrase"
        OTHER = "other", "Other"

    deck = models.ForeignKey(Deck, on_delete=models.CASCADE, related_name="cards")
    front = models.CharField(max_length=255)
    back = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    example = models.TextField(blank=True)
    part_of_speech = models.CharField(
        max_length=16, choices=PartOfSpeech.choices, default=PartOfSpeech.OTHER
    )
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("order", "id")

    def __str__(self):
        return f"{self.front} → {self.back}"
