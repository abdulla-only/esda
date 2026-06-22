from django.db import migrations


def delete_shared_decks(apps, schema_editor):
    """Drop the legacy shared catalog (owner IS NULL); decks are now per-user."""
    Deck = apps.get_model("catalog", "Deck")
    Deck.objects.filter(owner__isnull=True).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("catalog", "0002_alter_deck_unique_together_deck_owner_and_more"),
    ]

    operations = [
        migrations.RunPython(delete_shared_decks, migrations.RunPython.noop),
    ]
