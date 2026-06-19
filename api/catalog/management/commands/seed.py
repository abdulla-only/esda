"""Seed languages, CEFR decks (A1/A2) and sample cards. Idempotent."""
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils.text import slugify

from catalog.models import Card, Deck, Language

SEED = {
    "en": {
        "name": "English",
        "decks": {
            "A1": [
                ("hello", "привет", "noun", "Hello, how are you?"),
                ("water", "вода", "noun", "I drink water every morning."),
                ("to eat", "есть / кушать", "verb", "I want to eat an apple."),
                ("big", "большой", "adjective", "That is a big house."),
                ("good", "хороший", "adjective", "Have a good day!"),
            ],
            "A2": [
                ("weather", "погода", "noun", "The weather is nice today."),
                ("to remember", "помнить", "verb", "I can't remember his name."),
                ("expensive", "дорогой", "adjective", "This phone is too expensive."),
                ("already", "уже", "adverb", "She has already left."),
            ],
        },
    },
    "ru": {
        "name": "Russian",
        "decks": {
            "A1": [
                ("дом", "house", "noun", "Это мой дом."),
                ("читать", "to read", "verb", "Я люблю читать книги."),
                ("красивый", "beautiful", "adjective", "Какой красивый закат!"),
                ("спасибо", "thank you", "phrase", "Спасибо за помощь!"),
            ],
            "A2": [
                ("путешествовать", "to travel", "verb", "Мы любим путешествовать летом."),
                ("здоровье", "health", "noun", "Здоровье важнее денег."),
                ("быстро", "quickly", "adverb", "Он бежит очень быстро."),
            ],
        },
    },
}


class Command(BaseCommand):
    help = "Seed languages, CEFR decks and sample cards."

    @transaction.atomic
    def handle(self, *args, **options):
        for code, lang_data in SEED.items():
            language, _ = Language.objects.get_or_create(
                code=code, defaults={"name": lang_data["name"]}
            )
            self.stdout.write(f"Language: {language}")

            for order, (deck_name, cards) in enumerate(lang_data["decks"].items()):
                deck, _ = Deck.objects.get_or_create(
                    language=language,
                    parent=None,
                    slug=slugify(deck_name),
                    defaults={"name": deck_name, "order": order},
                )
                self.stdout.write(f"  Deck: {deck.name}")

                for c_order, (front, back, pos, example) in enumerate(cards):
                    Card.objects.get_or_create(
                        deck=deck,
                        front=front,
                        defaults={
                            "back": back,
                            "part_of_speech": pos,
                            "example": example,
                            "order": c_order,
                        },
                    )

        self.stdout.write(self.style.SUCCESS("Seed complete."))
