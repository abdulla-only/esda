from django.db import models


class Language(models.Model):
    code = models.CharField(max_length=8, unique=True)  # e.g. "en", "ru"
    name = models.CharField(max_length=64)

    class Meta:
        ordering = ("code",)

    def __str__(self):
        return f"{self.name} ({self.code})"


class Deck(models.Model):
    """A node in a per-language deck tree (adjacency list via ``parent``)."""

    language = models.ForeignKey(
        Language, on_delete=models.CASCADE, related_name="decks"
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
        # slug is unique within a parent (root decks share parent=NULL).
        unique_together = ("parent", "slug")

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
