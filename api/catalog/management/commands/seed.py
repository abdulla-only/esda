"""Seed the reference languages. Decks and cards are per-user (created in-app)."""
from django.core.management.base import BaseCommand
from django.db import transaction

from catalog.models import Language

LANGUAGES = {"en": "English", "ru": "Russian"}


class Command(BaseCommand):
    help = "Seed reference languages (English, Russian)."

    @transaction.atomic
    def handle(self, *args, **options):
        for code, name in LANGUAGES.items():
            language, _ = Language.objects.get_or_create(
                code=code, defaults={"name": name}
            )
            self.stdout.write(f"Language: {language}")
        self.stdout.write(self.style.SUCCESS("Seed complete."))
